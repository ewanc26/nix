{ osConfig, lib, ... }:
let
  cfg = osConfig.myConfig;
  configFile =
    if cfg.isDesktop
    then ../configs/fastfetch.jsonc
    else ../configs/fastfetch-server.jsonc;
in
{
  programs.fastfetch.enable = true;
  xdg.configFile."fastfetch/config.jsonc".source = configFile;
}
