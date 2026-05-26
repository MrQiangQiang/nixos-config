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
    secret: "local_only_secure_token_2026_auto_generated"

    sniffing:
      enable: true
      force-dns-mapping: true
      parse-pure-ip: true
      override-destination: true
      sniff:
        HTTP:
          ports: [80, 8080-8880]
          override-destination: true
        TLS:
          ports: [443, 8443]
        QUIC:
          ports: [443, 8443]

    tun:
      enable: true
      stack: mixed
      device: tun0
      auto-route: true
      auto-detect-interface: true
      dns-hijack: ["any:53", "tcp://any:53"]
      strict-route: true

    dns:
      enable: true
      enhanced-mode: redir-host
      redir-host-compatible-mode: true
      default-nameserver: [223.5.5.5, 119.29.29.29]

      nameserver:
        - 223.5.5.5
        - 119.29.29.29
        - https://doh.pub/dns-query
        - tls://dns.alidns.com

      nameserver-policy:
        "bytedance.net": https://doh.pub/dns-query
        "bytedance.com": https://doh.pub/dns-query
        "byted.org": https://doh.pub/dns-query
        "trae.com.cn": https://doh.pub/dns-query
        "mchost.guru": https://doh.pub/dns-query
        "zijieapi.com": https://doh.pub/dns-query

      fallback-filter:
        geoip: false
        geoip-code: CN

      fallback:
        - https://doh.pub/dns-query
        - tls://dns.alidns.com
        - 223.5.5.5

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

      - DOMAIN-SUFFIX,trae.com.cn,DIRECT
      - DOMAIN-SUFFIX,mchost.guru,DIRECT
      - DOMAIN-SUFFIX,bytedanceapi.com,DIRECT
      - DOMAIN-SUFFIX,volcengine.com,DIRECT
      - DOMAIN-SUFFIX,zijieapi.com,DIRECT
      - DOMAIN-SUFFIX,bytedance.net,DIRECT
      - DOMAIN-SUFFIX,bytedance.com,DIRECT
      - DOMAIN-SUFFIX,byted.org,DIRECT
      - DOMAIN-SUFFIX,tiktok-row.net,全自动最优节点

      - GEOSITE,private,DIRECT
      - GEOSITE,apple,DIRECT
      - GEOSITE,category-ads-all,REJECT
      - GEOSITE,cn,DIRECT

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

  environment.sessionVariables = {
    http_proxy = "http://127.0.0.1:7890";
    https_proxy = "http://127.0.0.1:7890";
    no_proxy = "localhost,127.0.0.1,::1";
  };

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tun0" ];
    checkReversePath = false;
  };

  networking.networkmanager.connectionConfig = {
    "connection.mdns" = 2;
  };
}
