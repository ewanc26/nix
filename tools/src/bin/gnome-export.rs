use std::fs::File;
use std::io::{self, Write};
use std::process::{Command, Stdio};
use tools_common;

fn dump_dconf() -> io::Result<String> {
    println!("📥 Dumping dconf settings...");
    let dconf_output = Command::new("dconf").args(["dump", "/"]).output()?;
    let mut dconf2nix = Command::new("nix")
        .args(["run", "nixpkgs#dconf2nix"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()?;
    
    let mut stdin = dconf2nix.stdin.take().expect("Failed to open stdin");
    stdin.write_all(&dconf_output.stdout)?;
    drop(stdin); // Close stdin so dconf2nix knows to finish

    let output = dconf2nix.wait_with_output()?;
    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}

fn main() -> io::Result<()> {
    let repo_root = tools_common::git_root();
    let settings_dir = repo_root.join("settings/gnome");
    let dconf_file = settings_dir.join("dconf-settings.nix");
    
    std::fs::create_dir_all(&settings_dir)?;
    let content = dump_dconf()?;
    let timestamp = tools_common::get_timestamp();

    let mut file = File::create(&dconf_file)?;
    writeln!(file, "# GNOME settings exported at {}", timestamp)?;
    write!(file, "{}", content)?;

    println!("📝 Staging changes...");
    Command::new("git").current_dir(&repo_root).args(["add", dconf_file.to_str().unwrap()]).status()?;
    
    let has_changes = !Command::new("git")
        .current_dir(&repo_root)
        .args(["diff", "--cached", "--quiet"])
        .status()?
        .success();

    if has_changes {
        Command::new("git")
            .current_dir(&repo_root)
            .args(["commit", "-m", &format!("gnome: update dconf ({})", timestamp)])
            .status()?;
        println!("🚀 GNOME settings committed.");
    } else {
        println!("ℹ️  No changes detected in GNOME settings.");
    }
    Ok(())
}
