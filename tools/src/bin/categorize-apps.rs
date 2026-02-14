/// categorize-apps — scan /Applications and categorize by best package source
///
/// Priority: nixpkgs → Homebrew casks → Mac App Store → manual install
/// Helps you build a fully declarative nix-darwin configuration.
use tools_common::*;

#[derive(Debug)]
enum AppSource {
    Nixpkgs(String),      // package name in nixpkgs
    Homebrew(String),     // cask name
    MasOnly(u64),         // mas ID (app name is in App.name)
    Manual,               // not available in any package manager
}

struct App {
    name: String,
    source: AppSource,
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
    
    // Check if we got any results
    if stdout.trim() == "{}" || stdout.trim().is_empty() {
        return None;
    }

    // Simple heuristic: if the search term appears in the results, it's probably available
    if stdout.to_lowercase().contains(&search_name) {
        Some(search_name)
    } else {
        None
    }
}

fn check_homebrew_cask(app_name: &str) -> Option<String> {
    let search_name = normalize_name(app_name);
    
    // Try exact match first
    let output = Command::new("brew")
        .args(["info", "--cask", &search_name])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .ok()?;

    if output.success() {
        return Some(search_name);
    }

    // Try without hyphens
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
    
    // Parse: "1234567890  App Name  (version)"
    let parts: Vec<&str> = first_line.split_whitespace().collect();
    if parts.is_empty() {
        return None;
    }

    parts[0].parse().ok()
}

fn categorize_app(app_name: &str) -> App {
    print!("\r  Checking: {:<40}", app_name);
    let _ = io::stdout().flush();

    // Priority 1: nixpkgs
    if let Some(pkg_name) = check_nixpkgs(app_name) {
        return App {
            name: app_name.to_string(),
            source: AppSource::Nixpkgs(pkg_name),
        };
    }

    // Priority 2: Homebrew casks
    if let Some(cask_name) = check_homebrew_cask(app_name) {
        return App {
            name: app_name.to_string(),
            source: AppSource::Homebrew(cask_name),
        };
    }

    // Priority 3: Mac App Store
    if let Some(id) = check_mas(app_name) {
        return App {
            name: app_name.to_string(),
            source: AppSource::MasOnly(id),
        };
    }

    // Not available in any package manager
    App {
        name: app_name.to_string(),
        source: AppSource::Manual,
    }
}

fn print_results(apps: &[App]) {
    let mut nixpkgs = Vec::new();
    let mut homebrew = Vec::new();
    let mut mas_only = Vec::new();
    let mut manual = Vec::new();

    for app in apps {
        match &app.source {
            AppSource::Nixpkgs(pkg) => nixpkgs.push((app.name.as_str(), pkg.as_str())),
            AppSource::Homebrew(cask) => homebrew.push((app.name.as_str(), cask.as_str())),
            AppSource::MasOnly(id) => mas_only.push((app.name.as_str(), *id)),
            AppSource::Manual => manual.push(app.name.as_str()),
        }
    }

    println!("\n");
    println!("==============================================================");
    println!();

    // Nixpkgs
    println!("✅ NIXPKGS (add to settings/config/packages.nix):");
    if nixpkgs.is_empty() {
        println!("  (none found)");
    } else {
        for (app, pkg) in &nixpkgs {
            println!("  \"{}\"  # {}", pkg, app);
        }
    }
    println!();

    // Homebrew
    println!("🍺 HOMEBREW CASKS (add to settings/config/darwin.nix -> casks):");
    if homebrew.is_empty() {
        println!("  (none found)");
    } else {
        for (app, cask) in &homebrew {
            if app.to_lowercase() != *cask {
                println!("  \"{}\"  # {}", cask, app);
            } else {
                println!("  \"{}\"", cask);
            }
        }
    }
    println!();

    // Mac App Store
    println!("🍎 MAC APP STORE ONLY (add to settings/config/darwin.nix -> masApps):");
    if mas_only.is_empty() {
        println!("  (none found)");
    } else {
        for (app, id) in &mas_only {
            println!("  \"{}\" = {};", app, id);
        }
    }
    println!();

    // Manual
    println!("❌ NOT MANAGED / MANUAL INSTALL:");
    if manual.is_empty() {
        println!("  (none found)");
    } else {
        for app in &manual {
            println!("  \"{}\"", app);
        }
        println!();
        println!("  These apps typically include:");
        println!("  - Game launchers (Steam, Epic, EA, Roblox)");
        println!("  - Beta/custom builds");
        println!("  - Apps not in any package manager");
        println!("  - System apps (Safari)");
    }
    println!();

    println!("==============================================================");
    println!("Summary:");
    println!("  Nixpkgs:   {} apps", nixpkgs.len());
    println!("  Homebrew:  {} apps", homebrew.len());
    println!("  MAS:       {} apps", mas_only.len());
    println!("  Manual:    {} apps", manual.len());
    println!("  Total:     {} apps", apps.len());
    println!();
    println!("💡 Tip: Use generate-app-config to create config snippets");
}

fn main() -> io::Result<()> {
    println!("Scanning /Applications and categorizing apps...");
    println!("==============================================================");
    println!();

    let app_names = list_applications();
    let total = app_names.len();
    
    if total == 0 {
        eprintln!("No applications found in /Applications");
        std::process::exit(1);
    }

    println!("Found {} applications\n", total);

    let mut apps = Vec::new();
    for (i, app_name) in app_names.iter().enumerate() {
        print!("\rProcessing: {}/{} - {:<40}", i + 1, total, app_name);
        let _ = io::stdout().flush();
        
        apps.push(categorize_app(app_name));
    }

    print!("\r{:<70}\r", ""); // Clear the progress line
    let _ = io::stdout().flush();

    print_results(&apps);

    Ok(())
}
