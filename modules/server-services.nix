{ config, pkgs, ... }:

{
  # SSH Server Configuration
  services.openssh = {
    enable = true;
    
    settings = {
      # Security settings
      PermitRootLogin = "no";
      PasswordAuthentication = false; # Only key-based auth
      KbdInteractiveAuthentication = false;
      
      # Allow only specific users
      AllowUsers = [ "ewan" ];
      
      # Connection settings
      MaxAuthTries = 3;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
      
      # X11 forwarding
      X11Forwarding = false;
    };
    
    # Listen on port 22
    ports = [ 22 ];
  };

  # Fail2ban for SSH protection
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    
    # NEW FORMAT: Use .settings for jail configuration
    jails = {
      sshd.settings = {
        enabled = true;
        port = "22";
        filter = "sshd";
        logpath = "/var/log/auth.log";
        maxretry = 5;
        findtime = 600;
        bantime = 3600;
      };
    };
  };

  # Automatic security updates (in addition to system.autoUpgrade)
  system.autoUpgrade = {
    allowReboot = false; # Set to true if you want automatic reboots
    rebootWindow = {
      lower = "02:00";
      upper = "05:00";
    };
  };

  # SMART monitoring for disk health
  services.smartd = {
    enable = true;
    notifications = {
      x11.enable = false;
      wall.enable = true;
    };
  };

  # Periodic filesystem trim for SSDs
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # Time synchronization
  services.timesyncd = {
    enable = true;
  };

  # System monitoring
  services.journald = {
    extraConfig = ''
      SystemMaxUse=500M
      MaxRetentionSec=1month
    '';
  };

  # Automatic log cleanup
  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 2 * * 0 root journalctl --vacuum-time=30d"
    ];
  };

  # Enable firewall (configured in host default.nix)
  networking.firewall.enable = true;

  # Disable unnecessary services
  services.avahi.enable = false;
  services.printing.enable = false;
  
  # Optional: Uncomment services as needed
  
  # Docker (if needed)
  # virtualisation.docker = {
  #   enable = true;
  #   autoPrune = {
  #     enable = true;
  #     dates = "weekly";
  #   };
  # };
  
  # Podman (Docker alternative)
  # virtualisation.podman = {
  #   enable = true;
  #   dockerCompat = true;
  #   autoPrune = {
  #     enable = true;
  #     dates = "weekly";
  #   };
  # };
  
  # Web server (Nginx)
  # services.nginx = {
  #   enable = true;
  #   recommendedGzipSettings = true;
  #   recommendedOptimisation = true;
  #   recommendedProxySettings = true;
  #   recommendedTlsSettings = true;
  # };
  
  # Database (PostgreSQL)
  # services.postgresql = {
  #   enable = true;
  #   package = pkgs.postgresql_16;
  #   ensureDatabases = [ "myapp" ];
  #   ensureUsers = [{
  #     name = "myapp";
  #     ensurePermissions = {
  #       "DATABASE myapp" = "ALL PRIVILEGES";
  #     };
  #   }];
  # };
}
