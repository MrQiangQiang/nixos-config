{ pkgs, lib, vscodeDarkTheme ? "Rosé Pine", vscodeLightTheme ? "Rosé Pine Dawn", ... }:
let
  pname = "trae-cn";
  version = "2.3.38425";

  src = pkgs.fetchurl {
    url = "https://lf-cdn.trae.com.cn/obj/trae-com-cn/pkg/app/releases/stable/${version}/linux/Trae_CN-linux-x64.tar.gz";
    hash = "sha256-2Upp9g8FaAkK4nI4X1nh5WO00vTz2fyblcUPot2Yk10=";
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

  traeBootstrap = pkgs.replaceVars ./trae-cn/bootstrap.cjs {
    inherit vscodeDarkTheme vscodeLightTheme;
  };

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

      install -Dm644 $out/opt/Trae/resources/app/resources/linux/code.png $out/share/pixmaps/trae.png

      chmod u+w $out/opt/Trae/resources/app/out/main.js
      sed -i 's/should_use_ttnet:!0/should_use_ttnet:!1/g' $out/opt/Trae/resources/app/out/main.js
      sed -i 's/domain_white_list:{[^}]*\["\*"\][^}]*}/domain_white_list:{}/g' $out/opt/Trae/resources/app/out/main.js

      install -Dm644 ${traeBootstrap} $out/opt/Trae/resources/app/out/trae-bootstrap.cjs

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
    if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
      export XDG_SESSION_TYPE=wayland
    fi
    export XDG_CURRENT_DESKTOP="''${XDG_CURRENT_DESKTOP:-river}"
    export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
    export GTK_IM_MODULE=fcitx
    export QT_IM_MODULE=fcitx
    export XMODIFIERS=@im=fcitx
    export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export NIX_SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export NODE_EXTRA_CA_CERTS="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export NIX_ETC_PROTOCOLS="${pkgs.iana-etc}/etc/protocols"
    export NIX_ETC_SERVICES="${pkgs.iana-etc}/etc/services"
    export GSETTINGS_SCHEMA_DIR="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/gsettings-desktop-schemas-${pkgs.gsettings-desktop-schemas.version}/glib-2.0/schemas"
    export PAGER=cat
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY no_proxy NO_PROXY
  '';

  runScript = pkgs.writeScript "trae-cn-runner" ''
    #!${pkgs.bash}/bin/bash
    ( printf 'nameserver 223.5.5.5\nnameserver 119.29.29.29\noptions edns0\n' > /etc/resolv.conf ) 2>/dev/null || true
    exec ${trae-unwrapped}/opt/Trae/bin/trae-cn "$@"
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
