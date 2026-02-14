use tools_common::{self, *};

fn main() -> io::Result<()> {
    println!("🎨 Exporting GNOME Settings...");
    let repo_root = git_root();
    let out_file = repo_root.join("settings/gnome/dconf-settings.nix");
    fs::create_dir_all(out_file.parent().unwrap())?;

    let dconf_raw = Command::new("dconf").args(["dump", "/"]).output()?;
    let mut child = Command::new("nix")
        .args(["run", "nixpkgs#dconf2nix"])
        .stdin(Stdio::piped()).stdout(Stdio::piped()).spawn()?;

    if let Some(mut stdin) = child.stdin.take() {
        let _ = stdin.write_all(&dconf_raw.stdout);
    }

    let output = child.wait_with_output()?;
    if output.status.success() {
        let mut file = File::create(&out_file)?;
        writeln!(file, "# Generated at {}", get_timestamp())?;
        file.write_all(&output.stdout)?;
        git_sync("settings/gnome", "gnome");
    }
    Ok(())
}
