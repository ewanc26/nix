##############################################################################
#  Sharkey ActivityPub / microblogging server — NixOS module.
#
#  Architecture:
#    Sharkey (127.0.0.1:cfg.sharkey.port)
#      ↑ reverse proxy
#    Caddy (http://ap.ewancroft.uk:cfg.sharkey.caddyPort — internal only)
#      ↑ Cloudflare tunnel (outbound only, no firewall ports needed)
#
#  Account identity:
#    settings.url  = "https://ap.ewancroft.uk/"  (Sharkey's public host)
#    WebFinger redirect at ewancroft.uk (Vercel) still points to
#    ap.ewancroft.uk, so handles resolve as @ewan@ewancroft.uk unchanged.
#
#  Service startup:
#    sharkey-migrate.service runs TypeORM migrations first, then
#    sharkey.service starts the main process via sharkey-precise.nix wrappers.
#
#  Secrets (via sops-nix):
#    secrets/meilisearch-master-key — raw binary key, owner meilisearch.
#    No DB password needed: database.createLocally uses peer auth over
#    the PostgreSQL unix socket at /run/postgresql.
#
#  Credentials in settings:
#    Any settings value of the form `{ file = /path/to/secret; }` is
#    extracted by scrub-secrets, injected via systemd LoadCredential, and
#    exposed to the process as MK_CONFIG_<UPPER_DOTTED_PATH>_FILE=<path>.
#
#  First-run:
#    Open https://ap.ewancroft.uk — Sharkey prompts for initial setup.
#
#  Upstream nixpkgs sharkey module is disabled in favour of this one,
#  which uses sharkey-precise.nix wrappers rather than the pnpm run shim.
##############################################################################
{
  options,
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  myCfg = config.myConfig;
  sk = myCfg.sharkey;
  skPort = toString sk.port;
  caddyPort = toString sk.caddyPort;

  skcfg = config.services.sharkey;

  sharkey-precise = pkgs.callPackage ./sharkey-precise.nix {
    sharkey = skcfg.package;
  };

  sharkey-migrate = lib.getExe' sharkey-precise "sharkey-migrate";
  sharkey-start = lib.getExe' sharkey-precise "sharkey-start";

  settingsFormat = pkgs.formats.yaml { };

  # Recursively walks the settings attrset. Any leaf of the form
  # `{ file = /path/to/secret; }` is treated as a secret: stripped from
  # the generated YAML and instead injected via systemd LoadCredential,
  # surfaced to the process as MK_CONFIG_<UPPER_PATH>_FILE=<cred-path>.
  scrub-secrets =
    loc: this:
    (
      if builtins.typeOf this == "set" then
        if builtins.attrNames this == [ "file" ] then
          {
            leaf = "secret";
            value = "";
            secret =
              if lib.types.path.check this.file then
                this.file
              else
                throw ''
                  The value for the option `${
                    lib.showOption (loc ++ [ "file" ])
                  }` is not of type `${lib.types.path.description}`. Value: ${
                    lib.generators.toPretty { } (
                      lib.generators.withRecursion {
                        depthLimit = 10;
                        throwOnDepthLimit = false;
                      } this.file
                    )
                  }
                '';
          }
        else
          let
            scrubbed = builtins.mapAttrs (k: scrub-secrets (loc ++ [ k ])) this;
            except-leaves = kind: lib.filterAttrs (_: v: v.leaf or null != kind);
            except-empty = lib.filterAttrs (_: v: v != { } && v != [ ]);
          in
          {
            value = lib.pipe scrubbed [
              (except-leaves "secret")
              (builtins.mapAttrs (_: v: v.value))
            ];
            secret = lib.pipe scrubbed [
              (except-leaves "value")
              (builtins.mapAttrs (_: v: v.secret))
              except-empty
            ];
          }

      else if lib.typeOf this == "list" then
        let
          scrubbed = lib.imap0 (i: v: scrub-secrets (loc ++ [ "[index ${toString i}]" ]) v) this;
        in
        {
          value = builtins.map (builtins.getAttr "value") scrubbed;
          secret = builtins.map (builtins.getAttr "secret") scrubbed;
        }
      else
        {
          leaf = "value";
          value = this;
          secret = { };
        }
    );

  scrubbed-settings = scrub-secrets (options.services.sharkey.settings.loc) skcfg.settings;

  configFile = settingsFormat.generate "sharkey-config.yml" scrubbed-settings.value;

  make-credentials =
    loc: this:
    if builtins.typeOf this == "set" then
      lib.mapAttrsToList (name: make-credentials (loc ++ [ (lib.strings.toUpper name) ])) this
    else if builtins.typeOf this == "list" then
      lib.imap0 (i: make-credentials (loc ++ [ (toString i) ])) this
    else
      {
        name = "MK_CONFIG_${builtins.concatStringsSep "_" loc}_FILE";
        value = lib.mkDefinition {
          file = lib.unknownModule;
          value = this;
        };
      };

  extracted-credentials = builtins.listToAttrs (
    lib.flatten (make-credentials [ ] scrubbed-settings.secret)
  );

in
{
  # Replace the upstream nixpkgs sharkey module with this one.
  disabledModules = [ "${modulesPath}/services/web-apps/sharkey.nix" ];

  # ── Option declarations ────────────────────────────────────────────────────
  options.services.sharkey = {
    enable = lib.mkEnableOption "sharkey";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.sharkey;
      defaultText = lib.literalExpression "pkgs.sharkey";
      description = "Sharkey package to use.";
    };

    database.createLocally = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Create the PostgreSQL database locally and configure Sharkey to use it.
        Uses peer authentication over the unix socket — no password required.
      '';
    };

    redis.createLocally = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Create the Redis server locally and configure Sharkey to use it.";
    };

    meilisearch.createLocally = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Create a local Meilisearch instance and wire it into Sharkey's config.";
    };

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      description = ''
        Configuration for Sharkey, see
        <link xlink:href="https://activitypub.software/TransFem-org/Sharkey/-/blob/develop/.config/example.yml"/>
        for supported settings.

        Values of the form `{ file = /path/to/secret; }` are treated as credentials:
        stripped from the generated YAML and injected via systemd LoadCredential.
      '';
    };

    scrubbed-settings = lib.mkOption {
      default = scrubbed-settings;
      description = "Internal: settings with secrets extracted (not for direct use).";
    };

    credentials = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = ''
        Credentials injected via systemd LoadCredential.
        Keys must be of the form MK_CONFIG_*_FILE.
        Populated automatically from any `{ file = ...; }` values in settings.
      '';
    };
  };

  # ── Configuration ──────────────────────────────────────────────────────────
  config = lib.mkIf myCfg.services.sharkey.enable (
    lib.mkMerge [

      # ── AGPLv3 compliance assertion ──────────────────────────────────────────
      {
        assertions = [
          (
            let
              package-is-very-likely-unmodified =
                skcfg.package.src.gitRepoUrl or null == "https://activitypub.software/TransFem-org/Sharkey.git"
                && skcfg.package.patches or [ ] == [ ];

              has-git-repo-url = skcfg.package.src.gitRepoUrl or null != null;
              has-patches = skcfg.package.patches or [ ] != [ ];

              user-probably-knows-what-they're-doing =
                skcfg.settings ? publishTarballInsteadOfProvideRepositoryUrl;
            in
            {
              assertion = package-is-very-likely-unmodified || user-probably-knows-what-they're-doing;
              message = ''
                The Sharkey setting `publishTarballInsteadOfProvideRepositoryUrl` must be explicitly set.
                Please read its documentation to avoid violating the AGPLv3 license that Sharkey is distributed under.
                https://activitypub.software/TransFem-org/Sharkey/-/blob/05a499ac55f13d654453eb3419ddae2c8eab1a34/.config/example.yml#L5-60
              ''
              + lib.optionalString (has-git-repo-url && !has-patches) ''
                note: you probably need to ensure the repository in the settings is ${skcfg.package.src.gitRepoUrl}
              '';
            }
          )
        ];
      }

      # ── Core service setup ────────────────────────────────────────────────────
      {
        services.sharkey.enable = true;

        users.users.sharkey = {
          group = "sharkey";
          isSystemUser = true;
          home = "/run/sharkey";
          packages = [ skcfg.package ];
        };
        users.groups.sharkey = { };

        services.sharkey.settings.mediaDirectory = lib.mkForce sk.mediaDir;

        systemd.services.sharkey-migrate = {
          environment.MISSKEY_CONFIG_YML = "${configFile}";
          serviceConfig = {
            Type = "oneshot";
            User = "sharkey";
            ExecStart = sharkey-migrate;
            StandardOutput = "journal";
            StandardError = "journal";
            SyslogIdentifier = "sharkey-migrate";
          };
        };

        systemd.services.sharkey = {
          requires = [ "sharkey-migrate.service" ];
          after = [
            "sharkey-migrate.service"
            "srv.mount"
          ];
          wants = [ "srv.mount" ];

          environment.MISSKEY_CONFIG_YML = "${configFile}";
          serviceConfig = {
            Type = "simple";
            User = "sharkey";
            StateDirectory = "sharkey";
            StateDirectoryMode = "0700";
            RuntimeDirectory = "sharkey";
            RuntimeDirectoryMode = "0700";
            ExecStart = sharkey-start;
            TimeoutSec = 60;
            Restart = lib.mkForce "always";
            RestartSec = myCfg.server.servicePolicy.restartSec;
            StandardOutput = "journal";
            StandardError = "journal";
            SyslogIdentifier = "sharkey";
          };
        };
      }

      # ── Credentials assertion + auto-extraction ───────────────────────────────
      {
        assertions = [
          (
            let
              badly-named-credentials = builtins.filter (env: builtins.match "^MK_CONFIG_.*_FILE$" env == null) (
                builtins.attrNames skcfg.credentials
              );
            in
            {
              assertion = badly-named-credentials == [ ];
              message = ''
                services.sharkey.credentials contains invalid environment variables: ${builtins.concatStringsSep ", " badly-named-credentials}
                They should all be of the form MK_CONFIG_*_FILE.
              '';
            }
          )
        ];

        services.sharkey.credentials = extracted-credentials;
      }

      # ── LoadCredential wiring ─────────────────────────────────────────────────
      (
        let
          credentials' = lib.imap0 (i: env: {
            identifier = "sharkey-cred-${toString i}";
            inherit env;
            path = skcfg.credentials.${env};
          }) (builtins.attrNames skcfg.credentials);

          service = {
            serviceConfig.LoadCredential = map (cred: "${cred.identifier}:${cred.path}") credentials';
            environment = lib.mkMerge (map (cred: { ${cred.env} = "%d/${cred.identifier}"; }) credentials');
          };
        in
        {
          systemd.services.sharkey-migrate = service;
          systemd.services.sharkey = service;
        }
      )

      # ── myConfig wiring ───────────────────────────────────────────────────────
      # Wire myConfig.sharkey.* values into services.sharkey.settings.
      # publishTarballInsteadOfProvideRepositoryUrl satisfies the AGPLv3 assertion
      # above; set to false to expose the upstream git repo URL instead.
      {
        services.sharkey.settings = {
          url = "https://${sk.hostname}/";
          port = sk.port;
          address = "127.0.0.1";
          id = "aidx";
          publishTarballInsteadOfProvideRepositoryUrl = false;
        };
      }

      # ── PostgreSQL ─────────────────────────────────────────────────────────────
      (lib.mkIf skcfg.database.createLocally {
        systemd.services.sharkey-migrate.bindsTo = [ "postgresql.service" ];
        systemd.services.sharkey-migrate.after = [ "postgresql.service" ];
        systemd.services.sharkey.bindsTo = [ "postgresql.service" ];
        systemd.services.sharkey.after = [ "postgresql.service" ];
        services.postgresql = {
          enable = true;
          ensureDatabases = [ "sharkey" ];
          ensureUsers = [
            {
              name = "sharkey";
              ensureDBOwnership = true;
            }
          ];
        };
        services.sharkey.settings = {
          db.host = lib.mkDefault "/run/postgresql";
          db.port = lib.mkDefault config.services.postgresql.settings.port;
          db.db = lib.mkDefault "sharkey";
          db.user = lib.mkDefault "sharkey";
        };
      })

      # ── Redis ──────────────────────────────────────────────────────────────────
      (lib.mkIf skcfg.redis.createLocally {
        services.redis.servers.sharkey.enable = true;
        systemd.services.sharkey = {
          after = [ "redis-sharkey.service" ];
          serviceConfig.SupplementaryGroups = [ config.services.redis.servers.sharkey.group ];
        };
        services.sharkey.settings = {
          redis.path = lib.mkDefault config.services.redis.servers.sharkey.unixSocket;
        };
      })

      # ── Meilisearch ────────────────────────────────────────────────────────────
      # Meilisearch master key — file must contain the raw key value only (no KEY= prefix).
      # Generate and encrypt:
      #   openssl rand -base64 32 > secrets/meilisearch-master-key
      #   SOPS_AGE_KEY_FILE=~/.config/age/keys.txt sops --encrypt --in-place \
      #     --input-type binary --output-type binary secrets/meilisearch-master-key
      (lib.mkIf skcfg.meilisearch.createLocally {
        users.users.meilisearch = {
          isSystemUser = true;
          group = "meilisearch";
        };
        users.groups.meilisearch = { };

        sops.secrets."meilisearch-master-key" = {
          sopsFile = ../../../../secrets/meilisearch-master-key;
          format = "binary";
          owner = "meilisearch";
          group = "meilisearch";
          mode = "0400";
        };

        systemd.services.sharkey.after = [ "meilisearch.service" ];
        services.meilisearch = {
          enable = true;
          listenAddress = "127.0.0.1";
          masterKeyFile = config.sops.secrets."meilisearch-master-key".path;
          settings = {
            env = lib.mkDefault "production";
            no_analytics = true;
          };
        };
        services.sharkey.settings = {
          fulltextSearch.provider = lib.mkDefault "meilisearch";
          meilisearch.host = lib.mkDefault "localhost";
          meilisearch.port = lib.mkDefault config.services.meilisearch.listenPort;
          meilisearch.index = lib.mkDefault "sharkey";
          meilisearch.apiKey = lib.mkIf (config.services.meilisearch.masterKeyFile != null) (
            lib.mkDefault { file = config.services.meilisearch.masterKeyFile; }
          );
        };
      })

      # ── createLocally convenience defaults ─────────────────────────────────────
      {
        services.sharkey.database.createLocally = lib.mkDefault true;
        services.sharkey.redis.createLocally = lib.mkDefault true;
        services.sharkey.meilisearch.createLocally = lib.mkDefault true;
      }

      # ── Media directory on /srv ────────────────────────────────────────────────
      # Must exist before Sharkey starts — the service fails with NAMESPACE (226)
      # if the path is absent.
      {
        systemd.tmpfiles.rules = [
          "d ${sk.mediaDir} 0750 sharkey sharkey -"
        ];
      }

      # ── Caddy vhost — same pattern as every other CF-tunnel service ───────────
      {
        services.caddy.virtualHosts."http://${sk.hostname}:${caddyPort}" = {
          extraConfig = ''
            handle {
              reverse_proxy http://127.0.0.1:${skPort} {
                # Cloudflare tunnel passes CF-Connecting-IP with the real client IP.
                header_up X-Forwarded-For {http.request.header.CF-Connecting-IP}
                header_up X-Real-IP      {http.request.header.CF-Connecting-IP}
              }
            }
          '';
        };
      }
    ]
  );
}
