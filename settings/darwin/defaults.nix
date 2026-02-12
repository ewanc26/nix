{ config, ... }:
let
  decrypted = config.age.secrets.darwin-defaults-settings.path;
in
{
  imports = [ (import decrypted) ];
}
