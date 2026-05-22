{ config, pkgs, ... }:
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

    sniffing:
      enable: true
      force-dns-mapping: true
      parse-pure-ip: true
      override-destination: true

    tun:
      enable: true
      stack: gvisor
      device: tun0
      auto-route: true
      auto-detect-interface: true
      dns-hijack: ["any:53"]
      strict-route: true

    dns:
      enable: true
      enhanced-mode: fake-ip
      fake-ip-range: 198.18.0.1/16
      default-nameserver: [223.5.5.5, 119.29.29.29]
      nameserver: [223.5.5.5, 119.29.29.29, "https://doh.pub/dns-query"]

      fake-ip-filter:
        - '+.trae.cn'
        - '+.trae.com.cn'
        - '+.bytedance.com'
        - '+.bytedance.net'
        - '+.byted.org'
        - '+.zijieapi.com'
        - '+.mchost.guru'
        - '+.bytedanceapi.com'
        - '+.volcengine.com'
        - 'api.trae.com.cn'

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

      # 强制 Trae 与字节跳动相关流量走本地网络直连
      - DOMAIN-SUFFIX,trae-cn,DIRECT
      - DOMAIN-SUFFIX,trae.com.cn,DIRECT
      - DOMAIN-SUFFIX,bytedance.com,DIRECT
      - DOMAIN-SUFFIX,bytedance.net,DIRECT
      - DOMAIN-SUFFIX,byted.org,DIRECT
      - DOMAIN-SUFFIX,zijieapi.com,DIRECT
      - DOMAIN-SUFFIX,mchost.gurn,DIRECT
      - DOMAIN-SUFFIX,bytedanceapi.com,DIRECT
      - DOMAIN-SUFFIX,volcengine.com,DIRECT

      # 1. 优先进行【域名】匹配（秒级命中，不触发后台 DNS 等待）
      - GEOSITE,private,DIRECT
      - GEOSITE,apple,DIRECT
      - GEOSITE,category-ads-all,REJECT
      - GEOSITE,cn,DIRECT

      # 2. 其次进行【IP】匹配（作为兜底）
      - GEOIP,LAN,DIRECT
      - GEOIP,CN,DIRECT

      # 3. 剩余未命中流量全部走海外代理
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
