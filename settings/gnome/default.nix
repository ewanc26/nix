{ config, pkgs, lib, ... }:

{
  imports = [
    # Desktop settings
    ./desktop/interface/interface.nix
    ./desktop/wm/preferences.nix
    ./desktop/wm/keybindings.nix
    ./desktop/peripherals/touchpad.nix
    ./desktop/peripherals/mouse.nix
    ./desktop/peripherals/keyboard.nix
    ./desktop/background/background.nix
    ./desktop/screensaver/screensaver.nix
    ./desktop/notifications/notifications.nix
    ./desktop/privacy/privacy.nix
    ./desktop/sound/sound.nix
    ./desktop/a11y/accessibility.nix
    
    # Shell settings
    ./shell/shell.nix
    ./shell/extensions/extensions.nix
    ./shell/keybindings/keybindings.nix
    
    # Mutter (window manager)
    ./mutter/mutter.nix
    ./mutter/keybindings.nix
    
    # Settings daemon
    ./settings-daemon/settings-daemon.nix
    ./settings-daemon/plugins.nix
    
    # Applications
    ./applications/terminal/terminal.nix
    ./applications/nautilus/nautilus.nix
    ./applications/gedit/gedit.nix
    ./applications/calculator/calculator.nix
    ./applications/calendar/calendar.nix
  ];

  # Additional manual overrides or custom settings can go here
  dconf.settings = {
    # File chooser settings (not auto-exported)
    "org/gtk/settings/file-chooser" = {
      sort-directories-first = true;
    };
  };

  # Copy wallpaper to home directory
  home.file.".config/wallpapers/wallpaper.jpg" = {
    source = ../../wallpapers/wallpaper.jpg;
  };
}
