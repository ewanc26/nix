# Ghostty terminal — all desktop hosts (Darwin + Linux).
# On Darwin, uses the pre-built ghostty-bin package (avoids building from
# source / Xcode requirement). On Linux, uses the full nixpkgs package.
{
  pkgs,
  osConfig,
  isDarwin,
  ...
}:
let
  cfg = osConfig.myConfig;
  d = cfg.desktop;
in
{
  programs.ghostty = {
    enable = true;

    package = if isDarwin then pkgs.ghostty-bin else pkgs.ghostty;

    enableZshIntegration = true;

    settings = {
      # ── Font ────────────────────────────────────────────────────────────
      font-family = d.monoFontFamily;
      font-size = d.monoFontSize;

      # ── Theme ───────────────────────────────────────────────────────────
      background = "1e1e2e";
      foreground = "cdd6f4";

      # ── Window ──────────────────────────────────────────────────────────
      window-decoration = if isDarwin then "auto" else "none";
      background-opacity = 0.95;
      background-blur-radius = 20;

      # ── Cursor ──────────────────────────────────────────────────────────
      cursor-style = "bar";
      cursor-style-blink = true;

      # ── Scrollback ──────────────────────────────────────────────────────
      scrollback-limit = 10000;

      # ── Misc ────────────────────────────────────────────────────────────
      confirm-close-surface = false;
      copy-on-select = false;
    };
  };
}
