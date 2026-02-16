{ lib, settings, ... }:

let
  cfg = settings;
in
{
  services.openssh = {
    enable = lib.mkDefault cfg.server.sshd.enable;
    ports  = [ cfg.server.sshd.port ];

    settings = {
      PermitRootLogin                = cfg.server.sshd.permitRootLogin;
      PasswordAuthentication         = cfg.server.sshd.passwordAuthentication;
      KbdInteractiveAuthentication   = cfg.server.sshd.kbdInteractiveAuthentication;
      AllowUsers                     = [ cfg.user.username ];
      MaxAuthTries                   = cfg.server.sshd.maxAuthTries;
      ClientAliveInterval            = cfg.server.sshd.clientAliveInterval;
      ClientAliveCountMax            = cfg.server.sshd.clientAliveCountMax;
      X11Forwarding                  = cfg.server.sshd.x11Forwarding;
    };
  };
}
