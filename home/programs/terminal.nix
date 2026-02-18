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
    defaultProfile = "Catppuccin Mocha";
    profiles."Catppuccin Mocha" = {
      name = "Catppuccin Mocha";
      colorScheme = "Catppuccin Mocha";
      font = {
        name = d.monoFontFamily;
        size = d.monoFontSize;
      };
    };
  };
}
