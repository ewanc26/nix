use std::env;
use std::path::PathBuf;
use std::process::Command;

pub fn fail(msg: &str) -> ! {
    eprintln!("❌ {}", msg);
    std::process::exit(1);
}

pub fn git_root() -> PathBuf {
    if let Ok(root) = env::var("PRJ_ROOT") {
        return PathBuf::from(root);
    }
    let output = Command::new("git")
        .args(["rev-parse", "--show-toplevel"])
        .output()
        .ok();
    
    if let Some(output) = output {
        let path_str = String::from_utf8_lossy(&output.stdout).trim().to_string();
        if output.status.success() && !path_str.contains("/nix/store") {
            return PathBuf::from(path_str);
        }
    }
    env::current_dir().unwrap_or_else(|_| PathBuf::from("."))
}

pub fn get_timestamp() -> String {
    let output = Command::new("date")
        .arg("+%Y-%m-%d %H:%M:%S")
        .output()
        .expect("Failed to get timestamp");
    String::from_utf8_lossy(&output.stdout).trim().to_string()
}

pub fn hostname() -> String {
    let output = Command::new("hostname")
        .arg("-s")
        .output()
        .expect("Failed to get hostname");
    String::from_utf8_lossy(&output.stdout).trim().to_string()
}
