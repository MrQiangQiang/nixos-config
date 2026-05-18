{
  config,
  pkgs,
  ...
}:

let
  secrets = import ../secrets.nix;

  mihomoConfig = pkgs.writeText "mihomo-config.yaml" ''
    mixed-port: 7890
    allow-lan: true
    mode: rule
    log-level: info
    ipv6: false

    tun:
      enable: true
      stack: gvisor
      auto-route: true
      dns-hijack:
        - "any:53"

    dns:
      enable: true
      enhanced-mode: fake-ip
      fake-ip-range: 198.18.0.1/16
      default-nameserver:
        - 223.5.5.5
        - 119.29.29.29
      nameserver:
        - https//doh.pub/dns-query
        
  '';
in 
{
}
  
