# Shared XMRig option declarations.
# Imported by both modules/darwin/xmrig.nix and
# modules/server/services/utils/xmrig.nix so the interface stays in sync.
{
  config,
  lib,
  ...
}:
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
          fast  — ~2 GB RAM, full hashrate. Only worthwhile on well-provisioned machines.
      '';
    };

    pauseOnActive = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Pause mining while the machine is actively used (mouse/keyboard input).
        Set true on workstations and desktops; leave false on headless servers.
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
}
