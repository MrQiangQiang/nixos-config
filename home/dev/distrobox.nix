{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Pack the setup script into a standard Nix user application
  init-trae-script = pkgs.writeShellApplication {
    name = "init-trae";
    
    # Solidify host dependencies to ensure commands are found regardless of Shell PATH
    runtimeInputs = [ pkgs.distrobox ];

    text = builtins.readFile ../../scripts/init-trae.sh;
  };
in
{  
  home.packages = [
    init-trae-script
  ];
}
