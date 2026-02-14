/// generate-app-config — create nix config snippets from /Applications
///
/// Generates ready-to-paste configuration sections for:
/// - nixpkgs packages
/// - Homebrew casks
/// - Mac App Store apps
use tools_common::*;

struct CategorizedApp {
    name: String,
    source: AppSource,
}

#[derive(Debug)]
enum AppSource {
    Nixpkgs(String),
    Homebrew(String),
    MasOnly(u64),
}

fn list_applications() -> Vec<String> {
    let output = Command::new("sh")
        .args(["-c", r#"ls -1 /Applications 2>/dev/null | grep '\.app$' | sed 's/\.app$//'"#])
        .output()
        .expect("failed to list /Applications");

    String::from_utf8_lossy(&output.stdout)
        .lines()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect()
}

fn normalize_name(name: &str) -> String {
    name.to_lowercase()
        .chars()
        .map(|c| if c.is_alphanumeric() { c } else { '-' })
        .collect::<String>()
        .split('-')
        .filter(|s| !s.is_empty())
        .collect::<Vec<_>>()
        .join("-")
}

fn check_nixpkgs(app_name: &str) -> Option<String> {
    let search_name = normalize_name(app_name);
    
    let output = Command::new("nix")
        .args(["search", "nixpkgs", &search_name, "--json"])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .output()
        .ok()?;

    if !output.status.success() {
        return None;
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    
    if stdout.trim() == "{}" || stdout.trim().is_empty() {
        return None;
    }

    if stdout.to_lowercase().contains(&search_name) {
        Some(search_name)
    } else {
        None
    }
}

fn check_homebrew_cask(app_name: &str) -> Option<String> {
    let search_name = normalize_name(app_name);
    
    let output = Command::new("brew")
        .args(["info", "--cask", &search_name])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .ok()?;

    if output.success() {
        return Some(search_name);
    }

    let alt_name = search_name.replace("-", "");
    if alt_name != search_name {
        let output = Command::new("brew")
            .args(["info", "--cask", &alt_name])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .ok()?;

        if output.success() {
            return Some(alt_name);
        }
    }

    None
}

fn check_mas(app_name: &str) -> Option<u64> {
    let output = Command::new("mas")
        .args(["search", app_name])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .output()
        .ok()?;

    if !output.status.success() {
        return None;
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    let first_line = stdout.lines().next()?;
    
    let parts: Vec<&str> = first_line.split_whitespace().collect();
    if parts.is_empty() {
        return None;
    }

    parts[0].parse().ok()
}

fn categorize_app(app_name: &str) -> Option<CategorizedApp> {
    eprint!("\rProcessing: {:<40}", app_name);
    
    if let Some(pkg_name) = check_nixpkgs(app_name) {
        return Some(CategorizedApp {
            name: app_name.to_string(),
            source: AppSource::Nixpkgs(pkg_name),
        });
    }

    if let Some(cask_name) = check_homebrew_cask(app_name) {
        return Some(CategorizedApp {
            name: app_name.to_string(),
            source: AppSource::Homebrew(cask_name),
        });
    }

    if let Some(id) = check_mas(app_name) {
        return Some(CategorizedApp {
            name: app_name.to_string(),
            source: AppSource::MasOnly(id),
        });
    }

    None
}

fn main() -> io::Result<()> {
    let timestamp = get_timestamp();
    
    eprintln!("Analyzing applications...");
    eprintln!();

    let app_names = list_applications();
    let total = app_names.len();
    
    if total == 0 {
        eprintln!("No applications found in /Applications");
        std::process::exit(1);
    }

    eprintln!("Found {} applications\n", total);

    let mut nixpkgs = Vec::new();
    let mut homebrew = Vec::new();
    let mut mas_apps = Vec::new();

    for app_name in app_names.iter() {
        if let Some(app) = categorize_app(app_name) {
            match app.source {
                AppSource::Nixpkgs(pkg) => nixpkgs.push(pkg),
                AppSource::Homebrew(cask) => homebrew.push(cask),
                AppSource::MasOnly(id) => mas_apps.push((app.name, id)),
            }
        }
    }

    eprint!("\r{:<70}\r", ""); // Clear progress line

    // Output configuration
    println!("# Generated configuration from /Applications - {}", timestamp);
    println!("# Copy the relevant sections to your config files");
    println!();

    // Nixpkgs
    if !nixpkgs.is_empty() {
        println!("# ==============================================================");
        println!("# Add to settings/config/packages.nix -> system or development");
        println!("# ==============================================================");
        println!("[");
        for pkg in nixpkgs {
            println!("  \"{}\"", pkg);
        }
        println!("]");
        println!();
    }

    // Homebrew
    if !homebrew.is_empty() {
        println!("# ==============================================================");
        println!("# Add to settings/config/darwin.nix -> homebrew.casks");
        println!("# ==============================================================");
        println!("casks = [");
        for cask in homebrew {
            println!("  \"{}\"", cask);
        }
        println!("];");
        println!();
    }

    // MAS
    if !mas_apps.is_empty() {
        println!("# ==============================================================");
        println!("# Add to settings/config/darwin.nix -> homebrew.masApps");
        println!("# ==============================================================");
        println!("masApps = {{");
        for (name, id) in mas_apps {
            println!("  \"{}\" = {};", name, id);
        }
        println!("}};");
        println!();
    }

    println!("# ==============================================================");
    println!("# Summary");
    println!("# ==============================================================");
    eprintln!("✨ Done! Copy the sections above to your config files.");

    Ok(())
}
