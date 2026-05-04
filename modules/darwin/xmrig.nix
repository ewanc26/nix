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
        numa = true;
        scratchpad_prefetch_mode = 1;
      };

      cpu = {
        enabled = true;
        "huge-pages" = false; # not supported on macOS
        "huge-pages-jit" = false;
        priority = 0; # lowest possible (0–5 scale in xmrig; maps to nice 19 via launchd)
        yield = true;
        "memory-pool" = false;
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
  options.myConfig.services.xmrig = {
    enable = lib.mkEnableOption "XMRig Monero miner";

    threadsPercent = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = 50;
      description = ''
        Percentage of CPU threads xmrig may use (1–100).
        xmrig detects thread count at runtime and applies this cap.
      '';
    };

    randomxMode = lib.mkOption {
      type = lib.types.enum [
        "auto"
        "light"
        "fast"
      ];
      default = "light";
      description = ''
        RandomX dataset mode.
          light — ~256 MB RAM, lower hashrate.
          auto  — picks fast if RAM is available, light otherwise.
          fast  — ~2 GB RAM, full hashrate.
      '';
    };

    pauseOnActive = lib.mkOption {
      type = lib.types.bool;
      default = true; # sensible default for a desktop/workstation Mac
      description = "Pause mining while the machine is actively used.";
    };

    pool = {
      url = lib.mkOption {
        type = lib.types.str;
        default = "pool.supportxmr.com:443";
        description = "Stratum pool URL including port.";
      };

      user = lib.mkOption {
        type = lib.types.str;
        description = "Monero wallet address.";
      };

      pass = lib.mkOption {
        type = lib.types.str;
        default = "x";
        description = "Pool password / worker label.";
      };

      rigId = lib.mkOption {
        type = lib.types.str;
        default = config.networking.hostName;
        description = "Rig identifier shown on pool dashboard. Defaults to hostname.";
      };

      tls = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable TLS for the pool connection.";
      };
    };
  };

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
