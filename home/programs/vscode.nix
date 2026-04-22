# VS Code configuration.
{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  cfg = osConfig.myConfig;
  d = cfg.desktop;

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

  # Writable VS Code settings — symlinked directly from nix-config repo.
  # Edit at ~/.config/nix-config/home/programs/vscode/settings.json
  home.file."Library/Application Support/Code/User/settings.json".source =
    lib.file.mkOutOfStoreSymlink "${builtins.getEnv "HOME"}/.config/nix-config/home/programs/vscode/settings.json";
}
