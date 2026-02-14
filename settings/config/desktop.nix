{
  # Desktop environment configuration (Linux)

  enable = true;

  # Desktop environment
  environment = "gnome";  # "gnome", "kde", "xfce", etc.

  # Display manager
  displayManager = "gdm";  # "gdm", "sddm", "lightdm", etc.

  # GTK/Qt theming
  theme     = "Adwaita-dark";
  iconTheme = "Adwaita";

  # Monospace font (used in GNOME Console, GNOME Terminal, IDE configs, etc.)
  monoFont         = "FiraCode Nerd Font Mono 11";
  monoFontConsole  = "FiraCode Nerd Font 10";  # GNOME Console uses a slightly different name/size

  # GNOME-specific settings
  gnome = {
    # Packages to exclude from the default GNOME install.
    # Must match top-level nixpkgs attribute names.
    excludePackages = [
      "gnome-photos"
      "gnome-tour"
      "gnome-music"
      "gnome-characters"
      "cheese"
      "gedit"
      "epiphany"
      "geary"
      "totem"
      "tali"
      "iagno"
      "hitori"
      "atomix"
    ];

    # GNOME extension packages to install from pkgs.gnomeExtensions.<name>
    extensionPackages = [
      "astra-monitor"
      "media-controls"
      "dash-to-dock"
    ];

    # Extension UUIDs to enable (must match the installed extensions)
    enabledExtensions = [
      "astra-monitor@astraext.github.io"
      "mediacontrols@cliffniff.github.com"
      "dash-to-dock@micxgx.gmail.com"
      "system-monitor@gnome-shell-extensions.gcampax.github.com"
      "extension-list@tu.berry"
      "drive-menu@gnome-shell-extensions.gcampax.github.com"
      "add-to-desktop@tommimon.github.com"
      "fq@megh"
    ];
  };
}
