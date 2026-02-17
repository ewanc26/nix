{
  # Secrets configuration
  enable = true;
  masterKeyPath = "~/.config/age/keys.txt";

  # Core secrets (always present once set up)
  files = [
    "ssh-passphrase"
    "wifi-home"
  ];

  # Optional per-app secrets.
  # Set enable = true only after the corresponding .age file has been created
  # by the migration script (secrets/age/<name>.age must exist in the repo).
  docker  = { enable = true;  };   # ~/.docker/config.json
  claude  = { enable = true;  };   # ~/.claude.json
  duckdns = { enable = false; };   # ~/.duckdns/ — server/Linux only; enable per-host
  forgejo = { enable = false; };   # Forgejo SECRET_KEY + INTERNAL_TOKEN — enable after creating secrets/age/forgejo.env.age
}
