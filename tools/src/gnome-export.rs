#!/usr/bin/env -S nix run nixpkgs#rustc -- --edition 2021
use std::fs::File;
use std::io::{self, Write};
use std::path::PathBuf;
use std::process::{Command, Stdio};

fn git_root() -> io::Result<PathBuf> {
    let output = Command::new("git")
        .args(["rev-parse", "--show-toplevel"])
        .output()?;
    
    if output.status.success() {
        Ok(PathBuf::from(
            String::from_utf8_lossy(&output.stdout).trim()
        ))
    } else {
        Ok(PathBuf::from("/etc/nixos"))
    }
}

fn get_timestamp() -> String {
    let output = Command::new("date")
        .arg("+%Y-%m-%d %H:%M:%S")
        .output()
        .expect("Failed to get timestamp");
    
    String::from_utf8_lossy(&output.stdout).trim().to_string()
}

fn dump_dconf() -> io::Result<String> {
    println!("📥 Dumping current dconf settings...");
    
    // First dump dconf
    let dconf_output = Command::new("dconf")
        .arg("dump")
        .arg("/")
        .output()?;
    
    if !dconf_output.status.success() {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            "Failed to dump dconf settings"
        ));
    }
    
    // Then pipe to dconf2nix
    let dconf2nix = Command::new("nix")
        .args(["run", "nixpkgs#dconf2nix"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()?;
    
    dconf2nix.stdin.unwrap().write_all(&dconf_output.stdout)?;
    
    let output = dconf2nix.wait_with_output()?;
    
    if !output.status.success() {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            "Failed to convert dconf to nix"
        ));
    }
    
    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}

fn run_flake_check(repo_root: &PathBuf) -> io::Result<()> {
    println!("🧪 Running flake check...");
    
    let status = Command::new("nix")
        .args(["flake", "check"])
        .current_dir(repo_root)
        .status()?;
    
    if !status.success() {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            "Flake check failed"
        ));
    }
    
    Ok(())
}

fn has_changes(repo_root: &PathBuf) -> bool {
    Command::new("git")
        .args(["diff", "--cached", "--quiet"])
        .current_dir(repo_root)
        .status()
        .map(|s| !s.success())
        .unwrap_or(false)
}

fn main() -> io::Result<()> {
    let repo_root = git_root()?;
    let settings_dir = repo_root.join("settings/gnome");
    let dconf_file = settings_dir.join("dconf-settings.nix");
    
    std::fs::create_dir_all(&settings_dir)?;
    
    let dconf_content = dump_dconf()?;
    let timestamp = get_timestamp();
    
    println!("💾 Writing to {}...", dconf_file.display());
    
    let mut file = File::create(&dconf_file)?;
    writeln!(file, "# GNOME dconf settings exported at {}", timestamp)?;
    write!(file, "{}", dconf_content)?;
    
    run_flake_check(&repo_root)?;
    
    println!("📝 Committing changes...");
    
    Command::new("git")
        .current_dir(&repo_root)
        .args(["add", dconf_file.to_str().unwrap()])
        .status()?;
    
    if has_changes(&repo_root) {
        Command::new("git")
            .current_dir(&repo_root)
            .args([
                "commit",
                "-m",
                &format!("gnome: update dconf settings ({})", timestamp),
            ])
            .status()?;
        
        println!("✅ Settings exported and committed.");
    } else {
        println!("✅ No changes detected.");
    }
    
    Ok(())
}
