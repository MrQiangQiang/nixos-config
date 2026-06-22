{
  config,
  pkgs,
  lib,
  ...
}:

let
  mihomoConfigTemplate = pkgs.writeText "mihomo-config-template.yaml" ''
    mixed-port: 7890
    allow-lan: true
    mode: rule
    log-level: info
    ipv6: false

    external-controller: 127.0.0.1:9090
    # mihomo RESTful API 认证 token。硬编码在 nix store 中(非真正密钥),
    # 但 external-controller 仅绑定 127.0.0.1,无远程暴露面。
    # 本地进程若能访问 localhost:9090 也能读 nix store,故此 token 仅防误访问。
    # 真正的密钥(订阅 URL)已通过 agenix + LoadCredential 安全管理。
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
        health-check: { enable: true, interval: 600, url: http://www.gstatic.com/generate_204, timeout: 5000, expected-status: 204 }

    proxy-groups:
      - { name: "全自动最优节点", type: url-test, use: [my-airport], url: http://www.gstatic.com/generate_204, interval: 300, tolerance: 50, timeout: 5000, max-failed-times: 3, expected-status: 204 }

    rules:
      # Tailscale: tailnet 流量直连，控制平面走代理
      - IP-CIDR,100.64.0.0/10,DIRECT,no-resolve
      - DST-PORT,41641,DIRECT
      - DOMAIN-SUFFIX,tailscale.com,全自动最优节点
      - DOMAIN-SUFFIX,tailscale.io,全自动最优节点

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

  # 生成含真实订阅URL的配置文件到 $RUNTIME_DIRECTORY(/run/mihomo,root:root 700)。
  # 旧实现写入 /tmp/mihomo-config.yaml(全局可读 644),任何本地用户可读取订阅URL,
  # 完全抵消 agenix 密钥管理。RuntimeDirectory 由 systemd 自动创建并设置 700 权限。
  mihomoPrestart = pkgs.writeShellScript "mihomo-prestart" ''
    ${pkgs.gnused}/bin/sed "s|__PROXY_SUBSCRIPTION_URL__|$(cat $CREDENTIALS_DIRECTORY/proxy-url)|" \
      ${mihomoConfigTemplate} > "$RUNTIME_DIRECTORY/config.yaml"
  '';
in
{
  age.secrets.proxy-subscription-url = {
    file = ../secrets/proxy-subscription-url.age;
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  services.mihomo = {
    enable = true;
    tunMode = true;
    webui = pkgs.metacubexd;
    configFile = mihomoConfigTemplate;
  };

  systemd.services.mihomo = {
    after = [
      "agenix.service"
      "time-sync.target"
    ];
    wants = [ "time-sync.target" ];
    restartTriggers = [ config.age.secrets.proxy-subscription-url.file ];
    serviceConfig = {
      RuntimeDirectory = "mihomo";
      ExecStartPre = [ mihomoPrestart ];
      # systemd 260 ExecStart 中 $VAR(无花括号)不展开,只有 ${VAR} 展开。
      # 用 $RUNTIME_DIRECTORY 会导致 -f 参数为空,mihomo 将 -ext-ui 误认为配置路径。
      ExecStart = lib.mkForce "${pkgs.mihomo}/bin/mihomo -d /var/lib/private/mihomo -f \${RUNTIME_DIRECTORY}/config.yaml -ext-ui ${config.services.mihomo.webui}";
      LoadCredential = lib.mkForce [ "proxy-url:${config.age.secrets.proxy-subscription-url.path}" ];
      AmbientCapabilities = lib.mkForce [ "CAP_NET_ADMIN" ];
      CapabilityBoundingSet = lib.mkForce [ "CAP_NET_ADMIN" ];
    };
  };

  networking.firewall = {
    trustedInterfaces = [ "tun0" ];
    checkReversePath = false;
  };
}
