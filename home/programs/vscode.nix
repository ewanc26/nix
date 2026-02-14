{ config, pkgs, lib, ... }:

let
  cfg = import ../../settings/config.nix;

  # Convert "publisher.name" strings to pkgs.vscode-extensions.<publisher>.<name>
  toExt = extStr:
    let parts = lib.splitString "." extStr;
    in pkgs.vscode-extensions.${builtins.elemAt parts 0}.${builtins.elemAt parts 1};
in
{
  programs.vscode = {
    enable = cfg.development.vscode.enable;

    profiles.default = {
      extensions = map toExt cfg.development.vscode.extensions;

      userSettings = {
        "workbench.colorTheme"           = cfg.development.vscode.colorTheme;
        "workbench.iconTheme"            = cfg.development.vscode.iconTheme;
        "editor.fontFamily"              = cfg.development.vscode.fontFamily;
        "editor.fontSize"               = cfg.development.vscode.fontSize;
        "editor.lineHeight"             = cfg.development.vscode.lineHeight;
        "editor.fontLigatures"          = cfg.development.vscode.fontLigatures;
        "editor.formatOnSave"           = true;
        "editor.minimap.enabled"        = false;
        "editor.renderWhitespace"       = "boundary";
        "editor.rulers"                 = [ 80 120 ];
        "editor.tabSize"                = 2;
        "editor.insertSpaces"           = true;
        "files.autoSave"                = "afterDelay";
        "files.autoSaveDelay"           = 1000;
        "git.autofetch"                 = true;
        "git.confirmSync"               = false;
        "terminal.integrated.fontFamily" = cfg.development.vscode.terminalFontFamily;
        "terminal.integrated.fontSize"  = cfg.development.vscode.terminalFontSize;
        "workbench.startupEditor"       = "none";
        "explorer.confirmDelete"        = false;
        "explorer.confirmDragAndDrop"   = false;
      };
    };
  };
}
