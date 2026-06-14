{
  hosts = {
    laptop-1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICfFJst3nBZ06Bft8jtQo7bISsYox3eHDeCr5uTjfsk7 root@laptop-1";
    desktop-1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFYlv4fxvq7fPjWl1aA8SVpBGxAC346b2gPWhnaaNWC1 root@desktop-1";
  };
  users = {
    fugui = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJvALtc74c420xWoDLT6mwGO/Mf7JemicsoeFjFo87Ez fugui@laptop-1";
    fugui-desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF33Qo/4/LuuW9XftrsKWQbh+ABmfiwzdNW/qz7ostpq fugui@desktop-1";
    fugui-github = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKPlCRJnNW/V6jTl90yd1CMjIuorkNPJRs/dAgAbGnBx fugui@github.com";
  };
}
