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
  };

  config = lib.mkIf cfg.enable {
    services.xmrig = {
      enable = true;
      package = pkgs.xmrig;
      settings = {
        autosave = false; # declarative — never let xmrig overwrite config
        background = false;
        colors = false;
        title = false;

        api = {
          id = null;
          "worker-id" = "nixos-server";
        };

        http = {
          enabled = true;
          host = "127.0.0.1";
          port = xmrigApiPort;
          "access-token" = null;
          restricted = true; # read-only
        };

        randomx = {
          mode = "light"; # ~256MB RAM, lower hashrate — acceptable for background
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
          priority = 1; # idle class — OS always wins
          yield = true;
          "memory-pool" = false;
          # 4 threads on even cores — leaves headroom for services
          argon2 = [
            0
            2
            4
            6
          ];
          cn = [
            0
            2
            4
            6
          ];
          "cn-heavy" = [
            0
            2
          ];
          "cn-lite" = [
            0
            2
            4
            6
          ];
          "cn-pico" = [
            0
            2
            4
            6
          ];
          "cn/upx2" = [
            0
            2
            4
            6
          ];
          ghostrider = [
            [
              8
              0
            ]
            [
              8
              2
            ]
            [
              8
              4
            ]
            [
              8
              6
            ]
          ];
          rx = [
            0
            2
            4
            6
          ];
          "rx/wow" = [
            0
            2
            4
            6
          ];
          "cn-lite/0" = false;
          "cn/0" = false;
          "rx/arq" = "rx/wow";
        };

        opencl.enabled = false;
        cuda.enabled = false;

        pools = [
          {
            algo = "rx/0";
            coin = "XMR";
            url = "pool.supportxmr.com:443";
            user = "44yH2LpkSsrSmWQC3SVmrABw2MUhNjNCE365hG7Rr7veJYNPBD1f6dNgXNr2nc6ZcP3jEyj9vXnqmg7VBBPeS8uwMhJ4yXW";
            pass = "server";
            "rig-id" = "nixos-server";
            nicehash = false;
            keepalive = true;
            enabled = true;
            tls = true;
            sni = true;
            daemon = false;
          }
        ];

        "donate-level" = 1;
        "donate-over-proxy" = 1;
        "print-time" = 60;
        retries = 5;
        "retry-pause" = 5;
        verbose = 0;
        watch = false; # no config file to watch — declarative
      };
    };

    # Keep it truly idle — drop below normal niceness and use idle I/O
    systemd.services.xmrig.serviceConfig = {
      Nice = 19;
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
    };

    # ── Observability ────────────────────────────────────────────────────────
    # json_exporter bridges xmrig's HTTP JSON API → Prometheus metrics.
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

    # Scrape xmrig via json_exporter — merged into Prometheus alongside
    # the existing node/caddy/nextcloud/postgres jobs in grafana.nix.
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
