use std::env;
use std::fs::{self, File};
use std::io::{self, BufRead, BufReader, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use tools_common;

fn generate_age_key(path: &Path) -> io::Result<()> {
    println!("⚠️ Generating Age key...");
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
    tools_common::fail("Could not find public key");
}

fn derive_host_key() -> String {
    let host_key_path = "/etc/ssh/ssh_host_ed25519_key.pub";
    if !Path::new(host_key_path).exists() { return "".to_string(); }
    let mut child = Command::new("nix").args(["run", "nixpkgs#ssh-to-age"]).stdin(Stdio::piped()).stdout(Stdio::piped()).spawn().expect("ssh-to-age fail");
    let key_data = fs::read_to_string(host_key_path).unwrap_or_default();
    let mut stdin = child.stdin.take().unwrap();
    stdin.write_all(key_data.as_bytes()).ok();
    drop(stdin);
    String::from_utf8_lossy(&child.wait_with_output().unwrap().stdout).trim().to_string()
}

fn main() -> io::Result<()> {
    let root = tools_common::git_root();
    let age_key = PathBuf::from(env::var("HOME").unwrap()).join(".config/age/keys.txt");
    if !age_key.exists() { generate_age_key(&age_key)?; }
    
    let user_key = extract_public_key(&age_key);
    let host_key = derive_host_key();
    let host = tools_common::hostname();
    
    println!("✅ Setup for {} (User Key: {})", host, user_key);
    if !host_key.is_empty() { println!("✅ Host Key: {}", host_key); }
    
    Ok(())
}
