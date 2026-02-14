use tools_common::{self, *};

fn main() -> io::Result<()> {
    let age_key = PathBuf::from(env::var("HOME").unwrap()).join(".config/age/keys.txt");
    if !age_key.exists() {
        println!("⚠️ Age key missing at {}", age_key.display());
    } else {
        println!("✅ Secrets environment ready.");
    }
    Ok(())
}
