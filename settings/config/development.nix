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

    # Extensions from nixpkgs (pkgs.vscode-extensions.<publisher>.<name>).
    # Must match attribute paths in the nixpkgs vscode-extensions set.
    extensions = [
      # ── Nix ─────────────────────────────────────────────────────────────
      "jnoortheen.nix-ide"          # Nix LSP, formatting, error reporting

      # ── Languages ───────────────────────────────────────────────────────
      "ms-python.python"            # Python IntelliSense + debugger
      "ms-python.debugpy"           # Python debugger (required peer dep)
      "rust-lang.rust-analyzer"     # Rust LSP
      "ms-dotnettools.csharp"       # C# language support
      "ms-dotnettools.csdevkit"     # C# Dev Kit (solution explorer, test runner)

      # ── Web / Frontend ──────────────────────────────────────────────────
      "bradlc.vscode-tailwindcss"   # Tailwind CSS IntelliSense
      "dbaeumer.vscode-eslint"      # ESLint integration
      "esbenp.prettier-vscode"      # Prettier formatter

      # ── Git ─────────────────────────────────────────────────────────────
      "eamodio.gitlens"             # Git blame, history, diffing
      "editorconfig.editorconfig"   # .editorconfig support

      # ── General quality-of-life ─────────────────────────────────────────
      "streetsidesoftware.code-spell-checker" # Spell checking in comments/strings
      "christian-kohler.path-intellisense"    # Filename autocompletion

      # ── Theme / icons ───────────────────────────────────────────────────
      "dracula-theme.theme-dracula"
      "pkief.material-icon-theme"
    ];

    # Extensions from the VS Code Marketplace via the nix-vscode-extensions
    # overlay (pkgs.vscode-marketplace.<publisher>.<name>).
    # Use this for extensions not packaged in base nixpkgs 25.11.
    marketplaceExtensions = [
      "golang.go"            # Go language support (requires gopls on PATH)
      "svelte.svelte-vscode" # Svelte language server
    ];
  };
}
