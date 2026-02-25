##############################################################################
#  Grafana + Prometheus — tailnet-only observability stack.
#
#  Architecture:
#    Prometheus scrapes:
#      • node_exporter      — system metrics (CPU, mem, disk, net)
#      • caddy              — request rates, latency, TLS
#      • nextcloud          — user counts, file counts, app status
#      • immich             — job queue, library stats
#      • jellyfin           — via prometheus-jellyfin-exporter
#      • postgres (×2)      — Nextcloud and Immich DB stats
#    Grafana reads from Prometheus and serves dashboards.
#
#  Access:
#    https://grafana.ewancroft.uk — tailnet only, via Caddy on Tailscale IP.
#    Prometheus itself is localhost-only; never exposed directly.
##############################################################################
{
  config,
  lib,
  ...
}:
let
  cfg = config.myConfig;
  hasTailnet = cfg.server.tailscaleIP != "";
  gf = cfg.server.grafana;

  prometheusPort = 9090;
  grafanaPort = gf.port;

  # Scrape configs built conditionally per enabled service
  scrapeConfigs =
    [
      # ── System ──────────────────────────────────────────────────────────────
      {
        job_name = "node";
        static_configs = [ { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ]; } ];
      }
      # ── Caddy ───────────────────────────────────────────────────────────────
      {
        job_name = "caddy";
        static_configs = [ { targets = [ "127.0.0.1:2019" ]; } ];
        metrics_path = "/metrics";
      }
    ]
    ++ lib.optional (cfg.services.nextcloud.enable && cfg.server.grafana.nextcloudMetrics) {
      job_name = "nextcloud";
      static_configs = [ { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.nextcloud.port}" ]; } ];
    }
    ++ lib.optional config.services.postgresql.enable {
      job_name = "postgres";
      static_configs = [ { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.postgres.port}" ]; } ];
    };
in
lib.mkIf hasTailnet {

  # ── Prometheus exporters ─────────────────────────────────────────────────
  services.prometheus.exporters = {
    node = {
      enable = true;
      port = 9100;
      enabledCollectors = [
        "cpu"
        "diskstats"
        "filesystem"
        "loadavg"
        "meminfo"
        "netdev"
        "stat"
        "systemd"
        "time"
        "uname"
      ];
    };

    # Nextcloud exporter is disabled until the Monitoring app is installed
    # and secrets/nextcloud-metrics-token is created. Enable by setting
    # myConfig.server.grafana.nextcloudMetrics = true in the host config.
    nextcloud = lib.mkIf (cfg.services.nextcloud.enable && cfg.server.grafana.nextcloudMetrics) {
      enable = true;
      port = 9205;
      url = "https://${cfg.nextcloud.hostname}";
      tokenFile = config.sops.secrets."nextcloud-metrics-token".path;
    };

    postgres = lib.mkIf config.services.postgresql.enable {
      enable = true;
      port = 9187;
      runAsLocalSuperUser = true;
    };

  };

  # Nextcloud metrics token — generate in Nextcloud admin → Monitoring app,
  # then: sops secrets/nextcloud-metrics-token (binary, raw token).
  # Only activated when myConfig.server.grafana.nextcloudMetrics = true.
  sops.secrets."nextcloud-metrics-token" = lib.mkIf (cfg.services.nextcloud.enable && cfg.server.grafana.nextcloudMetrics) {
    sopsFile = ../secrets/nextcloud-metrics-token;
    format = "binary";
    owner = "nextcloud-exporter";
    mode = "0440";
  };

  # ── Caddy metrics ────────────────────────────────────────────────────────
  # Expose /metrics on the admin API port (2019, localhost only by default).
  services.caddy.globalConfig = lib.mkAfter ''
    servers {
      metrics
    }
  '';

  # ── Prometheus ───────────────────────────────────────────────────────────
  services.prometheus = {
    enable = true;
    port = prometheusPort;
    listenAddress = "127.0.0.1";
    retentionTime = "30d";
    inherit scrapeConfigs;
  };

  # ── Grafana ──────────────────────────────────────────────────────────────
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = grafanaPort;
        domain = gf.hostname;
        root_url = "https://${gf.hostname}";
        enforce_domain = false;
      };
      analytics.reporting_enabled = false;
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:${toString prometheusPort}";
          isDefault = true;
        }
      ];
    };
  };

  # ── Caddy vhosts ─────────────────────────────────────────────────────────
  services.caddy.virtualHosts."http://${gf.hostname}" = {
    extraConfig = ''
      bind ${cfg.server.tailscaleIP}
      redir https://${gf.hostname}{uri} permanent
    '';
  };

  services.caddy.virtualHosts."https://${gf.hostname}" = {
    extraConfig = ''
      bind ${cfg.server.tailscaleIP}
      tls ${cfg.server.acmeCertDir}/fullchain.pem ${cfg.server.acmeCertDir}/key.pem
      reverse_proxy http://127.0.0.1:${toString grafanaPort}
    '';
  };
}
