{ pkgs, lib, ... }:
let
  pname = "trae-cn";
  version = "2.3.30127";

  src = pkgs.fetchurl {
    url = "https://lf-cdn.trae.com.cn/obj/trae-com-cn/pkg/app/releases/stable/${version}/linux/Trae_CN-linux-x64.tar.gz";
    hash = "sha256-0qDhrItGwInu1qotBG30cSyBZltzW1PtzRtQtH0sf98=";
  };

  runtimeLibs = with pkgs; [
    alsa-lib at-spi2-atk at-spi2-core atk
    cairo cups dbus expat fontconfig freetype
    glib gnutls gtk3
    libdrm libgcrypt libgbm libglvnd libnotify libsecret
    libX11 libXcomposite libXdamage libXext libXfixes libXrandr
    libxkbcommon libxkbfile libxcb
    mesa nspr nss
    openssl openssl_1_1_unsecure
    pango stdenv.cc.cc.lib udev xz zeromq zlib
  ];

  trae-unwrapped = pkgs.stdenv.mkDerivation {
    inherit pname version src;

    unpackPhase = ''
      runHook preUnpack
      mkdir -p $out/opt/Trae
      tar xzf $src -C $out/opt/Trae
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      rm -f $out/opt/Trae/resources/app/modules/ckg/binary/libstdc++.so.6

      find $out/opt/Trae -type f \( -iname "*trae*.png" -o -iname "*trae*.svg" \) | head -n 1 | xargs -I {} install -Dm644 {} $out/share/pixmaps/trae.png 2>/dev/null || true

      chmod u+w $out/opt/Trae/resources/app/out/main.js
      sed -i 's/should_use_ttnet:!0/should_use_ttnet:!1/g' $out/opt/Trae/resources/app/out/main.js
      sed -i 's/domain_white_list:{[^}]*\["\*"\][^}]*}/domain_white_list:{}/g' $out/opt/Trae/resources/app/out/main.js

      cat > $out/opt/Trae/resources/app/out/trae-bootstrap.cjs << 'BOOTSTRAP_EOF'
const {app} = require("electron");
try { app.commandLine.appendSwitch("no-proxy-server"); } catch(e) {}
module.exports = require("./main.js");
BOOTSTRAP_EOF

      chmod u+w $out/opt/Trae/resources/app/package.json
      sed -i 's|"main": "./out/main.js"|"main": "./out/trae-bootstrap.cjs"|' $out/opt/Trae/resources/app/package.json
      runHook postInstall
    '';
  };

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

  targetPkgs = pkgs: runtimeLibs ++ (with pkgs; [
    bash coreutils curl git
    cacert iana-etc xdg-utils
  ]);

  unshareUser = false;
  unshareIpc  = false;
  unshareNet  = false;
  unsharePid  = false;
  dieWithParent = false;

  profile = ''
    export XDG_SESSION_TYPE="''${XDG_SESSION_TYPE:-wayland}"
    export GTK_IM_MODULE=fcitx5
    export QT_IM_MODULE=fcitx5
    export XMODIFIERS=@im=fcitx
    export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export NIX_SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export NODE_EXTRA_CA_CERTS="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export NIX_ETC_PROTOCOLS="${pkgs.iana-etc}/etc/protocols"
    export NIX_ETC_SERVICES="${pkgs.iana-etc}/etc/services"
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY no_proxy NO_PROXY
  '';

  runScript = pkgs.writeScript "trae-cn-runner" ''
    #!${pkgs.bash}/bin/bash
    printf 'nameserver 223.5.5.5\nnameserver 119.29.29.29\noptions edns0\n' > /etc/resolv.conf 2>/dev/null || true
    exec ${trae-unwrapped}/opt/Trae/bin/trae-cn \
      --enable-features=UseOzonePlatform,WaylandWindowDecorations \
      --ozone-platform-hint=auto \
      --enable-wayland-ime \
      --password-store=basic \
      "$@"
  '';

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/* $out/share/applications/
    sed -i "s|^Exec=.*|Exec=$out/bin/trae-cn %U|" $out/share/applications/*.desktop
  '';

  meta = with lib; {
    description = "Trae CN - AI-powered IDE (Chinese edition)";
    homepage = "https://www.trae.com.cn/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
