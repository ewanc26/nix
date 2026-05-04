{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myConfig.services.xmrig;

  # Write config to nix store — xmrig reads it at launch
  xmrigConfig = pkgs.writeText "xmrig-config.json" (
    builtins.toJSON {
      autosave = false;
      background = false;
      colors = false;
      title = false;

      api = {
        id = null;
        "worker-id" = cfg.pool.rigId;
      };

      http = {
        enabled = false; # no Prometheus on darwin — no json_exporter available
        host = "127.0.0.1";
        port = 18080;
        "access-token" = null;
        restricted = true;
      };

      randomx = {
        mode = cfg.randomxMode;
        "1gb-pages" = false;
        rdmsr = false; # macOS doesn't support MSR
        wrmsr = false;
        numa = false; # Apple Silicon has no NUMA topology
        scratchpad_prefetch_mode = 1;
      };

      cpu = {
        enabled = true;
        "huge-pages" = false; # not supported on macOS
        "huge-pages-jit" = false;
        priority = 0; # lowest possible (0–5 scale in xmrig; maps to nice 19 via launchd)
        yield = true;
        "memory-pool" = true;
        "max-threads-hint" = cfg.threadsPercent;
        "pause-on-active" = cfg.pauseOnActive;
      };

      opencl.enabled = false;
      cuda.enabled = false;

      pools = [
        {
          algo = "rx/0";
          coin = "XMR";
          url = cfg.pool.url;
          user = cfg.pool.user;
          pass = cfg.pool.pass;
          "rig-id" = cfg.pool.rigId;
          nicehash = false;
          keepalive = true;
          enabled = true;
          tls = cfg.pool.tls;
          sni = cfg.pool.tls;
          daemon = false;
        }
      ];

      "donate-level" = 1;
      "donate-over-proxy" = 1;
      "print-time" = 60;
      retries = 5;
      "retry-pause" = 5;
      verbose = 0;
      watch = false;
    }
  );
in
{
  imports = [ ../../modules/xmrig-options.nix ];

  config = lib.mkIf cfg.enable {
    # Make xmrig available system-wide
    environment.systemPackages = [ pkgs.xmrig ];

    # launchd daemon — runs as root so it can access performance APIs
    launchd.daemons.xmrig = {
      serviceConfig = {
        Label = "uk.ewancroft.xmrig";
        ProgramArguments = [
          "${pkgs.xmrig}/bin/xmrig"
          "--config=${xmrigConfig}"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        # Background process type — macOS gives it lowest scheduling priority
        ProcessType = "Background";
        LowPriorityIO = true;
        Nice = 19;
        StandardOutPath = "/var/log/xmrig.log";
        StandardErrorPath = "/var/log/xmrig.log";
      };
    };
  };
}
