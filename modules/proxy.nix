{ config, pkgs, lib, ... }:

let
  mihomoConfigTemplate = pkgs.writeText "mihomo-config-template.yaml" ''
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
        url: __PROXY_SUBSCRIPTION_URL__
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

  mihomoPrestart = pkgs.writeShellScript "mihomo-prestart" ''
    ${pkgs.gnused}/bin/sed "s|__PROXY_SUBSCRIPTION_URL__|$(cat $CREDENTIALS_DIRECTORY/proxy-url)|" \
      ${mihomoConfigTemplate} > /tmp/mihomo-config.yaml
  '';
in {
  age.secrets.proxy-subscription-url = {
    file = ../secrets/proxy-subscription-url.age;
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  services.mihomo = {
    enable = true;
    tunMode = true;
    configFile = mihomoConfigTemplate;
  };

  systemd.services.mihomo = {
    after = [ "agenix.service" "time-sync.target" ];
    wants = [ "time-sync.target" ];
    restartTriggers = [ config.age.secrets.proxy-subscription-url.file ];
    serviceConfig = {
      ExecStartPre = [ mihomoPrestart ];
      ExecStart = lib.mkForce "${pkgs.mihomo}/bin/mihomo -d /var/lib/private/mihomo -f /tmp/mihomo-config.yaml";
      LoadCredential = lib.mkForce [ "proxy-url:${config.age.secrets.proxy-subscription-url.path}" ];
      AmbientCapabilities = lib.mkForce [ "CAP_NET_ADMIN" ];
      CapabilityBoundingSet = lib.mkForce [ "CAP_NET_ADMIN" ];
    };
  };

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
