# Home-manager configuration — all hosts.
#
# Access system-level options via `osConfig.myConfig.*`.
# Platform detection: `isDarwin` is passed via extraSpecialArgs in flake.nix.
{
  config,
  pkgs,
  lib,
  osConfig,
  isDarwin,
  ...
}:
let
  cfg = osConfig.myConfig;

  # Custom scripts from home/scripts/ — available on PATH on both platforms.
  myScripts = pkgs.stdenv.mkDerivation {
    name = "my-scripts";
    src = ./scripts;
    installPhase = ''
      mkdir -p $out/bin
      cp -r * $out/bin/
      chmod +x $out/bin/*
    '';
  };

  allKeys = import ../modules/ssh-keys.nix;
in
{
  imports = [
    ./programs/git.nix
    ./programs/zsh.nix
    ./programs/ssh.nix
  ]
  ++ lib.optionals (!isDarwin && !cfg.isDesktop) [
    ./programs/terminal.nix # Konsole profile — Linux server hosts only
  ]
  ++ lib.optionals (cfg.isDesktop && !isDarwin) [
    ./programs/kde.nix # KDE Plasma settings — Linux desktop only
  ]
  ++ lib.optionals cfg.isDesktop [
    ./programs/vscode.nix # VSCode — desktop (mac-app-util handles macOS app bundle)
  ]
  ++ lib.optionals (cfg.isDesktop) [
    ./programs/starship.nix
    ./programs/ghostty.nix
  ]
  ++ [
    ./programs/fastfetch.nix
  ];

  home = {
    username = cfg.user.username;
    homeDirectory = if isDarwin then "/Users/${cfg.user.username}" else "/home/${cfg.user.username}";
    stateVersion = cfg.stateVersion;

    packages = [
      myScripts
    ]
    ++ map (font: pkgs.nerd-fonts.${font}) cfg.packages.fonts
    ++ lib.optionals (!isDarwin) (map (pkg: pkgs.${pkg}) cfg.packages.linux);

    # SSH authorised keys — all machines except this one.
    # Filter by hostname so each host does not authorise its own key.
    file.".ssh/authorized_keys".text =
      let
        hostName = osConfig.networking.hostName;
        filteredKeys = lib.attrValues (lib.filterAttrs (name: _: name != hostName) allKeys);
      in
      builtins.concatStringsSep "\n" filteredKeys;

    file.".ssh/allowed_signers".text =
      let
        entries = lib.mapAttrsToList (_: key: "${cfg.user.email} ${key}") allKeys;
        validEntries = lib.filter (e: !(lib.hasInfix "REPLACE_WITH" e)) (lib.unique entries);
      in
      builtins.concatStringsSep "\n" validEntries + "\n";

    file.".gitignore_global".text = builtins.concatStringsSep "\n" [
      ".DS_Store"
      ".DS_Store?"
      "._*"
      ".Spotlight-V100"
      ".Trashes"
      "ehthumbs.db"
      "Thumbs.db"
      ".vscode/"
      ".idea/"
      "*.swp"
      "*.swo"
      "*~"
      "*.tmp"
      "*.bak"
      "*.log"
    ];
  };

  # ── pnpm ──────────────────────────────────────────────────────────────────
  # home-manager has no programs.pnpm module. The correct declarative setup is:
  #   1. xdg.configFile writes ~/.config/pnpm/rc with global-bin-dir as an
  #      absolute path — pnpm reads this file directly, no shell needed.
  #   2. home.sessionVariables exports PNPM_HOME so pnpm itself knows where
  #      to store global packages.
  #   3. home.sessionPath prepends the bin dir to PATH using the dedicated
  #      home-manager option (avoids manual string concat in shell init).
  xdg.configFile."pnpm/rc".text = ''
    global-bin-dir=${config.home.homeDirectory}/.local/share/pnpm
  '';

  programs.home-manager.enable = true;

  # Disable the home-manager manual — avoids a known upstream warning about
  # options.json referencing store paths without proper context (HM issue #7935).
  manual.manpages.enable = false;
  manual.html.enable = false;
  manual.json.enable = false;

  # ── npm global packages ──────────────────────────────────────────────────────
  # Packages not in nixpkgs installed via npm. Each entry is idempotent —
  # skipped if the binary is already present.
  home.activation.npmGlobalPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _npm="${pkgs.nodejs_22}/bin/npm"
    _prefix=$("$_npm" prefix -g)
    if [ ! -f "$_prefix/bin/letta" ]; then
      echo "npm: installing @letta-ai/letta-code..."
      $DRY_RUN_CMD "$_npm" install -g @letta-ai/letta-code
    fi
  '';

  # ── nix-config git repo ────────────────────────────────────────────────────
  # Ensures ~/.config/nix-config is always a git repo with the correct remotes.
  # Server hosts only use origin (GitHub) — Tangled is for desktop hosts only.
  home.activation.nixConfigGitRepo = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    nix_config="${config.home.homeDirectory}/.config/nix-config"
    github_remote="git@github.com:ewanc26/nix"
    tangled_remote="git@tangled.org:ewancroft.uk/nix"

    if [ ! -d "$nix_config" ]; then
      echo "nix-config: directory not found, skipping git setup"
    else
      cd "$nix_config"

      if [ ! -d ".git" ]; then
        $DRY_RUN_CMD ${pkgs.git}/bin/git init
        $DRY_RUN_CMD ${pkgs.git}/bin/git checkout -b main
        echo "nix-config: initialised git repo"
      fi

      current_origin=$(${pkgs.git}/bin/git remote get-url origin 2>/dev/null || echo "")
      if [ -z "$current_origin" ]; then
        $DRY_RUN_CMD ${pkgs.git}/bin/git remote add origin "$github_remote"
        echo "nix-config: added origin -> $github_remote"
      elif [ "$current_origin" != "$github_remote" ]; then
        $DRY_RUN_CMD ${pkgs.git}/bin/git remote set-url origin "$github_remote"
        echo "nix-config: updated origin -> $github_remote"
      fi

      # Tangled remote — desktop hosts only
      if ${lib.boolToString cfg.isDesktop}; then
        current_tangled=$(${pkgs.git}/bin/git remote get-url tangled 2>/dev/null || echo "")
        if [ -z "$current_tangled" ]; then
          $DRY_RUN_CMD ${pkgs.git}/bin/git remote add tangled "$tangled_remote"
          echo "nix-config: added tangled -> $tangled_remote"
        elif [ "$current_tangled" != "$tangled_remote" ]; then
          $DRY_RUN_CMD ${pkgs.git}/bin/git remote set-url tangled "$tangled_remote"
          echo "nix-config: updated tangled -> $tangled_remote"
        fi
      fi
    fi
  '';

  # ── Developer directories ──────────────────────────────────────────────────
  # Creates ~/Developer/Git and ~/Developer/Local on all hosts.
  # ~/Developer/Git  — GitHub repos (ewanc26, minus nix) + non-mirror Forgejo repos.
  # ~/Developer/Local — private Forgejo repos (requires userApiTokenFile to be set).
  # Repos are cloned via SSH on first activation; existing dirs are never touched.
  home.activation.developerDirs = lib.hm.dag.entryAfter [ "writeBoundary" "setupSecrets" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/Developer/Git"
    $DRY_RUN_CMD mkdir -p "$HOME/Developer/Local"

    # Ensure ssh is visible to git during activation (PATH is stripped).
    export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh"

    # ── GitHub ────────────────────────────────────────────────────────────────
    if ${pkgs.curl}/bin/curl --silent --max-time 5 --output /dev/null "https://github.com"; then
      page=1
      while true; do
        gh_response=$(${pkgs.curl}/bin/curl --silent \
          "https://api.github.com/users/${cfg.user.githubUsername}/repos?per_page=100&page=$page")
        # Bail out if the API returned an error or rate-limit (non-array response).
        if ! echo "$gh_response" | ${pkgs.jq}/bin/jq -e 'type == "array"' > /dev/null 2>&1; then
          echo "developer: github API returned non-array response (rate limit?), stopping"
          break
        fi
        repos=$(echo "$gh_response" | ${pkgs.jq}/bin/jq -r '.[] | select(.fork == false and .archived == false) | .name // empty')
        [ -z "$repos" ] && break
        for repo in $repos; do
          [ "$repo" = "nix" ] && continue
          if [ ! -d "$HOME/Developer/Git/$repo" ]; then
            echo "developer: cloning github:${cfg.user.githubUsername}/$repo"
            $DRY_RUN_CMD ${pkgs.git}/bin/git clone \
              "git@github.com:${cfg.user.githubUsername}/$repo.git" \
              "$HOME/Developer/Git/$repo"
          fi
        done
        page=$((page + 1))
      done
    else
      echo "developer: github unreachable, skipping GitHub clones"
    fi

    # ── Forgejo ───────────────────────────────────────────────────────────────
    if ${pkgs.curl}/bin/curl --silent --max-time 5 --output /dev/null "https://${cfg.forgejo.hostname}"; then
      forgejo_token_arg=""
      ${lib.optionalString (cfg.forgejo.userApiTokenFile != null) ''
        _token_file="${cfg.forgejo.userApiTokenFile}"
        # On Darwin, sops-nix decrypts via a launchd agent after activation,
        # so the pre-decrypted file may not exist yet. Fall back to decrypting
        # directly with the user age key if available.
        if [ ! -f "$_token_file" ] && [ -f "$HOME/.config/age/keys.txt" ]; then
          _raw="${builtins.toString ../secrets/forgejo-user-token}"
          _token_file=$(mktemp)
          SOPS_AGE_KEY_FILE="$HOME/.config/age/keys.txt" \
            ${pkgs.sops}/bin/sops --decrypt --input-type binary --output-type binary \
            "$_raw" > "$_token_file" 2>/dev/null || { rm -f "$_token_file"; _token_file=""; }
        fi
        if [ -n "$_token_file" ] && [ -f "$_token_file" ]; then
          forgejo_token_arg="&token=$(cat "$_token_file")"
        else
          echo "developer: forgejo token unavailable, skipping private repos"
        fi
      ''}

      page=1
      while true; do
        page_data=$(${pkgs.curl}/bin/curl --silent \
          "https://${cfg.forgejo.hostname}/api/v1/repos/search?limit=50&page=$page$forgejo_token_arg")
        # Bail out if the API returned an error or non-JSON response.
        if ! echo "$page_data" | ${pkgs.jq}/bin/jq -e 'type == "object" and (.data | type == "array")' > /dev/null 2>&1; then
          echo "developer: forgejo API returned non-array response (server error?), stopping"
          break
        fi
        count=$(echo "$page_data" | ${pkgs.jq}/bin/jq '.data | length')
        [ "$count" = "0" ] && break

        # Non-mirror public repos -> Developer/Git
        while IFS= read -r name; do
          if [ ! -d "$HOME/Developer/Git/$name" ]; then
            echo "developer: cloning forgejo:${cfg.user.username}/$name"
            $DRY_RUN_CMD ${pkgs.git}/bin/git clone \
              "git@${cfg.forgejo.hostname}:${cfg.user.username}/$name.git" \
              "$HOME/Developer/Git/$name"
          fi
        done < <(echo "$page_data" \
          | ${pkgs.jq}/bin/jq -r '.data[] | select(.mirror == false and .private == false) | .name')

        ${lib.optionalString (cfg.forgejo.userApiTokenFile != null) ''
          # Non-mirror private repos -> Developer/Local (token required)
          while IFS= read -r name; do
            if [ ! -d "$HOME/Developer/Local/$name" ]; then
              echo "developer: cloning forgejo:${cfg.user.username}/$name (private)"
              $DRY_RUN_CMD ${pkgs.git}/bin/git clone \
                "git@${cfg.forgejo.hostname}:${cfg.user.username}/$name.git" \
                "$HOME/Developer/Local/$name"
            fi
          done < <(echo "$page_data" \
            | ${pkgs.jq}/bin/jq -r '.data[] | select(.mirror == false and .private == true) | .name')
        ''}

        page=$((page + 1))
      done
    else
      echo "developer: forgejo unreachable, skipping Forgejo clones"
    fi
  '';

  # ── Nextcloud desktop client ─────────────────────────────────────────────
  # Both activation scripts below patch nextcloud.cfg in-place so that
  # credentials/tokens already written by the client are preserved.

  # Enable VFS (virtual files) for all configured sync folders — files appear
  # as lightweight placeholders locally and are only downloaded on access,
  # keeping the primary copy on the server. Linux uses "suffix" mode (.nextcloud
  # placeholder files); this is a no-op if VFS is already on or if the cfg
  # file doesn't exist yet (new installs pick it up after first sync setup).
  home.activation.nextcloudVFS = lib.mkIf (cfg.isDesktop && !isDarwin) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      cfg_file="$HOME/.config/Nextcloud/nextcloud.cfg"
      if [ -f "$cfg_file" ]; then
        $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i 's/virtualFilesMode=off/virtualFilesMode=suffix/g' "$cfg_file"
      fi
    ''
  );

  # Ensure Nextcloud-synced dirs exist directly at $HOME.
  # On macOS, Pictures is excluded — Photos Library.photoslibrary is TCC-protected.
  # Any legacy symlinks pointing to ~/Nextcloud/* are replaced with real dirs.
  home.activation.nextcloudFolderLinks = lib.mkIf cfg.isDesktop (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if ! ${pkgs.curl}/bin/curl --silent --max-time 5 --output /dev/null "https://${cfg.nextcloud.hostname}"; then
        echo "nextcloud: server unreachable, skipping folder setup"
      else
        dirs="Desktop Downloads Documents Obsidian Archives Pictures"
        ${lib.optionalString isDarwin ''dirs="Desktop Downloads Documents Obsidian Archives"''}

        for dir in $dirs; do
          target="$HOME/$dir"

          # Replace legacy symlink (from old ~/Nextcloud/$dir setup) with a real dir.
          if [ -L "$target" ]; then
            echo "nextcloud: removing legacy symlink $target"
            $DRY_RUN_CMD rm "$target"
          fi

          if [ ! -d "$target" ]; then
            $DRY_RUN_CMD mkdir -p "$target"
            echo "nextcloud: created $target"
          fi
        done
      fi
    ''
  );

  # ── Nextcloud client autostart (Linux desktop) ─────────────────────────────
  # Writes an XDG autostart entry so nextcloud-client launches in the background
  # on every login. On macOS the client is installed as a cask and manages its
  # own login item, so this is Linux-only.
  xdg.configFile."autostart/Nextcloud.desktop" = lib.mkIf (cfg.isDesktop && !isDarwin) {
    text = ''
      [Desktop Entry]
      Categories=Network
      Comment=Nextcloud desktop sync client
      Exec=nextcloud --background
      GenericName=File Synchronizer
      Icon=Nextcloud
      Name=Nextcloud
      StartupNotify=false
      Type=Application
      X-GNOME-Autostart-enabled=true
      X-KDE-autostart-after=panel
    '';
  };

  # ── Nextcloud server pre-seed ─────────────────────────────────────────────
  # If no Nextcloud account has been configured yet (nextcloud.cfg missing or
  # has no [Accounts] section), write a minimal config seeding the server URL
  # and username. The client will open its OAuth flow to finish authentication
  # on first launch — credentials are stored in KWallet, never in this file.
  home.activation.nextcloudPreSeed = lib.mkIf (cfg.isDesktop && !isDarwin) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      nc_cfg="$HOME/.config/Nextcloud/nextcloud.cfg"
      if [ ! -f "$nc_cfg" ] || ! grep -q "^\[Accounts\]" "$nc_cfg"; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$nc_cfg")"
        echo "nextcloud: pre-seeding server URL in nextcloud.cfg"
        if [ -z "$DRY_RUN_CMD" ]; then
          printf '[Accounts]\n0\\authType=webflow\n0\\davUser=${cfg.user.username}\n0\\serverUrl=https://${cfg.nextcloud.hostname}\n0\\url=https://${cfg.nextcloud.hostname}\ncount=1\n\n[General]\n' > "$nc_cfg"
        fi
      fi
    ''
  );

  # Allow syncing files of any size (client default blocks files over ~500 MB).
  home.activation.nextcloudMaxSize = lib.mkIf cfg.isDesktop (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      cfg_file="$HOME/.config/Nextcloud/nextcloud.cfg"
      if [ -f "$cfg_file" ]; then
        if grep -q "maxSizeEnabled" "$cfg_file"; then
          $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i 's/^maxSizeEnabled=.*/maxSizeEnabled=false/' "$cfg_file"
        else
          $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i '/\[General\]/a maxSizeEnabled=false' "$cfg_file"
        fi
      fi
    ''
  );

  fonts.fontconfig.enable = true;

  # ── rbw (Bitwarden CLI) ──────────────────────────────────────────────────
  # Configured to talk to Bitwarden's hosted EU server.
  # Switch base_url back to "https://${cfg.vaultwarden.hostname}" when the
  # server is back online.
  # First run: `rbw login` — then `rbw get`, `rbw list`, `rbw edit` etc.
  xdg.configFile."rbw/config.json".text = builtins.toJSON {
    base_url = "https://vault.bitwarden.eu";
    email = cfg.user.email;
    lock_timeout = 3600;
    pinentry = "pinentry-mac";
  };

  # ── Linux-only theming ────────────────────────────────────────────────────
  gtk = lib.mkIf (!isDarwin && cfg.isDesktop) {
    enable = true;
    theme = {
      name = cfg.desktop.theme;
      package = pkgs.adw-gtk3;
    };
    iconTheme.name = cfg.desktop.iconTheme;
  };

  qt = lib.mkIf (!isDarwin && cfg.isDesktop) {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };

  # ── macOS: wallpaper via desktoppr ───────────────────────────────────────
  programs.desktoppr = lib.mkIf isDarwin {
    enable = true;
    settings.picture = "${../wallpapers/wallpaper.jpg}";
  };

  # ── Encrypted secrets (sops-nix) ─────────────────────────────────────────
  # The forgejo-user-token secret is decrypted at the system level (root) in
  # modules/common.nix and placed at /run/secrets/forgejo-user-token.
  # No home-manager sops config is needed — the HM sops service runs as the
  # user and cannot read /etc/ssh/ssh_host_ed25519_key (600 root:root).
}
