/// sync-apps — automatically update nix config files with current applications
///
/// Scans /Applications, categorizes apps, and updates:
/// - settings/config/darwin.nix (casks and masApps)
/// - settings/config/packages.nix (nixpkgs packages)
///
/// Creates a git commit with the changes.
use tools_common::*;

#[derive(Debug)]
enum AppSource {
    Nixpkgs(String),
    Homebrew(String),
    MasOnly(u64),
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

fn categorize_apps() -> Vec<App> {
    let app_names = list_applications();
    let total = app_names.len();
    
    println!("🔍 Scanning {} applications...", total);
    
    let mut apps = Vec::new();
    for (i, app_name) in app_names.iter().enumerate() {
        print!("\r  Progress: {}/{} - {:<40}", i + 1, total, app_name);
        let _ = io::stdout().flush();
        
        // Priority: nixpkgs → Homebrew → MAS
        if let Some(pkg_name) = check_nixpkgs(app_name) {
            apps.push(App {
                name: app_name.to_string(),
                source: AppSource::Nixpkgs(pkg_name),
            });
        } else if let Some(cask_name) = check_homebrew_cask(app_name) {
            apps.push(App {
                name: app_name.to_string(),
                source: AppSource::Homebrew(cask_name),
            });
        } else if let Some(id) = check_mas(app_name) {
            apps.push(App {
                name: app_name.to_string(),
                source: AppSource::MasOnly(id),
            });
        }
    }
    
    print!("\r{:<70}\r", "");
    let _ = io::stdout().flush();
    
    apps
}

fn replace_section(content: &str, start_marker: &str, end_marker: &str, new_content: &str) -> String {
    // Find the start of the section
    if let Some(start_pos) = content.find(start_marker) {
        // Find the end marker after the start
        if let Some(end_offset) = content[start_pos..].find(end_marker) {
            let end_pos = start_pos + end_offset + end_marker.len();
            
            // Reconstruct: before + new section + after
            let mut result = String::new();
            result.push_str(&content[..start_pos]);
            result.push_str(new_content);
            result.push_str(&content[end_pos..]);
            return result;
        }
    }
    
    // If section not found, return original
    content.to_string()
}

fn update_darwin_config(repo_root: &Path, apps: &[App]) -> io::Result<()> {
    let darwin_config = repo_root.join("settings/config/darwin.nix");
    
    if !darwin_config.exists() {
        eprintln!("⚠️  settings/config/darwin.nix not found");
        return Ok(());
    }
    
    let content = fs::read_to_string(&darwin_config)?;
    
    // Extract casks and MAS apps
    let mut casks = Vec::new();
    let mut mas_apps = Vec::new();
    
    for app in apps {
        match &app.source {
            AppSource::Homebrew(cask) => casks.push(cask.clone()),
            AppSource::MasOnly(id) => mas_apps.push((app.name.clone(), *id)),
            _ => {}
        }
    }
    
    casks.sort();
    casks.dedup();
    mas_apps.sort_by(|a, b| a.0.cmp(&b.0));
    
    // Build new casks section
    let casks_content = if casks.is_empty() {
        "    casks = [\n    ];".to_string()
    } else {
        let casks_str = casks.iter()
            .map(|c| format!("      \"{}\"", c))
            .collect::<Vec<_>>()
            .join("\n");
        format!("    casks = [\n{}\n    ];", casks_str)
    };
    
    // Build new masApps section
    let mas_content = if mas_apps.is_empty() {
        "    masApps = {\n    };".to_string()
    } else {
        let mas_str = mas_apps.iter()
            .map(|(name, id)| format!("      \"{}\" = {};", name, id))
            .collect::<Vec<_>>()
            .join("\n");
        format!("    masApps = {{\n{}\n    }};", mas_str)
    };
    
    // Replace sections
    let mut new_content = content.clone();
    
    // Replace casks section
    new_content = replace_section(&new_content, "casks = [", "];", &casks_content);
    
    // Replace masApps section
    new_content = replace_section(&new_content, "masApps = {", "};", &mas_content);
    
    // Only write if changed
    if new_content != content {
        fs::write(&darwin_config, new_content)?;
        
        println!("✅ Updated settings/config/darwin.nix");
        println!("   - {} casks", casks.len());
        println!("   - {} Mac App Store apps", mas_apps.len());
    } else {
        println!("ℹ️  settings/config/darwin.nix unchanged");
    }
    
    Ok(())
}

fn update_packages_config(_repo_root: &Path, apps: &[App]) -> io::Result<()> {
    let mut nixpkgs = Vec::new();
    
    for app in apps {
        if let AppSource::Nixpkgs(pkg) = &app.source {
            nixpkgs.push(pkg.clone());
        }
    }
    
    if nixpkgs.is_empty() {
        return Ok(());
    }
    
    nixpkgs.sort();
    nixpkgs.dedup();
    
    println!("ℹ️  Found {} apps in nixpkgs:", nixpkgs.len());
    println!("   Add these manually to settings/config/packages.nix:");
    for pkg in &nixpkgs {
        println!("     \"{}\"", pkg);
    }
    
    Ok(())
}

fn main() -> io::Result<()> {
    let repo_root = git_root();
    
    println!("🚀 Syncing applications to nix config");
    println!("   Repo: {}\n", repo_root.display());
    
    // Check for uncommitted changes
    let has_changes = Command::new("git")
        .current_dir(&repo_root)
        .args(["diff", "--quiet"])
        .status()
        .map(|s| !s.success())
        .unwrap_or(false);
    
    if has_changes {
        println!("⚠️  You have uncommitted changes.");
        
        if !env::args().any(|a| a == "--force") {
            println!("   Commit them first or run with --force to proceed anyway.\n");
            std::process::exit(1);
        } else {
            println!("   Proceeding with --force...\n");
        }
    }
    
    // Categorize apps
    let apps = categorize_apps();
    
    let nixpkgs_count = apps.iter().filter(|a| matches!(a.source, AppSource::Nixpkgs(_))).count();
    let homebrew_count = apps.iter().filter(|a| matches!(a.source, AppSource::Homebrew(_))).count();
    let mas_count = apps.iter().filter(|a| matches!(a.source, AppSource::MasOnly(_))).count();
    
    println!("\n📊 Found:");
    println!("   - {} apps in nixpkgs", nixpkgs_count);
    println!("   - {} apps in Homebrew", homebrew_count);
    println!("   - {} apps in Mac App Store", mas_count);
    println!();
    
    // Update config files
    update_darwin_config(&repo_root, &apps)?;
    update_packages_config(&repo_root, &apps)?;
    
    // Check if anything changed
    let has_changes_after = Command::new("git")
        .current_dir(&repo_root)
        .args(["diff", "--quiet", "settings/config/darwin.nix"])
        .status()
        .map(|s| !s.success())
        .unwrap_or(false);
    
    if has_changes_after {
        println!();
        git_sync("settings/config/darwin.nix", "sync-apps");
        
        println!();
        println!("✨ Done! Your config is now in sync with /Applications");
        println!("   Run: darwin-rebuild switch --flake ~/.config/nix-config#macmini");
    } else {
        println!();
        println!("✨ Already in sync! No changes needed.");
    }
    
    Ok(())
}
