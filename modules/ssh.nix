{ config, pkgs, ... }
{
  services.openssh = {
    enable = true;
    listenAddresses = [
      { addr = "0.0.0.0"; port = 22; }
    ];
    settings = {
      # 允许密码认证 (首次连接使用, 后续启用密钥并关闭此项)
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };
}
