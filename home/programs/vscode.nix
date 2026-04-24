# VS Code configuration.
{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  cfg = osConfig.myConfig;
  d = cfg.desktop;
  isDarwin = pkgs.stdenv.isDarwin;

  # Font strings derived from desktop options — single source of truth.
  editorFont = d.monoFontBase; # "FiraCode"
  terminalFont = "${d.monoFontBase} Nerd Font"; # "FiraCode Nerd Font"

  toNixpkgsExt =
    extStr:
    let
      parts = lib.splitString "." extStr;
    in
    pkgs.vscode-extensions.${builtins.elemAt parts 0}.${builtins.elemAt parts 1};

  toMarketplaceExt =
    extStr:
    let
      parts = lib.splitString "." extStr;
    in
    pkgs.vscode-marketplace.${builtins.elemAt parts 0}.${builtins.elemAt parts 1};

  nixpkgsExtensions = [
    "jnoortheen.nix-ide"
    "ms-python.python"
    "ms-python.debugpy"
    "charliermarsh.ruff"
    "rust-lang.rust-analyzer"
    "ms-dotnettools.csharp"
    "ms-dotnettools.csdevkit"
    "mads-hartmann.bash-ide-vscode"
    "timonwong.shellcheck"
    "foxundermoon.shell-format"
    "ms-azuretools.vscode-docker"
    "tamasfe.even-better-toml"
    "redhat.vscode-yaml"
    "bradlc.vscode-tailwindcss"
    "dbaeumer.vscode-eslint"
    "esbenp.prettier-vscode"
    "eamodio.gitlens"
    "editorconfig.editorconfig"
    "streetsidesoftware.code-spell-checker"
    "christian-kohler.path-intellisense"
  ];

  marketplaceExtensions = [
    "golang.go"
    "svelte.svelte-vscode"
    "ms-vscode.makefile-tools"
  ];

  # Settings path differs by platform:
  #   macOS: ~/Library/Application Support/Code/User/settings.json
  #   NixOS: ~/.config/Code/User/settings.json
  settingsPath =
    if isDarwin then
      "Library/Application Support/Code/User/settings.json"
    else
      ".config/Code/User/settings.json";
in
{
  programs.vscode = {
    enable = cfg.development.vscode.enable;

    profiles.default = {
      extensions = map toNixpkgsExt nixpkgsExtensions ++ map toMarketplaceExt marketplaceExtensions;
      # Settings managed via home.file below (writable, stored in nix-config)
      userSettings = { };
    };
  };

  # Writable VS Code settings — symlinked from nix-config repo.
  # Edit at ~/.config/nix-config/home/programs/vscode/settings.json
  home.file."${settingsPath}".source =
    config.lib.file.mkOutOfStoreSymlink "${builtins.getEnv "HOME"}/.config/nix-config/home/programs/vscode/settings.json";
}
