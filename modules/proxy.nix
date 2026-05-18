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

    external-controller: 127.0.0.1:9090
    secret: "local_only_secure_token_2026_atuo_generated"

    tun:
      enable: true
      stack: gvisor
      device: tun0
      auto-route: true
      auto-detect-interface: true
      dns-hijack: ["any:53"]

    dns:
      enable: true
      enhanced-mode: fake-ip
      fake-ip-range: 198.18.0.1/16
      default-nameserver: [223.5.5.5, 119.29.29.29]
      nameserver: ["https//doh.pub/dns-query"]
      
    proxy-providers:
      my-airport:
        type: http
        url: ${secrets.proxy.subscriptionUrl}
        lazy: true
        interval: 86400
        path: airport-cache.yaml
        health-check: { enable: true, interval: 600, url: http://www.gstatic.com/generate_204 }

    proxy-groups:
      - { name: "全自动最优节点", type: url-test, use: [my-airport], url: http://www.gstatic.com/generate_204, interval: 300, tolerance: 50 }

    rules:
      - DOMAIN-SUFFIX,bigairport-twentieth-sub.com,DIRECT
      - GEOIP,LAN,DIRECT
      - GEOIP,CN,DIRECT
      - MATCH,全自动最优节点    
  '';
in {
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  services.mihomo = {
    enable = true;
    tunMode = true;
    configFile = mihomoConfig;
  };

  systemd.services.mihomo.serviceConfig = {
    StateDirectory = "mihomo";
    StateDirectoryMode = "0750";
    AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
    CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
  };

  systemd.services.nix-daemon.serviceConfig.Environment = [
    "http_proxy=http://127.0.0.1:7890"
    "https_proxy=http://127.0.0.1:7890"
  ];

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tun0" ];
    checkReversePath = false;
  };

  networking.networkmanager.connectionConfig = {
    "connection.mdns" = 2;
  };
}
