{ config, pkgs, lib, ... }:

{
  # Fastfetch configuration
  xdg.configFile."fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": {
        "type": "small"
      },
      "structure": "title:host:uptime:os:kernel:packages:shell:de:wm:wmtheme:cpu:gpu:memory:swap:disk",
      "modules": [
        "title",
        "host",
        "uptime",
        "os",
        "kernel",
        "packages",
        "shell",
        "de",
        "wm",
        "wmtheme",
        "cpu",
        "gpu",
        "memory",
        "swap",
        "disk"
      ]
    }
  '';
}
