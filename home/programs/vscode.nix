{ config, pkgs, ... }:

{
  programs.vscode = {
    enable = true;

    profiles.default = {
      # Extensions
      extensions = with pkgs.vscode-extensions; [
        # Language support
        bbenoist.nix
        ms-python.python
        rust-lang.rust-analyzer

        # Themes
        dracula-theme.theme-dracula
        pkief.material-icon-theme

        # Utilities
        esbenp.prettier-vscode
        editorconfig.editorconfig
      ];

      # User settings
      userSettings = {
        "workbench.colorTheme" = "Dracula";
        "workbench.iconTheme" = "material-icon-theme";
        "editor.fontFamily" = "'FiraCode', 'monospace'";
        "editor.fontSize" = 14;
        "editor.lineHeight" = 22;
        "editor.fontLigatures" = true;
        "editor.formatOnSave" = true;
        "editor.minimap.enabled" = false;
        "editor.renderWhitespace" = "boundary";
        "editor.rulers" = [ 80 120 ];
        "editor.tabSize" = 2;
        "editor.insertSpaces" = true;
        "files.autoSave" = "afterDelay";
        "files.autoSaveDelay" = 1000;
        "git.autofetch" = true;
        "git.confirmSync" = false;
        "terminal.integrated.fontFamily" = "'FiraCode Nerd Font'";
        "terminal.integrated.fontSize" = 13;
        "workbench.startupEditor" = "none";
        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;
      };
    };
  };
}