{ pkgs, ... }: 

{
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    tree
  ];
}
