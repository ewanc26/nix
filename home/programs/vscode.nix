{ config, pkgs, lib, ... }:

let
  cfg = import ../../settings/config.nix;

  # Resolve "publisher.name" → pkgs.vscode-extensions.<publisher>.<name>
  toNixpkgsExt = extStr:
    let parts = lib.splitString "." extStr;
    in pkgs.vscode-extensions.${builtins.elemAt parts 0}.${builtins.elemAt parts 1};

  # Resolve "publisher.name" → pkgs.vscode-marketplace.<publisher>.<name>
  # Provided by the nix-vscode-extensions overlay added in flake.nix.
  toMarketplaceExt = extStr:
    let parts = lib.splitString "." extStr;
    in pkgs.vscode-marketplace.${builtins.elemAt parts 0}.${builtins.elemAt parts 1};
in
{
  programs.vscode = {
    enable = cfg.development.vscode.enable;

    profiles.default = {
      extensions =
        map toNixpkgsExt    cfg.development.vscode.extensions
        ++ map toMarketplaceExt cfg.development.vscode.marketplaceExtensions;

      userSettings = {
        "workbench.colorTheme"            = lib.mkDefault cfg.development.vscode.colorTheme;
        "workbench.iconTheme"             = lib.mkDefault cfg.development.vscode.iconTheme;
        "editor.fontFamily"               = cfg.development.vscode.fontFamily;
        "editor.fontSize"                 = cfg.development.vscode.fontSize;
        "editor.lineHeight"               = cfg.development.vscode.lineHeight;
        "editor.fontLigatures"            = cfg.development.vscode.fontLigatures;
        "editor.formatOnSave"             = true;
        "editor.minimap.enabled"          = false;
        "editor.renderWhitespace"         = "boundary";
        "editor.rulers"                   = [ 80 120 ];
        "editor.tabSize"                  = 2;
        "editor.insertSpaces"             = true;
        "files.autoSave"                  = "afterDelay";
        "files.autoSaveDelay"             = 1000;
        "git.autofetch"                   = true;
        "git.confirmSync"                 = false;
        "terminal.integrated.fontFamily"  = cfg.development.vscode.terminalFontFamily;
        "terminal.integrated.fontSize"    = cfg.development.vscode.terminalFontSize;
        "workbench.startupEditor"         = "none";
        "explorer.confirmDelete"          = false;
        "explorer.confirmDragAndDrop"     = false;

        # Nix IDE — point at the nil language server
        "nix.enableLanguageServer"        = true;
        "nix.serverPath"                  = "nil";
        "nix.serverSettings".nil.formatting.command = [ "nixfmt" ];

        # Go — use the gopls on PATH
        "go.useLanguageServer"            = true;

        # Python — use pyright for type checking, ruff for linting/formatting
        "python.analysis.typeCheckingMode"         = "basic";
        "[python]"."editor.defaultFormatter"       = "charliermarsh.ruff";
        "ruff.lint.enable"                         = true;
      };
    };
  };
}
