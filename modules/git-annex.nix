{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.git-annex ];
}
