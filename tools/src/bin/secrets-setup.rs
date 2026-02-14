use std::env;
use std::fs::{self, File};
use std::io::{self, BufRead, BufReader, Read, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use tools_common;

fn generate_age_key(path: &Path) -> io::Result<()> {
    println!("⚠️ Generating Age key at {}...", path.display());
    fs::create_dir_all(path.parent().unwrap())?;
    Command::new("nix").args(["run", "nixpkgs#age-keygen", "--", "-o", path.to_str().unwrap()]).status()?;
    Ok(())
}

fn extract_public_key(path: &Path) -> String {
    let file = File::open(path).expect("No key file");
    for line in BufReader::new(file).lines().map(|l| l.unwrap()) {
        if line.starts_with("# public key:") {
            return line.split_whitespace().nth(3).unwrap().to_string();
        }
    }
    tools_common::fail("Could not find public key in file");
}

fn derive_host_key() -> Option<String> {
    let host_key_path = Path::new("/etc/ssh/ssh_host_ed25519_key.pub");
    if !host_key_path.exists() { return None; }
    let mut child = Command::new("nix").args(["run", "nixpkgs#ssh-to-age"]).stdin(Stdio::piped()).stdout(Stdio::piped()).spawn().ok()?;
    child.stdin.as_mut()?.write_all(fs::read_to_string(host_key_path).ok()?.as_bytes()).ok();
    Some(String::from_utf8_lossy(&child.wait_with_output().ok()?.stdout).trim().to_string())
}

fn main() -> io::Result<()> {
    println!("=== Ragenix Bootstrap ===");
    let root = tools_common::git_root();
    let secrets_dir = root.join("secrets");
    let age_key = PathBuf::from(env::var("HOME").unwrap()).join(".config/age/keys.txt");

    if !age_key.exists() { generate_age_key(&age_key)?; }
    let user_key = extract_public_key(&age_key);
    let host_key = derive_host_key();
    let hostname = tools_common::hostname();

    fs::create_dir_all(&secrets_dir)?;
    let secrets_file = secrets_dir.join("secrets.nix");

    let content = format!(
        "let\n  users = {{ \"{}\" = \"{}\"; }};\n  systems = {{ \"{}\" = \"{}\"; }};\n  all = (builtins.attrValues users) ++ (builtins.attrValues systems);\nin {{ }}\n",
        env::var("USER").unwrap(), user_key, hostname, host_key.unwrap_or_default()
    );
    
    if !secrets_file.exists() {
        File::create(&secrets_file)?.write_all(content.as_bytes())?;
        println!("✅ Created secrets.nix");
    }

    println!("✅ User Key: {}\nDone.", user_key);
    Ok(())
}
