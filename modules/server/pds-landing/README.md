# pds-landing

SvelteKit app that renders the landing page at [pds.ewancroft.uk](https://pds.ewancroft.uk) using
[`@ewanc26/pds-landing`](https://github.com/ewanc26/pkgs/tree/main/packages/pds-landing).

Built with `@sveltejs/adapter-static` and served by Caddy via the NixOS configuration in `../pds.nix`.

## Development

```sh
pnpm install
pnpm dev
```

## Build

```sh
pnpm build
```

The output in `build/` is what the Nix derivation in `pkgs/packages/pds-landing/default.nix` produces
and serves at the PDS root URL.
