let
  users = {
    ewan = "age1xl8ptkqm03skrdadqgprnez3trrc0k9t0ex052lweewqre2zc9qq7ljm3z";
  };

  systems = {
    MacMini = "age10ysmz3603uupz0043mpznchtnh6jsnk5cu3eg05xalma4xjacppsgupgvj";
    laptop = "age1s4exn5venvd2rkrvw9g6g9rua05quut62m6le8k79st0dryhcy3qq4n55k";
  };

  all = (builtins.attrValues users) ++ (builtins.attrValues systems);
in
{
  # Add your secrets here, e.g.:
  # "secret1.age".publicKeys = all;

  # Desktop Environment Settings Exports
  "darwin-defaults-settings.age".publicKeys = all;
  "gnome-dconf-settings.age".publicKeys = all;

  # Network Credentials
  "wifi-home.age".publicKeys = all;
}
