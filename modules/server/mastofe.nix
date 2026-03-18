##############################################################################
#  masto-fe-standalone — GoToSocial's fork of the Mastodon/glitch-soc
#  frontend, served as a static site on fe.ap.ewancroft.uk.
#
#  Architecture:
#    Caddy file_server (127.0.0.1:cfg.mastofe.caddyPort)
#      ↑ Cloudflare tunnel (outbound only)
#
#  The frontend is purely client-side — it authenticates against GTS via
#  OAuth from the browser.  No backend process runs here.
#
#  Source:  https://codeberg.org/superseriousbusiness/masto-fe-standalone
#
#  First-time hash pinning:
#    Run the following to get the correct src hash:
#      nix-prefetch-git --url https://codeberg.org/superseriousbusiness/masto-fe-standalone.git \
#        --rev <commit-or-tag>
#    And for the yarn deps hash:
#      nix build .#mastofe --impure  (will fail and print the correct hash)
#    Then fill both hashes in below.
##############################################################################
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myConfig;
  mfe = cfg.mastofe;
  caddyPort = toString mfe.caddyPort;

  # ── Source derivation ──────────────────────────────────────────────────────
  # Pin to a specific commit for reproducibility.
  # Update rev + hash together when you want to pull in upstream changes.
  mastoFeSrc = pkgs.fetchFromGitea {
    domain = "codeberg.org";
    owner = "superseriousbusiness";
    repo = "masto-fe-standalone";
    # TODO: replace with the latest tag/commit from
    #   https://codeberg.org/superseriousbusiness/masto-fe-standalone/releases
    rev = "main";
    hash = lib.fakeHash;
  };

  # ── Build derivation ────────────────────────────────────────────────────────
  # masto-fe-standalone is a Yarn-based Vite project.
  # After `yarn build` the compiled assets land in dist/.
  mastoFe = pkgs.mkYarnPackage {
    name = "masto-fe-standalone";
    src = mastoFeSrc;

    # TODO: obtain with:
    #   nix-prefetch-url "$(nix eval --raw '<nixpkgs/pkgs/development/node-packages/yarn.lock')"
    # or just let Nix tell you the right value on first build.
    offlineCache = pkgs.fetchYarnDeps {
      yarnLock = "${mastoFeSrc}/yarn.lock";
      hash = lib.fakeHash;
    };

    buildPhase = ''
      export HOME=$(mktemp -d)
      yarn --offline build
    '';

    installPhase = ''
      cp -r dist $out
    '';

    # masto-fe-standalone has no server-side JS — skip the default node_modules
    # dist and just keep the compiled static assets.
    distPhase = "true";
  };
in
lib.mkIf cfg.services.mastofe.enable {

  # ── Caddy virtual host ────────────────────────────────────────────────────
  # Plain HTTP on the internal caddyPort — TLS is terminated by Cloudflare.
  services.caddy.virtualHosts."http://${mfe.hostname}:${caddyPort}" = {
    extraConfig = ''
      root * ${mastoFe}
      file_server

      # Security headers
      header {
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        Referrer-Policy "strict-origin-when-cross-origin"
        Permissions-Policy "interest-cohort=()"
      }

      # Cache static assets aggressively; HTML never cached (SPA routing).
      @assets {
        path *.js *.css *.woff2 *.woff *.ttf *.png *.svg *.ico
      }
      header @assets Cache-Control "public, max-age=31536000, immutable"
      header /index.html Cache-Control "no-store"

      encode zstd gzip
    '';
  };
}
