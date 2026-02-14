#!/usr/bin/env -S nix run nixpkgs#rustc -- --edition 2021
use std::env;
use std::fs::{self, File};
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

const DESKTOP_DOMAINS: &[&str] = &[
    "com.apple.dock",
    "com.apple.finder",
    "com.apple.screencapture",
    "com.apple.menuextra.clock",
    "com.apple.systemuiserver",
    "com.apple.AppleMultitouchTrackpad",
    "NSGlobalDomain",
];

fn git_root() -> io::Result<PathBuf> {
    let output = Command::new("git")
        .args(["rev-parse", "--show-toplevel"])
        .output()?;
    
    if output.status.success() {
        Ok(PathBuf::from(
            String::from_utf8_lossy(&output.stdout).trim()
        ))
    } else {
        env::current_dir()
    }
}

fn run_defaults2nix(out_dir: &Path) -> io::Result<()> {
    println!("📥 Running defaults2nix...");
    
    let status = Command::new("nix")
        .args([
            "run", 
            "github:joshryandavis/defaults2nix", 
            "--",
            "-split",
            "-filter", "dates,state,uuids",
            "-out", out_dir.to_str().unwrap(),
        ])
        .status()?;
    
    if !status.success() {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            "defaults2nix failed"
        ));
    }
    
    Ok(())
}

fn capture_domain_direct(domain: &str, out_file: &Path) -> bool {
    Command::new("nix")
        .args([
            "run",
            "github:joshryandavis/defaults2nix",
            "--",
            domain,
            "-out", out_file.to_str().unwrap(),
        ])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

fn get_timestamp() -> String {
    let output = Command::new("date")
        .arg("+%Y-%m-%d %H:%M:%S")
        .output()
        .expect("Failed to get timestamp");
    
    String::from_utf8_lossy(&output.stdout).trim().to_string()
}

fn main() -> io::Result<()> {
    println!("🍎 Exporting Desktop Settings with defaults2nix...");
    
    let repo_root = git_root()?;
    let settings_dir = repo_root.join("settings/darwin");
    let domains_dir = settings_dir.join("domains");
    
    // Create temp dir
    let temp_dir = env::temp_dir().join(format!("darwin-export-{}", 
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
    ));
    let exports_dir = temp_dir.join("exports");
    
    fs::create_dir_all(&exports_dir)?;
    fs::create_dir_all(&domains_dir)?;
    
    // Run defaults2nix
    run_defaults2nix(&exports_dir)?;
    
    // Start building combined file
    let mut combined = String::new();
    combined.push_str("{ ... }:\n{\n  system.defaults.CustomUserPreferences = {\n");
    
    let mut found_count = 0;
    
    // Process each domain
    for domain in DESKTOP_DOMAINS {
        let expected_file = exports_dir.join(format!("{}.nix", domain));
        let target_file = domains_dir.join(format!("{}.nix", domain));
        
        if expected_file.exists() {
            fs::copy(&expected_file, &target_file)?;
            combined.push_str(&format!("    \"{}\" = import ./domains/{}.nix;\n", 
                domain, domain));
            found_count += 1;
            println!("    ✅ Captured: {}", domain);
        } else {
            println!("    🔍 {} not in split export, trying direct capture...", domain);
            if capture_domain_direct(domain, &target_file) {
                combined.push_str(&format!("    \"{}\" = import ./domains/{}.nix;\n", 
                    domain, domain));
                found_count += 1;
                println!("    ✅ Captured (Direct): {}", domain);
            } else {
                println!("    ❌ Skipped: {} (No data found)", domain);
            }
        }
    }
    
    combined.push_str("  };\n}\n");
    
    // Write combined file
    let defaults_file = settings_dir.join("default.nix");
    let mut file = File::create(&defaults_file)?;
    file.write_all(combined.as_bytes())?;
    
    // Git commit
    if Command::new("git")
        .args(["rev-parse", "--git-dir"])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
    {
        let timestamp = get_timestamp();
        
        Command::new("git")
            .current_dir(&repo_root)
            .args(["add", settings_dir.to_str().unwrap()])
            .status()?;
        
        let _ = Command::new("git")
            .current_dir(&repo_root)
            .args([
                "commit",
                "-m",
                &format!("darwin: update defaults via defaults2nix ({})", timestamp),
            ])
            .status();
    }
    
    // Cleanup
    let _ = fs::remove_dir_all(&temp_dir);
    
    println!("Done! 🎉 Successfully exported {} domains.", found_count);
    
    Ok(())
}
