# Hardened SSH server config for the server profile.
# Keys-only auth, root login disabled, single allowed user.
# Settings driven entirely from myConfig.server.sshd.* options.
{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
in
{
  services.openssh = {
    # mkForce: SSH is the only remote access path. Nothing should override this.
    enable = lib.mkForce cfg.server.sshd.enable;
    ports = [ cfg.server.sshd.port ];

    settings = {
      PermitRootLogin = cfg.server.sshd.permitRootLogin;
      PasswordAuthentication = cfg.server.sshd.passwordAuthentication;
      KbdInteractiveAuthentication = cfg.server.sshd.kbdInteractiveAuthentication;
      AllowUsers = [ cfg.user.username ];
      MaxAuthTries = cfg.server.sshd.maxAuthTries;
      ClientAliveInterval = cfg.server.sshd.clientAliveInterval;
      ClientAliveCountMax = cfg.server.sshd.clientAliveCountMax;
      X11Forwarding = cfg.server.sshd.x11Forwarding;
    };
  };
}
