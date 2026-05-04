{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myConfig.services.xmrig;
  xmrigApiPort = 18080;
  jsonExporterPort = 9399;
in
{
  options.myConfig.services.xmrig = {
    enable = lib.mkEnableOption "XMRig Monero miner";

    threadsPercent = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = 50;
      description = ''
        Percentage of CPU threads xmrig may use (1–100).
        xmrig detects the thread count at runtime and applies this cap.
        Lower values reduce thermal load — use 25 on thermally constrained
        machines (e.g. laptops already running hot).
      '';
      example = 25;
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
          light — ~256 MB RAM, lower hashrate. Best for memory-constrained hosts.
          auto  — uses fast mode if enough free RAM, light otherwise.
          fast  — ~2 GB RAM, full hashrate. Only worthwhile on dedicated miners.
      '';
    };

    pauseOnActive = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Pause mining while the machine is actively used (desktop sessions).
        Set true on workstations/laptops, leave false on headless servers.
      '';
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
        description = "Rig identifier shown on the pool dashboard. Defaults to hostname.";
      };

      tls = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable TLS for the pool connection.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.xmrig = {
      enable = true;
      package = pkgs.xmrig;
      settings = {
        autosave = false;
        background = false;
        colors = false;
        title = false;

        api = {
          id = null;
          "worker-id" = cfg.pool.rigId;
        };

        http = {
          enabled = true;
          host = "127.0.0.1";
          port = xmrigApiPort;
          "access-token" = null;
          restricted = true;
        };

        randomx = {
          mode = cfg.randomxMode;
          "1gb-pages" = false;
          rdmsr = true;
          wrmsr = false;
          numa = true;
          scratchpad_prefetch_mode = 1;
        };

        cpu = {
          enabled = true;
          "huge-pages" = true;
          "huge-pages-jit" = false;
          priority = 1; # idle class
          yield = true;
          "memory-pool" = false;
          # Let xmrig detect thread count at runtime and cap by percentage.
          # Avoids hardcoded core indices that break on different hardware.
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
      };
    };

    # Idle scheduling — xmrig never competes with real workloads
    systemd.services.xmrig.serviceConfig = {
      Nice = 19;
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
    };

    # ── Observability ──────────────────────────────────────────────────────
    services.prometheus.exporters.json = {
      enable = true;
      port = jsonExporterPort;
      configFile = pkgs.writeText "xmrig-json-exporter.yaml" ''
        modules:
          xmrig:
            metrics:
              - name: xmrig_hashrate
                type: gauge
                help: "Current hashrate in H/s (10s average)"
                path: '{ .hashrate.total[0] }'
              - name: xmrig_hashrate_1m
                type: gauge
                help: "Current hashrate in H/s (1m average)"
                path: '{ .hashrate.total[1] }'
              - name: xmrig_uptime_seconds
                type: counter
                help: "XMRig uptime in seconds"
                path: '{ .uptime }'
              - name: xmrig_shares_accepted
                type: counter
                help: "Accepted shares"
                path: '{ .results.shares_good }'
              - name: xmrig_shares_rejected
                type: counter
                help: "Rejected shares"
                path: '{ .connection.rejected }'
              - name: xmrig_difficulty
                type: gauge
                help: "Current share difficulty"
                path: '{ .results.diff_current }'
              - name: xmrig_avg_share_time_seconds
                type: gauge
                help: "Average time per share in seconds"
                path: '{ .results.avg_time }'
      '';
    };

    services.prometheus.scrapeConfigs = [
      {
        job_name = "xmrig";
        metrics_path = "/probe";
        params = {
          module = [ "xmrig" ];
          target = [ "http://127.0.0.1:${toString xmrigApiPort}/1/summary" ];
        };
        static_configs = [ { targets = [ "127.0.0.1:${toString jsonExporterPort}" ]; } ];
      }
    ];
  };
}
