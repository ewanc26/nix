# Utility functions for nix-config modules.
#
# Import as an attrset — no arguments required:
#
#   let myLib = import ../lib; in
#   { environment.systemPackages = myLib.resolveFrom pkgs cfg.packages.common; }
#
# The functions here are pure helpers; all NixOS option wiring still uses the
# standard module system directly (see USAGE.md for patterns).
{
  # Resolve a list of attribute names against any package set, skipping names
  # that are absent rather than failing the build.  Traces a warning for each
  # missing entry so problems are visible without being fatal.
  #
  # Examples:
  #   resolveFrom pkgs             cfg.packages.common
  #   resolveFrom pkgs.kdePackages cfg.desktop.plasma.excludePackages
  resolveFrom =
    pkgSet: names:
    builtins.filter (x: x != null) (
      map (
        name:
        if pkgSet ? ${name} then
          pkgSet.${name}
        else
          builtins.trace "WARNING: '${name}' not found in package set, skipping" null
      ) names
    );
}
