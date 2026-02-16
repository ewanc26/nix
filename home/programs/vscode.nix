{
  pkgs,
  lib,
  cfgLib,
  ...
}:

let
  cfg = cfgLib.cfg;

  # Resolve "publisher.name" → pkgs.vscode-extensions.<publisher>.<n>
  toNixpkgsExt =
    extStr:
    let
      parts = lib.splitString "." extStr;
    in
    pkgs.vscode-extensions.${builtins.elemAt parts 0}.${builtins.elemAt parts 1};

  # Resolve "publisher.name" → pkgs.vscode-marketplace.<publisher>.<n>
  # Provided by the nix-vscode-extensions overlay added in flake.nix.
  toMarketplaceExt =
    extStr:
    let
      parts = lib.splitString "." extStr;
    in
    pkgs.vscode-marketplace.${builtins.elemAt parts 0}.${builtins.elemAt parts 1};
in
{
  programs.vscode = {
    enable = cfg.development.vscode.enable;

    profiles.default = {
      extensions =
        map toNixpkgsExt cfg.development.vscode.extensions
        ++ map toMarketplaceExt cfg.development.vscode.marketplaceExtensions;

      userSettings = {
        "workbench.colorTheme" = lib.mkDefault cfg.development.vscode.colorTheme;
        "workbench.iconTheme" = lib.mkDefault cfg.development.vscode.iconTheme;
        "editor.fontFamily" = cfg.development.vscode.fontFamily;
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
        "terminal.integrated.fontFamily" = cfg.development.vscode.terminalFontFamily;
        "terminal.integrated.fontSize" = cfg.development.vscode.terminalFontSize;
        "workbench.startupEditor" = "none";
        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;

        # ── Per-language default formatters ───────────────────────────────────
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

        # ── Nix IDE ───────────────────────────────────────────────────────────
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.serverSettings".nil.formatting.command = [ "nixfmt" ];

        # ── Go ────────────────────────────────────────────────────────────────
        "go.useLanguageServer" = true;

        # ── Python ───────────────────────────────────────────────────────────
        "python.analysis.typeCheckingMode" = "basic";
        "ruff.lint.enable" = true;

        # ── Shell ─────────────────────────────────────────────────────────────
        # Point extensions at Nix-managed binaries so they work regardless of PATH.
        "shellcheck.executablePath" = "shellcheck";
        "shellformat.path" = "shfmt";
        "bashIde.shellcheckPath" = "shellcheck";

        # ── YAML ──────────────────────────────────────────────────────────────
        "yaml.format.enable" = true;
        "yaml.validate" = true;

        # ── TOML ──────────────────────────────────────────────────────────────
        "evenBetterToml.formatter.alignEntries" = false;
        "evenBetterToml.formatter.arrayTrailingComma" = true;
      };
    };
  };
}
