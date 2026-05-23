{ pkgs, ... }:
let
  pname = "trae-cn";
  version = "1.107.1";

  src = pkgs.requireFile {
    name = "Trae_CN-linux-x64.deb";
    hash = "sha256-U+LxX9+M5ArWXdF5U9OD2wmwePNnXQBgJ1aCJ2gU9KE=";
    message = ''
      未找到 Trae CN 安装包
      请下载对应版本和，运行以下命令获取 SRI Hash 并导入:
      nix hash file Trae_CN-linux-x64.deb
      nix-prefetch-url file://$PWD/Trae_CN-linux-x64.deb 加入 Store.
   ''; 
  };

  # 解包衍生源
  trae-unwrapped = pkgs.stdenv.mkDerivation {
    inherit pname version src;
    unpackPhase = ''
      ar x $src
      tar xf data.tar.*
    '';
    installPhase = ''
      mkdir -p $out/opt/Trae
      mkdir -p $out/share/pixmaps
     
      # 自适应探测真实解包路径并复制核心文件
      if [ -d "usr/share/trae-cn" ]; then
        cp -a usr/share/trae-cn/. $out/opt/Trae/ || true
      fi

      if [ -d "opt/Trae" ]; then
        cp -a opt/Trae/. $out/opt/Trae/ || true
      fi
      
      if [ -d "opt/apps/com.trae.app"]; then
        cp -a opt/apps/com.trae.app/. $out/opt/Trae/ || true
      fi
      
      # 兼容执行文件的命名（处理 trae vs trae-cn）
      # 我们创建一个软链接，保证最后的 runScript 无论如何都能找到 'trae' 这个命令
      if [ -f "$out/opt/Trae/trae-cn" ] && [ ! -f "$out/opt/Trae/trae" ]; then
        ln -s $out/opt/Trae/trae-cn $out/opt/Trae/trae
      fi

      # 智能提出图标（模糊查找，无视图标路径的变化）
      find usr/share -type f -name "*.png" | grep -i trae | head -n 1 | xargs -I {} cp {} $out/share/pixmaps/trae.png || true
    '';
  };

  # 声明式桌面图标，采用绝对路径确保渲染无误
  desktopItem = pkgs.makeDesktopItem {
    name = "trae-cn";
    desktopName = "Trae CN";
    exec = "trae-cn %U";
    icon = "${trae-unwrapped}/share/pixmaps/trae.png";
    comment = "AI-powered IDE";
    categories = [ "Development" "IDE" "TextEditor" ];
    startupWMClass = "trae";
    terminal = false;
  };
in
pkgs.buildFHSEnv {
  name = "trae-cn";

  # 强制引入基础工具，确保 shell 环境完备
  targetPkgs = pkgs: with pkgs; [
    # 核心工具
    bash coreutils curl git xdg-utils
    # GUI 基础与渲染库
    alsa-lib cairo cups dbus expat glib gtk3
    libdrm libglvnd libxkbcommon mesa nspr nss pango
    libgbm libnotify libappindicator
    # X11 / Wayland 相关库（处理 libatk 问题）
    libX11 libxcb libXcomposite libXdamage
    libXext libXfixes libXrandr libxshmfence
    # 网络与安全
    gnutls libsecret libgcrypt cacert openssl
    # 这里补全了 atk 相关库
    at-spi2-atk at-spi2-core atk
    # 字体与环境
    fontconfig freetype
    stdenv.cc.cc.lib zlib
    udev
  ];

  # 关闭隔离，完美融入宿主机网络与进程树
  unshareUser = false;
  unshareIpc = false;
  unshareNet = false;
  unsharePid = false;

  # 纯净环境变量: Wayland 护航与输入法标准化
  profile = ''
    export XDG_SESSION_TYPE=wayland    
    export GTK_IM_MODULE=fcitx5
    export QT_IM_MODULE=fcitx5
    export XMODIFIERS=@im=fcitx

    # 彻底规避 Node.js 的目录扫描 Bug
    # 直接指向 NixOS 预先合并好的单一证书文件，不再让应用去扫描 /etc/ssl/certs/ 目录
    export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export NIX_SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export NODE_EXTRA_CA_CERTS="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
  '';

  runScript = "${trae-unwrapped}/opt/Trae/trae-cn \
    --enable-features=UseOzonePlatform,WaylandWindowDecorations \
    --ozone-platform-hint=auto \
    --enable-wayland-ime \
    --password-store=basic";

  # 仅安装我们自己声明的纯净 Desktop Item，防止出现两个图标
  extraInstallCommands = ''
    # 复制 Desktop 文件
    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/* $out/share/applications/
  '';
}
