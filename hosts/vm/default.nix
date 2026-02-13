{ config, pkgs, ... }:

{
  imports = [
    ../../modules/users.nix
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

  system.stateVersion = "25.11";
}