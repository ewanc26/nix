use tools_common::{self, *};

const DOMAINS: &[&str] = &[
    "com.apple.dock", "com.apple.finder", "com.apple.screencapture",
    "com.apple.menuextra.clock", "com.apple.systemuiserver",
    "com.apple.AppleMultitouchTrackpad", "NSGlobalDomain",
];

fn main() -> io::Result<()> {
    println!("🍎 Exporting Darwin Settings...");
    let repo_root = git_root();
    let domains_dir = repo_root.join("settings/darwin/domains");
    fs::create_dir_all(&domains_dir)?;

    let mut combined = String::from("{ ... }:\n{\n  system.defaults.CustomUserPreferences = {\n");
    let mut count = 0;

    for domain in DOMAINS {
        let out_file = domains_dir.join(format!("{}.nix", domain));
        let args = ["run", "github:joshryandavis/defaults2nix", "--", domain, "-filter", "dates,state,uuids"];
        
        if capture_nix_to_file(&args, &out_file) {
            combined.push_str(&format!("    \"{}\" = import ./domains/{}.nix;\n", domain, domain));
            count += 1;
            println!("    ✅ Exported: {}", domain);
        }
    }
    combined.push_str("  };\n}\n");

    if count > 0 {
        let def_path = repo_root.join("settings/darwin/default.nix");
        File::create(&def_path)?.write_all(combined.as_bytes())?;
        git_sync("settings/darwin", "darwin");
    }
    Ok(())
}
