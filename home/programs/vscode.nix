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
      extensions =
        map toNixpkgsExt nixpkgsExtensions ++ map toMarketplaceExt marketplaceExtensions;

      userSettings = {
        "workbench.colorTheme" = lib.mkDefault cfg.development.vscode.colorTheme;
        "workbench.iconTheme" = lib.mkDefault cfg.development.vscode.iconTheme;
        "editor.fontFamily" = "'${editorFont}', 'monospace'";
        "editor.fontSize" = cfg.development.vscode.fontSize;
        "editor.lineHeight" = cfg.development.vscode.lineHeight;
        "editor.fontLigatures" = cfg.development.vscode.fontLigatures;
        "editor.formatOnSave" = true;
        "editor.minimap.enabled" = false;
        "editor.renderWhitespace" = "boundary";
        "editor.rulers" = [
          80
          120
        ];
        "editor.tabSize" = 2;
        "editor.insertSpaces" = true;
        "files.autoSave" = "afterDelay";
        "files.autoSaveDelay" = 1000;
        "git.autofetch" = true;
        "git.confirmSync" = false;
        "terminal.integrated.fontFamily" = "'${terminalFont}'";
        "terminal.integrated.fontSize" = cfg.development.vscode.terminalFontSize;
        "workbench.startupEditor" = "none";
        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;

        "[javascript]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[typescript]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[svelte]"."editor.defaultFormatter" = "svelte.svelte-vscode";
        "[css]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[html]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[json]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[jsonc]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[yaml]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[toml]"."editor.defaultFormatter" = "tamasfe.even-better-toml";
        "[shellscript]"."editor.defaultFormatter" = "foxundermoon.shell-format";
        "[dockerfile]"."editor.defaultFormatter" = "ms-azuretools.vscode-docker";
        "[makefile]"."editor.defaultFormatter" = "ms-vscode.makefile-tools";
        "[python]"."editor.defaultFormatter" = "charliermarsh.ruff";

        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.serverSettings".nil.formatting.command = [ "nixfmt" ];

        "go.useLanguageServer" = true;

        "python.analysis.typeCheckingMode" = "basic";
        "ruff.lint.enable" = true;

        "shellcheck.executablePath" = "shellcheck";
        "shellformat.path" = "shfmt";
        "bashIde.shellcheckPath" = "shellcheck";

        "yaml.format.enable" = true;
        "yaml.validate" = true;

        "evenBetterToml.formatter.alignEntries" = false;
        "evenBetterToml.formatter.arrayTrailingComma" = true;
      };
    };
  };
}
