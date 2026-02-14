{ config, lib, pkgs, ... }:

let
  cfg      = import ../settings/config.nix;
  ageDir   = ../secrets/age;

  # Build one age.secrets entry per file listed in settings/config/secrets.nix.
  # Each entry decrypts to /run/agenix/<name> at runtime.
  mkSecretEntry = name: lib.nameValuePair name {
    file = "${ageDir}/${name}.age";
    mode = "0440";
  };
in
{
  age.secrets = lib.listToAttrs (map mkSecretEntry cfg.secrets.files);

  # ─── How to use secrets in your config ───────────────────────────────────────
  #
  # Reference a decrypted file path:
  #   config.age.secrets.<name>.path
  #
  # Service password file:
  #   services.someService.passwordFile = config.age.secrets.my-password.path;
  #
  # Environment variable:
  #   systemd.services.myservice.environment.TOKEN_FILE =
  #     config.age.secrets.api-token.path;
  #
  # Shell script:
  #   script = ''
  #     TOKEN=$(cat ${config.age.secrets.api-token.path})
  #   '';
  #
  # Adding a new secret:
  #   1. Create it: rage -e -r "$(cat ~/.ssh/id_ed25519.pub)" secret.txt > secrets/age/my-secret.age
  #   2. Add the filename (without .age) to settings/config/secrets.nix → files list
  #   3. Rebuild — it will appear at config.age.secrets.my-secret.path
}
