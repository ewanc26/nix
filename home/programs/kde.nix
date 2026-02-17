# KDE Plasma desktop settings — desktop hosts only (not server).
# Terminal profile lives in terminal.nix and is imported separately for all
# non-Darwin hosts; this file is only the plasma-manager layer.
{ lib, cfgLib, ... }:

{
  imports = [
    ../../settings/plasma
  ];
}
