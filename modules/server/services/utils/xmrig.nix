{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myConfig.services.xmrig;
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
            url = "pool.supportxmr.com:3333";
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
  };
}
