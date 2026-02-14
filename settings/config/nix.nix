{
  # Nix configuration
  
  # Experimental features
  experimentalFeatures = [ "nix-command" "flakes" ];
  
  # Store optimization
  autoOptimise = true;
  
  # Garbage collection
  gc = {
    automatic = true;
    dates = "weekly";           # "weekly", "daily", or specific time like "03:15"
    options = "--delete-older-than 30d";
  };
  
  # Channel/input versions
  # NOTE: These are for documentation only. Flake inputs cannot reference local files.
  # To update channels, edit the URLs directly in flake.nix inputs section.
  # These values are kept here for consistency and documentation.
  channels = {
    nixpkgs = "nixos-25.11";
    nixpkgsDarwin = "nixpkgs-25.11-darwin";
    homeManager = "release-25.11";
    nixDarwin = "nix-darwin-25.11";
  };
}
