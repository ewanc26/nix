# Wallpapers

Desktop wallpaper images used across the configuration.

## Current Wallpaper

- `wallpaper.jpg` — default desktop background and lock screen

## How it works

### Linux (KDE Plasma)

plasma-manager's `workspace.wallpaper` option applies wallpaper via D-Bus at
home-manager activation time. However, activation runs *before* the Plasma
session is live, so D-Bus isn't available and it silently fails.

Instead, a `systemd.user` service in `home/programs/kde.nix` calls
`plasma-apply-wallpaperimage` *after* `plasma-plasmashell.service` is up:

```nix
systemd.user.services.set-plasma-wallpaper = {
  Unit.After   = [ "plasma-plasmashell.service" ];
  Unit.PartOf  = [ "graphical-session.target" ];
  Service.Type = "oneshot";
  Service.ExecStart = "${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-wallpaperimage ${wallpaper}";
  Install.WantedBy  = [ "graphical-session.target" ];
};
```

### macOS

Applied via `programs.desktoppr` in `home/home.nix`.

## Changing the Wallpaper

1. Replace `wallpapers/wallpaper.jpg` with your image (keep the same filename), or
2. Add a new image and update the `wallpaper` let-binding in `home/programs/kde.nix`
3. Rebuild: `sudo nixos-rebuild switch --flake .#laptop`

The service will apply the new wallpaper on next login (or you can restart it manually):
```bash
systemctl --user restart set-plasma-wallpaper.service
```

## Recommended Format

- **Format:** JPG or PNG
- **Resolution:** 1920×1080 or higher
