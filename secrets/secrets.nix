let
  nixos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICfFJst3nBZ06Bft8jtQo7bISsYox3eHDeCr5uTjfsk7 root@nixos";
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJvALtc74c420xWoDLT6mwGO/Mf7JemicsoeFjFo87Ez fugui@nixos";
in {
  "proxy-subscription-url.age".publicKeys = [ nixos user ];
}
