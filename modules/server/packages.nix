{ config, pkgs, cfgLib, ... }:

let
  cfg     = cfgLib.cfg;
  resolve = cfgLib.resolvePackages pkgs;
in
{
  environment.systemPackages =
    # Common CLI utilities (shared with laptop via settings/config/packages.nix)
    resolve cfg.packages.common
    # Cross-platform development tools (shared with laptop)
    ++ resolve cfg.packages.development
    # Server-only extras (defined in settings/config/packages.nix → server)
    ++ resolve cfg.packages.server
    # Server-specific tools not suited to the shared package lists
    ++ (with pkgs; [
      # System inspection
      iotop
      iftop
      lsof
      pciutils
      usbutils

      # Network diagnostics
      bind        # dig / nslookup
      inetutils   # telnet, ftp
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
  programs.bash.completion.enable   = true;

  # ── Restrict imperative package installation ──────────────────────────────────
  # Only root and members of the wheel group may connect to the Nix daemon
  # to build or install packages.  This keeps the server fully declarative:
  # non-privileged users cannot run `nix-env -i` or `nix profile install`.
  nix.settings.allowed-users = [ "root" "@wheel" ];
}
