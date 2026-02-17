/// server-config — interactive configurator for the NixOS server settings.
///
/// Reads the current values from settings/config/{server,forgejo,matrix,pds,cloudflare}.nix,
/// presents an interactive menu to change them, then writes the modified files back in-place.
///
/// Usage:
///   nix run .#server-config          # interactive (full menu)
///   nix run .#server-config -- --show # print current config and exit
use console::Style;
use dialoguer::{theme::ColorfulTheme, Confirm, Input, MultiSelect, Select};
use regex::Regex;
use std::fmt::Write as _;
use tools_common::*;

// ── helpers ──────────────────────────────────────────────────────────────────

fn theme() -> ColorfulTheme { ColorfulTheme::default() }

/// Replace the value of a Nix attribute in-place.
///   key   = the bare attribute name (e.g. `"device"`)
///   value = the new Nix literal to write (e.g. `"\"/dev/sdb1\""`)
///
/// Handles:
///   key = "string";
///   key = true;  / key = false;
///   key = 1234;
fn nix_set_scalar(src: &str, key: &str, value: &str) -> String {
    // Match `key = <anything up to semicolon>;` with optional whitespace
    let pattern = format!(r"(?m)(\b{key}\s*=\s*)([^;]+)(;)");
    let re = Regex::new(&pattern).unwrap();
    if re.is_match(src) {
        re.replace(src, format!("${{1}}{value}${{3}}")).into_owned()
    } else {
        eprintln!("⚠️  key '{key}' not found — skipping");
        src.to_string()
    }
}

/// Read a scalar value from a Nix file.
fn nix_get_scalar<'a>(src: &'a str, key: &str) -> Option<&'a str> {
    let pattern = format!(r"(?m)\b{key}\s*=\s*([^;]+);");
    let re = Regex::new(&pattern).unwrap();
    re.captures(src).map(|c| {
        // We can't return a lifetime-bound reference from a local Regex,
        // so we find the match start manually.
        let m = re.find(src).unwrap();
        let cap_start = m.start() + c.get(0).unwrap().as_str().find(c.get(1).unwrap().as_str()).unwrap();
        &src[cap_start..cap_start + c.get(1).unwrap().as_str().len()]
    })
}

fn strip_nix_string(s: &str) -> String {
    s.trim().trim_matches('"').to_string()
}

fn read_file(path: &Path) -> String {
    fs::read_to_string(path).unwrap_or_else(|e| {
        eprintln!("❌  Cannot read {}: {}", path.display(), e);
        std::process::exit(1);
    })
}

fn write_file(path: &Path, content: &str) {
    fs::write(path, content).unwrap_or_else(|e| {
        eprintln!("❌  Cannot write {}: {}", path.display(), e);
        std::process::exit(1);
    });
}

// ── config representation ────────────────────────────────────────────────────

#[derive(Debug, Clone)]
struct ServiceToggles {
    forgejo:    bool,
    pds:        bool,
    matrix:     bool,
    cloudflare: bool,
}

#[derive(Debug, Clone)]
struct StorageConfig {
    device:  String,
    fs_type: String,
}

#[derive(Debug, Clone)]
struct CockpitConfig {
    enable: bool,
    port:   u16,
}

#[derive(Debug, Clone)]
struct ForgejoConfig {
    hostname:             String,
    port:                 u16,
    caddy_port:           u16,
    app_name:             String,
    disable_registration: bool,
}

#[derive(Debug, Clone)]
struct MatrixConfig {
    hostname:    String,
    server_name: String,
    port:        u16,
    caddy_port:  u16,
}

#[derive(Debug, Clone)]
struct PdsConfig {
    hostname:    String,
    port:        u16,
    caddy_port:  u16,
    admin_email: String,
}

#[derive(Debug, Clone)]
struct CloudflareConfig {
    tunnel_id: String,
}

// ── readers ──────────────────────────────────────────────────────────────────

fn parse_bool(s: &str) -> bool { s.trim() == "true" }
fn parse_u16(s: &str) -> u16  { s.trim().parse().unwrap_or(0) }

fn read_services(src: &str) -> ServiceToggles {
    ServiceToggles {
        forgejo:    parse_bool(nix_get_scalar(src, "forgejo").unwrap_or("true")),
        pds:        parse_bool(nix_get_scalar(src, "pds").unwrap_or("true")),
        matrix:     parse_bool(nix_get_scalar(src, "matrix").unwrap_or("true")),
        cloudflare: parse_bool(nix_get_scalar(src, "cloudflare").unwrap_or("true")),
    }
}

fn read_storage(src: &str) -> StorageConfig {
    StorageConfig {
        device:  strip_nix_string(nix_get_scalar(src, "device").unwrap_or("\"/dev/sdb\"")),
        fs_type: strip_nix_string(nix_get_scalar(src, "fsType").unwrap_or("\"ext4\"")),
    }
}

fn read_cockpit(src: &str) -> CockpitConfig {
    // cockpit.enable lives alongside other booleans so we need to find it
    // after the "cockpit" heading comment
    let enable = if let Some(pos) = src.find("cockpit = {") {
        parse_bool(nix_get_scalar(&src[pos..], "enable").unwrap_or("true"))
    } else { true };
    let port = if let Some(pos) = src.find("cockpit = {") {
        parse_u16(nix_get_scalar(&src[pos..], "port").unwrap_or("9090"))
    } else { 9090 };
    CockpitConfig { enable, port }
}

fn read_forgejo(src: &str) -> ForgejoConfig {
    ForgejoConfig {
        hostname:             strip_nix_string(nix_get_scalar(src, "hostname").unwrap_or("\"git.ewancroft.uk\"")),
        port:                 parse_u16(nix_get_scalar(src, "port").unwrap_or("3001")),
        caddy_port:           parse_u16(nix_get_scalar(src, "caddyPort").unwrap_or("3002")),
        app_name:             strip_nix_string(nix_get_scalar(src, "appName").unwrap_or("\"Forgejo\"")),
        disable_registration: parse_bool(nix_get_scalar(src, "disableRegistration").unwrap_or("true")),
    }
}

fn read_matrix(src: &str) -> MatrixConfig {
    MatrixConfig {
        hostname:    strip_nix_string(nix_get_scalar(src, "hostname").unwrap_or("\"matrix.ewancroft.uk\"")),
        server_name: strip_nix_string(nix_get_scalar(src, "serverName").unwrap_or("\"ewancroft.uk\"")),
        port:        parse_u16(nix_get_scalar(src, "port").unwrap_or("8008")),
        caddy_port:  parse_u16(nix_get_scalar(src, "caddyPort").unwrap_or("8448")),
    }
}

fn read_pds(src: &str) -> PdsConfig {
    PdsConfig {
        hostname:    strip_nix_string(nix_get_scalar(src, "hostname").unwrap_or("\"pds.ewancroft.uk\"")),
        port:        parse_u16(nix_get_scalar(src, "port").unwrap_or("3000")),
        caddy_port:  parse_u16(nix_get_scalar(src, "caddyPort").unwrap_or("2020")),
        admin_email: strip_nix_string(nix_get_scalar(src, "adminEmail").unwrap_or("\"admin@example.com\"")),
    }
}

fn read_cloudflare(src: &str) -> CloudflareConfig {
    CloudflareConfig {
        tunnel_id: strip_nix_string(nix_get_scalar(src, "tunnelId").unwrap_or("\"<unset>\"")),
    }
}

// ── writers ──────────────────────────────────────────────────────────────────

fn write_services(src: &str, s: &ServiceToggles) -> String {
    // The service toggles sit inside a `services = { … }` block. Because all
    // four keys are bare booleans we can replace them by key name directly.
    // We scope each replacement to avoid touching unrelated `enable` fields.
    let src = nix_set_scalar(src, "forgejo",    &s.forgejo.to_string());
    let src = nix_set_scalar(&src, "pds",       &s.pds.to_string());
    let src = nix_set_scalar(&src, "matrix",    &s.matrix.to_string());
    nix_set_scalar(&src, "cloudflare",          &s.cloudflare.to_string())
}

fn write_storage(src: &str, st: &StorageConfig) -> String {
    let src = nix_set_scalar(src, "device",  &format!("\"{}\"", st.device));
    nix_set_scalar(&src, "fsType",           &format!("\"{}\"", st.fs_type))
}

fn write_cockpit(src: &str, c: &CockpitConfig) -> String {
    // Cockpit block comes AFTER the storage block in server.nix so we
    // replace only within the cockpit = { … } section.
    let block_start = src.find("cockpit = {").unwrap_or(0);
    let (before, after) = src.split_at(block_start);
    let after = nix_set_scalar(after, "enable", &c.enable.to_string());
    let after = nix_set_scalar(&after, "port",   &c.port.to_string());
    format!("{before}{after}")
}

fn write_forgejo(src: &str, f: &ForgejoConfig) -> String {
    let src = nix_set_scalar(src, "hostname",             &format!("\"{}\"", f.hostname));
    let src = nix_set_scalar(&src, "port",                &f.port.to_string());
    let src = nix_set_scalar(&src, "caddyPort",           &f.caddy_port.to_string());
    let src = nix_set_scalar(&src, "appName",             &format!("\"{}\"", f.app_name));
    nix_set_scalar(&src, "disableRegistration",           &f.disable_registration.to_string())
}

fn write_matrix(src: &str, m: &MatrixConfig) -> String {
    let src = nix_set_scalar(src, "hostname",   &format!("\"{}\"", m.hostname));
    let src = nix_set_scalar(&src, "serverName",&format!("\"{}\"", m.server_name));
    let src = nix_set_scalar(&src, "port",      &m.port.to_string());
    nix_set_scalar(&src, "caddyPort",           &m.caddy_port.to_string())
}

fn write_pds(src: &str, p: &PdsConfig) -> String {
    let src = nix_set_scalar(src, "hostname",   &format!("\"{}\"", p.hostname));
    let src = nix_set_scalar(&src, "port",      &p.port.to_string());
    let src = nix_set_scalar(&src, "caddyPort", &p.caddy_port.to_string());
    nix_set_scalar(&src, "adminEmail",          &format!("\"{}\"", p.admin_email))
}

fn write_cloudflare(src: &str, c: &CloudflareConfig) -> String {
    nix_set_scalar(src, "tunnelId", &format!("\"{}\"", c.tunnel_id))
}

// ── display ───────────────────────────────────────────────────────────────────

fn bool_str(b: bool) -> &'static str { if b { "enabled" } else { "disabled" } }

fn print_summary(
    svc: &ServiceToggles, st: &StorageConfig, ck: &CockpitConfig,
    fg: &ForgejoConfig, mx: &MatrixConfig, pd: &PdsConfig, cf: &CloudflareConfig,
) {
    let h1 = Style::new().bold().cyan();
    let kv = |k: &str, v: &str| println!("    {:<26} {}", format!("{k}:"), v);

    println!("\n{}", h1.apply_to("  ── Service toggles ──────────────────────"));
    kv("forgejo",    bool_str(svc.forgejo));
    kv("pds",        bool_str(svc.pds));
    kv("matrix",     bool_str(svc.matrix));
    kv("cloudflare", bool_str(svc.cloudflare));

    println!("\n{}", h1.apply_to("  ── /srv storage ──────────────────────────"));
    kv("device",  &st.device);
    kv("fsType",  &st.fs_type);

    println!("\n{}", h1.apply_to("  ── Cockpit dashboard ─────────────────────"));
    kv("enable", bool_str(ck.enable));
    kv("port",   &ck.port.to_string());

    println!("\n{}", h1.apply_to("  ── Forgejo ───────────────────────────────"));
    kv("hostname",             &fg.hostname);
    kv("port",                 &fg.port.to_string());
    kv("caddyPort",            &fg.caddy_port.to_string());
    kv("appName",              &fg.app_name);
    kv("disableRegistration",  bool_str(fg.disable_registration));

    println!("\n{}", h1.apply_to("  ── Matrix Synapse ────────────────────────"));
    kv("hostname",   &mx.hostname);
    kv("serverName", &mx.server_name);
    kv("port",       &mx.port.to_string());
    kv("caddyPort",  &mx.caddy_port.to_string());

    println!("\n{}", h1.apply_to("  ── Bluesky PDS ───────────────────────────"));
    kv("hostname",   &pd.hostname);
    kv("port",       &pd.port.to_string());
    kv("caddyPort",  &pd.caddy_port.to_string());
    kv("adminEmail", &pd.admin_email);

    println!("\n{}", h1.apply_to("  ── Cloudflare Tunnel ─────────────────────"));
    kv("tunnelId", &cf.tunnel_id);

    println!();
}

// ── interactive sections ──────────────────────────────────────────────────────

fn edit_services(svc: &mut ServiceToggles) {
    let names = ["forgejo", "pds (Bluesky ATProto)", "matrix", "cloudflare tunnel"];
    let current = [svc.forgejo, svc.pds, svc.matrix, svc.cloudflare];
    let defaults: Vec<bool> = current.to_vec();

    let selected = MultiSelect::with_theme(&theme())
        .with_prompt("Select services to ENABLE (space = toggle, enter = confirm)")
        .items(&names)
        .defaults(&defaults)
        .interact()
        .unwrap();

    svc.forgejo    = selected.contains(&0);
    svc.pds        = selected.contains(&1);
    svc.matrix     = selected.contains(&2);
    svc.cloudflare = selected.contains(&3);
}

fn edit_storage(st: &mut StorageConfig) {
    st.device = Input::with_theme(&theme())
        .with_prompt("/srv block device  (e.g. /dev/sdb, /dev/sdb1)")
        .with_initial_text(&st.device)
        .interact_text().unwrap();

    let fs_opts = ["ext4", "xfs", "btrfs"];
    let current_idx = fs_opts.iter().position(|&f| f == st.fs_type).unwrap_or(0);
    let sel = Select::with_theme(&theme())
        .with_prompt("Filesystem type")
        .items(&fs_opts)
        .default(current_idx)
        .interact().unwrap();
    st.fs_type = fs_opts[sel].to_string();
}

fn edit_cockpit(ck: &mut CockpitConfig) {
    ck.enable = Confirm::with_theme(&theme())
        .with_prompt("Enable Cockpit dashboard?")
        .default(ck.enable)
        .interact().unwrap();

    if ck.enable {
        let new_port: String = Input::with_theme(&theme())
            .with_prompt("Cockpit port  (accessible over Tailscale only)")
            .with_initial_text(&ck.port.to_string())
            .interact_text().unwrap();
        ck.port = new_port.trim().parse().unwrap_or(ck.port);
    }
}

fn edit_forgejo(fg: &mut ForgejoConfig) {
    fg.hostname = Input::with_theme(&theme())
        .with_prompt("Forgejo public hostname")
        .with_initial_text(&fg.hostname)
        .interact_text().unwrap();

    fg.app_name = Input::with_theme(&theme())
        .with_prompt("Forgejo display name")
        .with_initial_text(&fg.app_name)
        .interact_text().unwrap();

    let p: String = Input::with_theme(&theme())
        .with_prompt("Forgejo internal port")
        .with_initial_text(&fg.port.to_string())
        .interact_text().unwrap();
    fg.port = p.trim().parse().unwrap_or(fg.port);

    let cp: String = Input::with_theme(&theme())
        .with_prompt("Caddy internal port (tunnel → Caddy → Forgejo)")
        .with_initial_text(&fg.caddy_port.to_string())
        .interact_text().unwrap();
    fg.caddy_port = cp.trim().parse().unwrap_or(fg.caddy_port);

    fg.disable_registration = Confirm::with_theme(&theme())
        .with_prompt("Disable public registration?")
        .default(fg.disable_registration)
        .interact().unwrap();
}

fn edit_matrix(mx: &mut MatrixConfig) {
    mx.hostname = Input::with_theme(&theme())
        .with_prompt("Matrix public hostname  (e.g. matrix.example.com)")
        .with_initial_text(&mx.hostname)
        .interact_text().unwrap();

    mx.server_name = Input::with_theme(&theme())
        .with_prompt("Matrix server name  (used in @user:domain IDs)")
        .with_initial_text(&mx.server_name)
        .interact_text().unwrap();

    let p: String = Input::with_theme(&theme())
        .with_prompt("Synapse internal port")
        .with_initial_text(&mx.port.to_string())
        .interact_text().unwrap();
    mx.port = p.trim().parse().unwrap_or(mx.port);

    let cp: String = Input::with_theme(&theme())
        .with_prompt("Caddy internal port")
        .with_initial_text(&mx.caddy_port.to_string())
        .interact_text().unwrap();
    mx.caddy_port = cp.trim().parse().unwrap_or(mx.caddy_port);
}

fn edit_pds(pd: &mut PdsConfig) {
    pd.hostname = Input::with_theme(&theme())
        .with_prompt("PDS public hostname  (e.g. pds.example.com)")
        .with_initial_text(&pd.hostname)
        .interact_text().unwrap();

    pd.admin_email = Input::with_theme(&theme())
        .with_prompt("PDS admin email")
        .with_initial_text(&pd.admin_email)
        .interact_text().unwrap();

    let p: String = Input::with_theme(&theme())
        .with_prompt("PDS internal port")
        .with_initial_text(&pd.port.to_string())
        .interact_text().unwrap();
    pd.port = p.trim().parse().unwrap_or(pd.port);

    let cp: String = Input::with_theme(&theme())
        .with_prompt("Caddy internal port")
        .with_initial_text(&pd.caddy_port.to_string())
        .interact_text().unwrap();
    pd.caddy_port = cp.trim().parse().unwrap_or(pd.caddy_port);
}

fn edit_cloudflare(cf: &mut CloudflareConfig) {
    cf.tunnel_id = Input::with_theme(&theme())
        .with_prompt("Cloudflare tunnel UUID  (from: cloudflared tunnel create server)")
        .with_initial_text(&cf.tunnel_id)
        .interact_text().unwrap();
}

// ── main ─────────────────────────────────────────────────────────────────────

fn main() {
    let args: Vec<String> = env::args().collect();
    let show_only = args.iter().any(|a| a == "--show");

    let root   = git_root();
    let cfg    = root.join("settings/config");

    let server_path     = cfg.join("server.nix");
    let forgejo_path    = cfg.join("forgejo.nix");
    let matrix_path     = cfg.join("matrix.nix");
    let pds_path        = cfg.join("pds.nix");
    let cloudflare_path = cfg.join("cloudflare.nix");

    // Read all files
    let mut server_src     = read_file(&server_path);
    let mut forgejo_src    = read_file(&forgejo_path);
    let mut matrix_src     = read_file(&matrix_path);
    let mut pds_src        = read_file(&pds_path);
    let mut cloudflare_src = read_file(&cloudflare_path);

    // Parse current values
    let mut svc = read_services(&server_src);
    let mut st  = read_storage(&server_src);
    let mut ck  = read_cockpit(&server_src);
    let mut fg  = read_forgejo(&forgejo_src);
    let mut mx  = read_matrix(&matrix_src);
    let mut pd  = read_pds(&pds_src);
    let mut cf  = read_cloudflare(&cloudflare_src);

    let title = Style::new().bold().green();
    println!("\n{}", title.apply_to("  🖥️   Server configurator"));
    println!("  Repo: {}\n", root.display());

    if show_only {
        print_summary(&svc, &st, &ck, &fg, &mx, &pd, &cf);
        return;
    }

    // ── interactive menu loop ─────────────────────────────────────────────────
    let menu_items = [
        "Service toggles   (forgejo / pds / matrix / cloudflare)",
        "/srv storage       (block device, filesystem)",
        "Cockpit dashboard  (enable, port)",
        "Forgejo            (hostname, ports, app name, registration)",
        "Matrix Synapse     (hostname, server name, ports)",
        "Bluesky PDS        (hostname, ports, admin email)",
        "Cloudflare Tunnel  (tunnel UUID)",
        "── Show current config",
        "── Save and exit",
        "── Exit without saving",
    ];

    loop {
        let choice = Select::with_theme(&theme())
            .with_prompt("What do you want to configure?")
            .items(&menu_items)
            .default(0)
            .interact()
            .unwrap();

        match choice {
            0 => edit_services(&mut svc),
            1 => edit_storage(&mut st),
            2 => edit_cockpit(&mut ck),
            3 => edit_forgejo(&mut fg),
            4 => edit_matrix(&mut mx),
            5 => edit_pds(&mut pd),
            6 => edit_cloudflare(&mut cf),
            7 => print_summary(&svc, &st, &ck, &fg, &mx, &pd, &cf),
            8 => {
                // Apply changes to source strings
                server_src     = write_services(&server_src, &svc);
                server_src     = write_storage(&server_src, &st);
                server_src     = write_cockpit(&server_src, &ck);
                forgejo_src    = write_forgejo(&forgejo_src, &fg);
                matrix_src     = write_matrix(&matrix_src, &mx);
                pds_src        = write_pds(&pds_src, &pd);
                cloudflare_src = write_cloudflare(&cloudflare_src, &cf);

                // Write files
                write_file(&server_path,     &server_src);
                write_file(&forgejo_path,    &forgejo_src);
                write_file(&matrix_path,     &matrix_src);
                write_file(&pds_path,        &pds_src);
                write_file(&cloudflare_path, &cloudflare_src);

                println!("\n✅  Saved. Run `nrs` to apply changes.");

                // Optionally rebuild immediately
                if Confirm::with_theme(&theme())
                    .with_prompt("Run nixos-rebuild switch now?")
                    .default(false)
                    .interact()
                    .unwrap()
                {
                    let status = Command::new("sudo")
                        .args(["nixos-rebuild", "switch", "--flake", &format!("{}#server", root.display())])
                        .status();
                    match status {
                        Ok(s) if s.success() => println!("✅  Rebuild succeeded."),
                        Ok(s) => eprintln!("❌  Rebuild exited with status {s}"),
                        Err(e) => eprintln!("❌  Could not run nixos-rebuild: {e}"),
                    }
                }
                break;
            }
            9 => {
                println!("Exiting without saving.");
                break;
            }
            _ => {}
        }
    }
}
