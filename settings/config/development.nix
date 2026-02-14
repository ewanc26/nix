{
  # Development configuration

  # Programming languages/tools to install
  languages = [
    "nodejs"
    "python3"
    "go"
    "rust"
  ];

  # VS Code configuration
  vscode = {
    enable = true;

    # Theme
    colorTheme = "Dracula";
    iconTheme = "material-icon-theme";

    # Editor appearance
    fontFamily = "'FiraCode', 'monospace'";
    terminalFontFamily = "'FiraCode Nerd Font'";
    fontSize = 14;
    terminalFontSize = 13;
    lineHeight = 22;
    fontLigatures = true;

    # Extensions – must match nixpkgs vscode-extensions attribute paths ("publisher.name")
    extensions = [
      "bbenoist.nix"
      "ms-python.python"
      "rust-lang.rust-analyzer"
      "dracula-theme.theme-dracula"
      "pkief.material-icon-theme"
      "esbenp.prettier-vscode"
      "editorconfig.editorconfig"
    ];
  };
}
