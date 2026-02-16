let
  # ── Single-source font primitives ─────────────────────────────────────────
  # Change a name here and Konsole, KDE, and VS Code all update at once.
  monoFontBase   = "FiraCode";                          # root font family name
  monoFontFamily = "${monoFontBase} Nerd Font Mono";   # full name for KDE / Konsole
  monoFontSize   = 11;

  uiFont     = "Noto Sans";   # closest open-source match to macOS San Francisco
  uiFontSize = 10;
in
{
  # Desktop environment configuration (Linux)
  enable         = true;
  environment    = "plasma6";   # "gnome" | "plasma6" | "xfce"
  displayManager = "sddm";      # "gdm"  | "sddm"   | "lightdm"

  # GTK/Qt theming
  theme     = "Catppuccin-Mocha-Standard-Green-Dark";
  iconTheme = "Papirus-Dark";

  # ── Font primitives — single source of truth ──────────────────────────────
  # All consumers (KDE font roles, Konsole, VS Code) reference these;
  # nothing below is ever hardcoded elsewhere.
  inherit uiFont uiFontSize monoFontBase monoFontFamily monoFontSize;

  # Computed composites — derived, never typed twice
  monoFont        = "${monoFontFamily} ${toString monoFontSize}"; # "FiraCode Nerd Font Mono 11"
  monoFontConsole = monoFontFamily;   # Konsole font.name = family only (no trailing size)

  # ── KDE Plasma-specific settings ───────────────────────────────────────────
  plasma = {
    # Color scheme applied by plasma-apply-colorscheme on login.
    # Mirrors macOS: NSGlobalDomain.AppleInterfaceStyle = "Dark"
    #                NSGlobalDomain.AppleAccentColor    = 3 (Green)
    colorScheme  = "CatppuccinMochaGreen";

    # Plasma desktop style (controls panel/widget chrome).
    desktopTheme = "breeze-dark";

    # Packages to exclude from the default KDE Plasma install.
    # Must match attribute names under pkgs.kdePackages.
    excludePackages = [
      "oxygen"   # Legacy Oxygen theme — use Breeze/Catppuccin instead
      "elisa"    # KDE music player — use Spotify instead
    ];
  };
}
