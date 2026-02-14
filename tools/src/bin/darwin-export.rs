use std::fs::{self, File};
use std::io::{self, Write};
use std::path::{Path};
use std::process::{Command, Stdio};
use tools_common;

const DESKTOP_DOMAINS: &[&str] = &[
    "com.apple.dock", "com.apple.finder", "com.apple.screencapture",
    "com.apple.menuextra.clock", "com.apple.systemuiserver",
    "com.apple.AppleMultitouchTrackpad", "NSGlobalDomain",
];

fn capture_domain_direct(domain: &str, out_file: &Path) -> bool {
    let status = Command::new("nix")
        .args([
            "run", "github:joshryandavis/defaults2nix", "--", 
            domain, 
            "-filter", "dates,state,uuids",
            "-out", out_file.to_str().unwrap()
        ])
        .status()
        .map(|s| s.success())
        .unwrap_or(false);
    
    status && out_file.exists() && fs::metadata(out_file).map(|m| m.len() > 0).unwrap_or(false)
}

fn main() -> io::Result<()> {
    println!("🍎 Exporting Desktop Settings...");
    let repo_root = tools_common::git_root();
    let settings_dir = repo_root.join("settings/darwin");
    let domains_dir = settings_dir.join("domains");

    fs::create_dir_all(&domains_dir)?;

    let mut combined = String::from("{ ... }:\n{\n  system.defaults.CustomUserPreferences = {\n");
    let mut found_count = 0;

    for domain in DESKTOP_DOMAINS {
        let target_file = domains_dir.join(format!("{}.nix", domain));
        if capture_domain_direct(domain, &target_file) {
            combined.push_str(&format!("    \"{}\" = import ./domains/{}.nix;\n", domain, domain));
            found_count += 1;
            println!("    ✅ Success: {}", domain);
        }
    }

    combined.push_str("  };\n}\n");
    File::create(settings_dir.join("default.nix"))?.write_all(combined.as_bytes())?;

    Command::new("git").current_dir(&repo_root).args(["add", "settings/darwin"]).status()?;
    let timestamp = tools_common::get_timestamp();
    let commit = Command::new("git").current_dir(&repo_root).args(["commit", "-m", &format!("darwin: update defaults ({})", timestamp)]).status()?;

    if commit.success() { println!("🚀 Darwin settings committed."); }
    else { println!("ℹ️  No changes in Darwin settings."); }
    Ok(())
}
