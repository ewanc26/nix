{ config, ... }:
let
  decrypted = config.age.secrets.gnome-dconf-settings.path;
in
{
  imports = [ (import decrypted) ];
}