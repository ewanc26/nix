let
  users = {
    ewan = "age19k8hcgcnsvs9tvr2layhxpld6ahk0uylqeqk0rzpm8j5u5v2wqkqknuf9f";
  };

  systems = {
    laptop = "age1s4exn5venvd2rkrvw9g6g9rua05quut62m6le8k79st0dryhcy3qq4n55k";
  };

  all = (builtins.attrValues users) ++ (builtins.attrValues systems);
in
{
  # Add your secrets here, e.g.:
  # "secret1.age".publicKeys = all;
}
