let
  users = {
    ewan = "age1xl8ptkqm03skrdadqgprnez3trrc0k9t0ex052lweewqre2zc9qq7ljm3z";
  };

  systems = {
    macmini = "age10ysmz3603uupz0043mpznchtnh6jsnk5cu3eg05xalma4xjacppsgupgvj";
    laptop = "age1s4exn5venvd2rkrvw9g6g9rua05quut62m6le8k79st0dryhcy3qq4n55k";
  };

  all = (builtins.attrValues users) ++ (builtins.attrValues systems);
in
{
  # Add your actual secrets here
  # UI preferences are NOT secrets and should not be encrypted
  
  # Network Credentials (REAL secrets)
  "age/wifi-home.age".publicKeys = all;
  
  # SSH Key Passphrases
  "age/ssh-passphrase.age".publicKeys = all;
 
  # Examples of what SHOULD be encrypted:
  # "api-keys.age".publicKeys = all;
  # "passwords.age".publicKeys = all;
}
