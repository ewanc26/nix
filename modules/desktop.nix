# KDE Plasma 6 desktop environment.
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.myConfig;

  resolveKde =
    names:
    builtins.filter (x: x != null) (
      map (
        name:
        if pkgs.kdePackages ? ${name} then
          pkgs.kdePackages.${name}
        else
          builtins.trace "WARNING: kdePackages.${name} not found, skipping" null
      ) names
    );
in
{
  # X11/Wayland base — required even in Wayland sessions.
  services.xserver = {
    enable = true;
    videoDrivers = [ "modesetting" ];
    xkb.layout = "gb";
  };

  services.displayManager.sddm = lib.mkIf (cfg.desktop.displayManager == "sddm") {
    enable = true;
    wayland.enable = true;
  };

  services.desktopManager.plasma6.enable = cfg.desktop.environment == "plasma6";

  environment.systemPackages = with pkgs; [
    kdePackages.qtstyleplugin-kvantum
    kdePackages.kcalc
    libgtop
  ];

  services.libinput.mouse.accelSpeed = "-0.5";

  services.libinput.touchpad = {
    naturalScrolling = false;
    tapping = false;
    scrollMethod = "twofinger";
  };

  environment.plasma6.excludePackages = resolveKde cfg.desktop.plasma.excludePackages;
}
