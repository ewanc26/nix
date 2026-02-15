{
  config,
  pkgs,
  lib,
  cfgLib,
  ...
}:

let
  cfg = cfgLib.cfg;

  # Safely resolve KDE package names under pkgs.kdePackages,
  # skipping any that do not exist rather than crashing the build.
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
  # X11/Wayland base – still required even in Wayland sessions
  services.xserver = {
    enable = true;

    videoDrivers = [ "modesetting" ];

    xkb.layout = "gb";
  };

  # Display manager – driven from settings/config/desktop.nix
  services.displayManager.sddm = lib.mkIf (cfg.desktop.displayManager == "sddm") {
    enable = true;
    wayland.enable = true; # Prefer Wayland session for Plasma 6
  };

  # Desktop environment – KDE Plasma 6
  services.desktopManager.plasma6.enable = cfg.desktop.environment == "plasma6";

  # Kvantum is the recommended theming engine for Qt/Plasma
  environment.systemPackages = with pkgs; [
    kdePackages.qtstyleplugin-kvantum # Kvantum Qt6 style engine (used by home-manager qt module)
    kdePackages.kcalc # Calculator (lightweight, commonly needed)
    libgtop # Required for resource monitors / KSysGuard sensors
  ];

  # Mouse – mac: "com.apple.mouse.scaling" = 0.5 (slow/precise)
  # libinput accelSpeed: -1 (slowest) … 0 (default) … +1 (fastest)
  services.libinput.mouse.accelSpeed = "-0.5";

  # Touchpad – mac: trackpad.Clicking = false, swipescrolldirection = false
  services.libinput.touchpad = {
    naturalScrolling = false; # mac: "com.apple.swipescrolldirection" = false
    tapping = false; # mac: trackpad.Clicking = false
    scrollMethod = "twofinger";
  };

  # Exclude unwanted default KDE packages – list driven from settings/config/desktop.nix
  environment.plasma6.excludePackages = resolveKde cfg.desktop.plasma.excludePackages;
}
