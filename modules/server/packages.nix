{
  config,
  pkgs,
  ...
}:
let
  cfg = config.myConfig;

  resolvePackages =
    names:
    builtins.filter (x: x != null) (
      map (
        name:
        if pkgs ? ${name} then
          pkgs.${name}
        else
          builtins.trace "WARNING: package '${name}' not found in nixpkgs, skipping" null
      ) names
    );
in
{
  environment.systemPackages =
    # Common CLI utilities (shared with laptop via myConfig.packages.common)
    resolvePackages cfg.packages.common
    # Cross-platform development tools (shared with laptop)
    ++ resolvePackages cfg.packages.development
    # Server-only extras
    ++ resolvePackages cfg.packages.server
    # Server-specific tools not suited to the shared package lists
    ++ (with pkgs; [
      # System inspection
      iotop
      iftop
      lsof
      pciutils
      usbutils

      # Network diagnostics
      bind # dig / nslookup
      inetutils # telnet, ftp
      traceroute
      mtr

      # Disk utilities
      parted
      gptfdisk
      smartmontools

      # Compression (server archiving)
      p7zip
      gnutar
      gzip
      bzip2
    ]);

  programs.command-not-found.enable = true;
  programs.bash.completion.enable = true;

  # ── Restrict imperative package installation ──────────────────────────────
  # Only root and members of the wheel group may connect to the Nix daemon
  # to build or install packages. This keeps the server fully declarative:
  # non-privileged users cannot run `nix-env -i` or `nix profile install`.
  nix.settings.allowed-users = [
    "root"
    "@wheel"
  ];
}
