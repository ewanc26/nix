{ config, pkgs, settings, ... }:

let
  cfg = settings;

  toPkg = name:
    if pkgs ? ${name} then pkgs.${name}
    else builtins.trace "WARNING: package '${name}' not found in nixpkgs, skipping" null;

  resolve = names: builtins.filter (x: x != null) (map toPkg names);
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
}
