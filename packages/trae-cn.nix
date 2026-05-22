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
    nativeBuildInputs = [ pkgs.dpkg ];
    unpackPhase = "dpkg-deb -x $src .";
    installPhase = ''
      mkdir -p $out/opt/Trae
      cp -r opt/Trae/* $out/opt/Trae/
     
      # 清除所有文件的特殊权限 (suid/sgid)，防止其影响 Nix 构建
      chmod -R u-s,g-s $out/opt/Trae    

      mkdir -p $out/share/pixmaps
      cp usr/share/pixmaps/trae.png $out/share/pixmaps/ || true
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
  
  targetPkgs = pkgs: with pkgs; [
    alsa-lib cairo cups dbus expat glib gtk3
    libdrm libglvnd libxkbcommon mesa nspr nss pango
    xorg.libX11 xorg.libxcb xorg.libXcomposite xorg.libXdamage
    xorg.libXext xorg.libXfixes xorg.libXrandr
    fontconfig freetype
    stdenv.cc.cc.lib zlib openssl bash coreutils curl git
  ];

  # 关闭隔离，完美融入宿主机网络与进程树
  unshareUser = false;
  unshareIpc = false;
  unshareNet = false;
  unsharePid = false;

  # 纯净环境变量: Wayland 护航与输入法标准化
  profile = ''
    export XDG_SESSION_TYPE=wayland
    unset DISPLAY
    
    export GTK_IM_MODULE=fcitx5
    export QT_IM_MODULE=fcitx5
    export XMODIFIERS=@im=fcitx
  '';

  # 原生 Wayland 启动参数，挂载 exec 接管进程
  runScript = "exec ${trae-unwrapped}/opt/Trae --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform-hint=auto --enable-wayland-ime";

  # 仅安装我们自己声明的纯净 Desktop Item，防止出现两个图标
  extraInstallCommands = ''
    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/* $out/share/applications/
  '';
}
