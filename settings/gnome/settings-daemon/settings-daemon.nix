# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "plugins/housekeeping" = {
      donation-reminder-last-shown = mkInt64 1770568675932549;
    };

  };
}
