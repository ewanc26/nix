{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.myConfig;

  resolvePackages =
    names:
    builtins.filter (x: x != null) (
      map (
        name:
        if pkgs ? ${name} then
          pkgs.${name}
        else
          builtins.trace "WARNING: package '${name}' not found in nixpkgs, skipping" null
      ) names
    );

  # Packages from the shared development list that are too large or that are
  # better managed via Homebrew on a space-constrained 256 GB Mac.
  #
  # - ollama       ~300 MB binary; model weights are GBs each — use Homebrew
  #                cask or install on-demand instead.
  # - dotnet-sdk   ~600 MB; install via Homebrew cask if needed on macOS.
  # - openjdk21    ~300 MB; macOS users typically want the Homebrew/Temurin build.
  darwinDevExclude = [
    "ollama"
    "dotnet-sdk"
    "openjdk21"
  ];

  developmentForDarwin = lib.filter
    (name: !(builtins.elem name darwinDevExclude))
    cfg.packages.development;
in
{
  environment.systemPackages =
    # Common CLI utilities (all systems)
    resolvePackages cfg.packages.common
    # Cross-platform development packages — with heavy/macOS-inappropriate ones removed
    ++ resolvePackages developmentForDarwin
    # macOS-specific packages (GNU replacements, build libs)
    ++ resolvePackages cfg.packages.darwin;

  programs = {
    # zsh is already enabled in darwin/common.nix
    bash.enable = true;
  };
}
