#!/usr/bin/env -S nix run nixpkgs#rustc -- --edition 2021
use std::env;
use std::fs::{self, File, OpenOptions};
use std::io::{self, BufRead, BufReader, Read, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

fn fail(msg: &str) -> ! {
    eprintln!("❌ {}", msg);
    std::process::exit(1);
}

fn git_root() -> PathBuf {
    let output = Command::new("git")
        .args(["rev-parse", "--show-toplevel"])
        .output()
        .ok();
    
    if let Some(output) = output {
        if output.status.success() {
            return PathBuf::from(String::from_utf8_lossy(&output.stdout).trim());
        }
    }
    
    env::current_dir()
        .ok()
        .and_then(|p| p.parent().map(|p| p.to_path_buf()))
        .unwrap_or_else(|| PathBuf::from("."))
}

fn hostname() -> String {
    let output = Command::new("hostname")
        .arg("-s")
        .output()
        .expect("Failed to get hostname");
    
    String::from_utf8_lossy(&output.stdout).trim().to_string()
}

fn generate_age_key(key_path: &Path) -> io::Result<()> {
    println!("⚠️ No key found at {}. Generating...", key_path.display());
    
    if let Some(parent) = key_path.parent() {
        fs::create_dir_all(parent)?;
    }
    
    let status = Command::new("nix")
        .args([
            "run",
            "nixpkgs#age-keygen",
            "--",
            "-o", key_path.to_str().unwrap(),
        ])
        .status()?;
    
    if !status.success() {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            "Failed to generate age key"
        ));
    }
    
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let mut perms = fs::metadata(key_path)?.permissions();
        perms.set_mode(0o600);
        fs::set_permissions(key_path, perms)?;
    }
    
    Ok(())
}

fn extract_public_key(key_path: &Path) -> io::Result<String> {
    println!("Extracting public key...");
    
    // Method A: Try to grep it from the comment
    let file = File::open(key_path)?;
    let reader = BufReader::new(file);
    
    for line in reader.lines() {
        let line = line?;
        if line.starts_with("# public key:") {
            if let Some(key) = line.split_whitespace().nth(3) {
                return Ok(key.trim().to_string());
            }
        }
    }
    
    // Method B: Fallback to age -y
    let output = Command::new("nix")
        .args([
            "run",
            "nixpkgs#age",
            "--",
            "-y",
            key_path.to_str().unwrap(),
        ])
        .output()?;
    
    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
        Err(io::Error::new(
            io::ErrorKind::Other,
            "Failed to extract public key"
        ))
    }
}

fn derive_host_key() -> Option<String> {
    let host_key_path = Path::new("/etc/ssh/ssh_host_ed25519_key.pub");
    
    if !host_key_path.exists() {
        return None;
    }
    
    println!("Deriving host key...");
    
    let mut key_file = File::open(host_key_path).ok()?;
    let mut contents = String::new();
    key_file.read_to_string(&mut contents).ok()?;
    
    let mut child = Command::new("nix")
        .args(["run", "nixpkgs#ssh-to-age"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .ok()?;
    
    child.stdin.as_mut()?.write_all(contents.as_bytes()).ok()?;
    
    let output = child.wait_with_output().ok()?;
    
    if output.status.success() {
        Some(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
        None
    }
}

fn create_secrets_file(
    secrets_file: &Path,
    username: &str,
    user_key: &str,
    hostname: &str,
    host_key: &str,
) -> io::Result<()> {
    println!("Creating {}...", secrets_file.display());
    
    let content = format!(
        r#"let
  users = {{
    {} = "{}";
  }};

  systems = {{
    {} = "{}";
  }};

  all = (builtins.attrValues users) ++ (builtins.attrValues systems);
in
{{
}}
"#,
        username, user_key, hostname, host_key
    );
    
    let mut file = File::create(secrets_file)?;
    file.write_all(content.as_bytes())?;
    
    Ok(())
}

fn update_secrets_file(
    secrets_file: &Path,
    username: &str,
    user_key: &str,
    hostname: &str,
    host_key: &Option<String>,
) -> io::Result<()> {
    println!("Updating {}...", secrets_file.display());
    
    let content = fs::read_to_string(secrets_file)?;
    let mut lines: Vec<String> = content.lines().map(|s| s.to_string()).collect();
    
    // Update user key
    let user_pattern = format!("{} =", username);
    let user_replacement = format!("    {} = \"{}\";", username, user_key);
    
    let mut user_found = false;
    for (i, line) in lines.iter_mut().enumerate() {
        if line.contains(&user_pattern) {
            *line = user_replacement.clone();
            user_found = true;
            break;
        }
    }
    
    // Add user if not found
    if !user_found {
        for (i, line) in lines.iter().enumerate() {
            if line.contains("users = {") {
                lines.insert(i + 1, user_replacement);
                break;
            }
        }
    }
    
    // Update/add system key if provided
    if let Some(hkey) = host_key {
        let system_pattern = format!("{} =", hostname);
        let system_replacement = format!("    {} = \"{}\";", hostname, hkey);
        
        let mut system_found = false;
        for line in lines.iter_mut() {
            if line.contains(&system_pattern) {
                *line = system_replacement.clone();
                system_found = true;
                break;
            }
        }
        
        if !system_found {
            println!("Adding system: {}", hostname);
            for (i, line) in lines.iter().enumerate() {
                if line.contains("systems = {") {
                    lines.insert(i + 1, system_replacement);
                    break;
                }
            }
        }
    }
    
    let mut file = File::create(secrets_file)?;
    file.write_all(lines.join("\n").as_bytes())?;
    
    Ok(())
}

fn verify_nix_syntax(file: &Path) -> bool {
    Command::new("nix-instantiate")
        .args(["--parse", file.to_str().unwrap()])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

fn rekey_secrets(secrets_dir: &Path, secrets_file: &Path, age_key: &Path) -> io::Result<()> {
    // Count .age files
    let secrets_count = fs::read_dir(secrets_dir)?
        .filter_map(|e| e.ok())
        .filter(|e| {
            e.path()
                .extension()
                .map(|ext| ext == "age")
                .unwrap_or(false)
        })
        .count();
    
    if secrets_count > 0 {
        println!("Re-keying {} secrets...", secrets_count);
        
        let _ = Command::new("nix")
            .args([
                "run",
                "github:yaxitech/ragenix",
                "--",
                "--rules", secrets_file.to_str().unwrap(),
                "--identity", age_key.to_str().unwrap(),
                "-r",
            ])
            .status();
    }
    
    Ok(())
}

fn main() -> io::Result<()> {
    println!("=== Ragenix Flake Bootstrap ===");
    
    let username = env::var("USER")
        .or_else(|_| env::var("USERNAME"))
        .unwrap_or_else(|_| "user".to_string());
    
    let hostname = hostname();
    
    let root = git_root();
    let secrets_dir = root.join("secrets");
    let secrets_file = secrets_dir.join("secrets.nix");
    let age_key = PathBuf::from(env::var("HOME").unwrap_or_else(|_| ".".to_string()))
        .join(".config/age/keys.txt");
    
    fs::create_dir_all(age_key.parent().unwrap())?;
    
    // Generate key if needed
    if !age_key.exists() || age_key.metadata()?.len() == 0 {
        generate_age_key(&age_key)?;
    }
    
    // Extract public key
    let user_key = extract_public_key(&age_key)
        .unwrap_or_else(|_| fail("Could not extract public key. Is it a valid age key?"));
    
    println!("✅ Master Identity ({}): {}", username, user_key);
    
    // Derive host key
    let host_key = derive_host_key();
    
    // Create secrets directory
    fs::create_dir_all(&secrets_dir)?;
    
    // Update or create secrets.nix
    if !secrets_file.exists() {
        create_secrets_file(
            &secrets_file,
            &username,
            &user_key,
            &hostname,
            host_key.as_deref().unwrap_or(""),
        )?;
    } else {
        update_secrets_file(
            &secrets_file,
            &username,
            &user_key,
            &hostname,
            &host_key,
        )?;
    }
    
    // Verify Nix syntax
    if verify_nix_syntax(&secrets_file) {
        println!("✅ secrets.nix is valid Nix");
    } else {
        fail("secrets.nix has syntax errors!");
    }
    
    // Rekey
    rekey_secrets(&secrets_dir, &secrets_file, &age_key)?;
    
    println!("\nDone.");
    
    Ok(())
}
