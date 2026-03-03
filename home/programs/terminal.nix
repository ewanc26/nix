# Konsole terminal profile — all non-Darwin hosts.
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
