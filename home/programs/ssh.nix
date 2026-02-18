# SSH client configuration.
# Platform detection via pkgs.stdenv.isDarwin.
{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  cfg = osConfig.myConfig;
  isDarwin = pkgs.stdenv.isDarwin;
  userName = cfg.user.username;

  # Tailscale binary path differs by platform.
  # macOS: absolute path inside Tailscale.app — ProxyCommand runs with minimal
  #        environment so Homebrew PATH isn't available.
  # Linux: Nix package provides the binary.
  tailscaleBin =
    if isDarwin then
      "/Applications/Tailscale.app/Contents/MacOS/Tailscale"
    else
      "${pkgs.tailscale}/bin/tailscale";

  internalHosts = [
    "laptop"
    "server"
    "macmini"
  ];

  tailscaleHostBlocks = lib.listToAttrs (
    map (hostName: {
      name = hostName;
      value = {
        user = userName;
        proxyCommand = "${tailscaleBin} nc %h %p";
        extraOptions = {
          ControlMaster = "auto";
          ControlPath = "~/.ssh/sockets/tailscale-%r@%h-%p";
          ControlPersist = "600";
        };
      };
    }) internalHosts
  );
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = tailscaleHostBlocks // {
      "*" = {
        extraOptions = {
          ControlMaster = "auto";
          ControlPath = "~/.ssh/sockets/%r@%h-%p";
          ControlPersist = "600";
          AddKeysToAgent = "yes";
        };
      };
    };
  };

  # Linux desktop: enable SSH agent and load keys at login.
  services.ssh-agent = lib.mkIf (!isDarwin && cfg.isDesktop) {
    enable = true;
  };

  systemd.user.services.ssh-load-keys = lib.mkIf (!isDarwin && cfg.isDesktop) {
    Unit = {
      Description = "Load SSH keys into agent via KWallet";
      After = [
        "ssh-agent.service"
        "graphical-session.target"
      ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.openssh}/bin/ssh-add";
      Environment = [
        "SSH_AUTH_SOCK=%t/ssh-agent"
        "SSH_ASKPASS=${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass"
        "SSH_ASKPASS_REQUIRE=prefer"
      ];
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # macOS: load SSH keys from Keychain into the agent at login.
  launchd.agents.ssh-load-keychain = lib.mkIf isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/ssh-add"
        "--apple-load-keychain"
      ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/ssh-add-keychain.log";
      StandardErrorPath = "/tmp/ssh-add-keychain.log";
    };
  };

  # Ensure the socket directory exists.
  home.file.".ssh/sockets/.keep".text = "";
}
