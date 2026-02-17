{ ... }:

{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # /srv mount is declared by modules/server/storage.nix

  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = false;
}
