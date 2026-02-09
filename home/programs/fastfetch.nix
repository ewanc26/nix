{ config, pkgs, lib, ... }:

{
  # Fastfetch configuration - source from configs directory
  xdg.configFile."fastfetch/config.jsonc".source = ../configs/fastfetch.jsonc;
}
