let
  users = {
    ewan = "age1xl8ptkqm03skrdadqgprnez3trrc0k9t0ex052lweewqre2zc9qq7ljm3z";
  };

  systems = {
    macmini = "age10ysmz3603uupz0043mpznchtnh6jsnk5cu3eg05xalma4xjacppsgupgvj";
    laptop  = "age1s4exn5venvd2rkrvw9g6g9rua05quut62m6le8k79st0dryhcy3qq4n55k";
    # Add the server key once the host exists:
    #   nix-shell -p ssh-to-age --run 'ssh-keyscan <server-ip> | ssh-to-age'
    # Then uncomment and paste the result here, and run:
    #   nix run github:yaxitech/ragenix -- --rules secrets/secrets.nix --rekey
    # server = "age1...";
  };

  all = (builtins.attrValues users) ++ (builtins.attrValues systems);

  # Until the server key is added above, PDS secrets are encrypted for ewan
  # only (so rekeying works from the macmini/laptop today).
  # After adding the server key, change this to: [ users.ewan systems.server ]
  pdsKeys = [ users.ewan ];
  matrixKeys = [ users.ewan ];
in
{
  # Network credentials
  "age/wifi-home.age".publicKeys    = all;

  # SSH key passphrases
  "age/ssh-passphrase.age".publicKeys = all;

  # PDS runtime secrets (KEY=value env file)
  "age/pds.env.age".publicKeys = pdsKeys;
  "age/duckdns.tar.gz.age".publicKeys = all;
  "age/docker-config.json.age".publicKeys = all;
  "age/claude.json.age".publicKeys = all;
  "age/matrix.env.age".publicKeys = matrixKeys;
  "age/cloudflare.token.age".publicKeys = matrixKeys;
  "age/cf-tunnel.json.age".publicKeys = matrixKeys;
}
