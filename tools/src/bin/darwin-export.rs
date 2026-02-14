use std::fs::{self, File};
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use tools_common;

const DESKTOP_DOMAINS: &[&str] = &[
    "com.apple.dock", "com.apple.finder", "com.apple.screencapture",
    "com.apple.menuextra.clock", "com.apple.systemuiserver",
    "com.apple.AppleMultitouchTrackpad", "NSGlobalDomain",
];

fn run_defaults2nix(out_dir: &Path) -> io::Result<()> {
    println!("📥 Running defaults2nix...");
    let status = Command::new("nix")
        .args(["run", "github:joshryandavis/defaults2nix", "--", "-split", "-filter", "dates,state,uuids", "-out", out_dir.to_str().unwrap()])
        .status()?;
    if !status.success() { return Err(io::Error::new(io::ErrorKind::Other, "defaults2nix failed")); }
    Ok(())
}

fn capture_domain_direct(domain: &str, out_file: &Path) -> bool {
    Command::new("nix")
        .args(["run", "github:joshryandavis/defaults2nix", "--", domain, "-out", out_file.to_str().unwrap()])
        .stdout(Stdio::null()).stderr(Stdio::null()).status()
        .map(|s| s.success()).unwrap_or(false)
}

fn main() -> io::Result<()> {
    println!("🍎 Exporting Desktop Settings...");
    let repo_root = tools_common::git_root();
    let settings_dir = repo_root.join("settings/darwin");
    let domains_dir = settings_dir.join("domains");

    let temp_dir = std::env::temp_dir().join(format!("darwin-export-{}", std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_secs()));
    let exports_dir = temp_dir.join("exports");
    
    fs::create_dir_all(&exports_dir)?;
    fs::create_dir_all(&domains_dir)?;
    run_defaults2nix(&exports_dir)?;

    let mut combined = String::from("{ ... }:\n{\n  system.defaults.CustomUserPreferences = {\n");
    let mut found_count = 0;

    for domain in DESKTOP_DOMAINS {
        let expected_file = exports_dir.join(format!("{}.nix", domain));
        let target_file = domains_dir.join(format!("{}.nix", domain));
        
        if expected_file.exists() {
            fs::copy(&expected_file, &target_file)?;
            combined.push_str(&format!("    \"{}\" = import ./domains/{}.nix;\n", domain, domain));
            found_count += 1;
            println!("    ✅ Captured: {}", domain);
        } else {
            println!("    🔍 {} not in split, trying direct...", domain);
            if capture_domain_direct(domain, &target_file) {
                combined.push_str(&format!("    \"{}\" = import ./domains/{}.nix;\n", domain, domain));
                found_count += 1;
                println!("    ✅ Captured (Direct): {}", domain);
            }
        }
    }

    combined.push_str("  };\n}\n");
    File::create(settings_dir.join("default.nix"))?.write_all(combined.as_bytes())?;

    if Command::new("git").args(["rev-parse", "--git-dir"]).stdout(Stdio::null()).status().map(|s| s.success()).unwrap_or(false) {
        Command::new("git").current_dir(&repo_root).args(["add", settings_dir.to_str().unwrap()]).status()?;
        let _ = Command::new("git").current_dir(&repo_root).args(["commit", "-m", &format!("darwin: update defaults ({})", tools_common::get_timestamp())]).status();
    }

    let _ = fs::remove_dir_all(&temp_dir);
    println!("Done! 🎉 Exported {} domains.", found_count);
    Ok(())
}
