# Minimal hardware config for the NixOS server.
# Auto-detected by nixos-generate-config; safe to regenerate.
# Common to both x86_64-linux and aarch64-linux server builds.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  # The server flake exposes both `server` (x86_64) and `server-arm` (aarch64)
  # from this one hardware file, so anything Intel-specific has to be guarded.
  # Without this, `server-arm` fails to evaluate outright: microcode-intel
  # refuses to evaluate on aarch64-linux.
  isX86 = pkgs.stdenv.hostPlatform.isx86;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "uas"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = lib.optionals isX86 [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/53c1ca4d-fdb9-47f0-ab81-ae871dacb11d";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/CF37-9198";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/914a24e1-c0cc-453d-bbf7-599c6e741fcd"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault (
    isX86 && config.hardware.enableRedistributableFirmware
  );
}
