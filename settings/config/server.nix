{
  # Server configuration

  # SSH daemon
  sshd = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
    kbdInteractiveAuthentication = false;
    port = 22;
    maxAuthTries = 3;
    clientAliveInterval = 300;
    clientAliveCountMax = 2;
    x11Forwarding = false;
  };

  # Fail2ban intrusion prevention
  fail2ban = {
    enable = true;
    maxRetry = 5;
    banTime = 600;   # seconds – 10 minutes
    findTime = 600;  # seconds – detection window
  };

  # Firewall
  firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [ 22 ];  # Add ports as needed
    allowedUDPPorts = [ ];
  };
}
