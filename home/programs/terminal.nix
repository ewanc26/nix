# Konsole terminal profile — all non-Darwin (Linux) hosts.
# Font family and size driven from myConfig.desktop options.
# macOS uses Ghostty instead (handled in ghostty.nix).
{
  osConfig,
  ...
}:
let
  cfg = osConfig.myConfig;
  d = cfg.desktop;
in
{
  programs.konsole = {
    enable = true;
    defaultProfile = "Default";
    profiles."Default" = {
      name = "Default";
      colorScheme = "Breeze";
      font = {
        name = d.monoFontFamily;
        size = d.monoFontSize;
      };
    };
  };
}
