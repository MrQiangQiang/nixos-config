let
  keys = import ./keys.nix;
in
{
  "proxy-subscription-url.age".publicKeys = [
    keys.hosts.laptop-1
    keys.hosts.desktop-1
    keys.users.fugui
  ];
  "opencode-go-key.age".publicKeys = [
    keys.hosts.laptop-1
    keys.hosts.desktop-1
    keys.users.fugui
  ];
}
