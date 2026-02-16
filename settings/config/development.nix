let
  # Pull the font primitives from the single source of truth so VS Code
  # stays in sync with KDE/Konsole without hardcoding "FiraCode" twice.
  desktop = import ./desktop.nix;

  # VS Code uses the bare family name (no "Nerd Font Mono" suffix) for the
  # editor pane, and the Nerd Font variant (without "Mono") for the terminal.
  editorFont   = desktop.monoFontBase;                          # "FiraCode"
  terminalFont = "${desktop.monoFontBase} Nerd Font";           # "FiraCode Nerd Font"
in
{
  # Development configuration

  # VS Code configuration
  vscode = {
    enable = true;

    # Theme
    colorTheme = "Catppuccin Mocha";
    iconTheme  = "catppuccin-vsc-icons";

    # Editor appearance — font strings derived from desktop.nix primitives
    fontFamily         = "'${editorFont}', 'monospace'";  # "'FiraCode', 'monospace'"
    terminalFontFamily = "'${terminalFont}'";             # "'FiraCode Nerd Font'"
    fontSize           = 14;
    terminalFontSize   = 13;
    lineHeight         = 22;
    fontLigatures      = true;

    # Extensions from nixpkgs (pkgs.vscode-extensions.<publisher>.<name>).
    # Must match attribute paths in the nixpkgs vscode-extensions set.
    extensions = [
      # ── Nix ──────────────────────────────────────────────────────────────────
      "jnoortheen.nix-ide"          # Nix LSP, formatting, error reporting

      # ── Python ───────────────────────────────────────────────────────────────
      "ms-python.python"            # Python IntelliSense + debugger
      "ms-python.debugpy"           # Python debugger (required peer dep)

      # ── Rust ─────────────────────────────────────────────────────────────────
      "rust-lang.rust-analyzer"     # Rust LSP

      # ── C# / VB.NET (.NET) ───────────────────────────────────────────────────
      "ms-dotnettools.csharp"       # C# and VB.NET language support
      "ms-dotnettools.csdevkit"     # C# Dev Kit (solution explorer, test runner)

      # ── Shell / Bash ─────────────────────────────────────────────────────────
      "mads-hartmann.bash-ide-vscode" # Bash language server
      "timonwong.shellcheck"          # ShellCheck linting for sh/bash/zsh
      "foxundermoon.shell-format"     # shfmt formatter for shell scripts

      # ── Docker ───────────────────────────────────────────────────────────────
      "ms-azuretools.vscode-docker"   # Dockerfile syntax, linting, Docker integration

      # ── Data / config formats ─────────────────────────────────────────────────
      "tamasfe.even-better-toml"    # TOML (Cargo.toml, starship.toml, pyproject.toml…)
      "redhat.vscode-yaml"          # YAML with JSON schema validation

      # ── Web / Frontend ────────────────────────────────────────────────────────
      "bradlc.vscode-tailwindcss"   # Tailwind CSS IntelliSense
      "dbaeumer.vscode-eslint"      # ESLint (JS/TS/Svelte)
      "esbenp.prettier-vscode"      # Prettier formatter (JS/TS/CSS/HTML/JSON/YAML…)

      # ── Git ───────────────────────────────────────────────────────────────────
      "eamodio.gitlens"             # Git blame, history, diffing
      "editorconfig.editorconfig"   # .editorconfig support

      # ── General quality-of-life ───────────────────────────────────────────────
      "streetsidesoftware.code-spell-checker" # Spell checking in comments/strings
      "christian-kohler.path-intellisense"    # Filename autocompletion

      # ── Theme / icons ─────────────────────────────────────────────────────────
      # catppuccin-vsc and catppuccin-vsc-icons are installed by the
      # catppuccin home-manager module automatically — do not declare here.
    ];

    # Extensions from the VS Code Marketplace via the nix-vscode-extensions
    # overlay (pkgs.vscode-marketplace.<publisher>.<name>).
    # Use this for extensions not packaged in base nixpkgs 25.11.
    marketplaceExtensions = [
      "golang.go"                # Go language support (requires gopls on PATH)
      "svelte.svelte-vscode"     # Svelte language server
      "ms-vscode.makefile-tools" # Makefile syntax, build targets, IntelliSense
    ];
  };
}
