{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    curl
    tree
    wget
  ];
}
