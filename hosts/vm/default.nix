{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/server-base.nix
    ../../profiles/server-hardened.nix
  ];

  networking.hostName = "vm";

  # Boot loader – EFI works best in UTM
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # VM root FS – UTM will use a disk image
  fileSystems."/".device = "root.img";
  fileSystems."/".fsType = "ext4";

  # Enable QEMU guest support
  services.qemuGuest.enable = true;

  # Optional: minimal memory and CPUs for UTM
  virtualisation.memorySize = 1024;   # 1GB RAM
  virtualisation.cores = 2;

  system.stateVersion = "25.11";
}