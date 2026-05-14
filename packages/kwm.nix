{
  lib,
  stdenv,
  fetchFromGitHub,
  zig_0_15,
  pkg-config,
  wayland,
  wayland-scanner,
  wayland-protocols,
  libxkbcommon,
  pixman,
  fcft,
  libevdev
}:

let
  pname = "kwm";
  version = "2026-05-11";

  src = fetchFromGitHub {
    owner = "kewuaa";
    repo = "kwm";
    rev = "d3d6ec2c13c830f312a79c8cb7b908964ecb5c84";
    hash = "sha256-UIBuOC+kAMQmKBwqmefUvz9PhSDb/TNWcNh5CxItnc8=";
  }; 

  zigDeps = zig_0_15.fetchDeps {
    inherit pname version src;
#    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; 
#    hash = "sha256-RxaOdKCDduRBGMb1bb5cYgQ6WAfIG9tpuxiVhOmaEvE=";
    hash = lib.fakeHash;
  };
in
stdenv.mkDerivation {
  inherit pname version src;

  strictDeps = true;

#  depsBuildBuild = [
#    pkg-config
#    wayland-scanner
#  ];

  nativeBuildInputs = [
    zig_0_15.hook
    wayland-protocols
    wayland-scanner
    pkg-config 
  ];

  buildInputs = [
    wayland
    libxkbcommon
    pixman
    fcft
    libevdev
  ];

  postConfigure = ''
    export PKG_CONFIG_PATH="${
      lib.makeSearchPath "lib/pkgconfig" [
        wayland-scanner
        wayland
        libxkbcommon
        libevdev
        pixman
        fcft
      ]
    }:${wayland-protocols}/share/pkgconfig''${PKG_CONFIG_PATH:+:}$PKG_CONFIG_PATH"
    export ZIG_GLOBAL_CHACHE_DIR=$TMPDIR/zig-cache
    mkdir -p "$ZIG_GLOBAL_CACHE_DIR"
    cp -rn ${zigDeps}/* "$ZIG_GLOBAL_CACHE_DIR/"
    chmod -R u+w "$ZIG_GLOBAL_CACHE_DIR"
#    export ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
#    mkdir -p $ZIG_GLOBAL_CACHE_DIR/p
#    cp -r ${zigDeps}/* "$ZIG_GLOBAL_CACHE_DIR/p"
#    chmod -R u+w "$ZIG_GLOBAL_CACHE_DIR"
  '';
  
#  preBuild = ''
#    if [ -n "$deps" ]; then
#      zigBuildFlagsArray+=("--system" "$deps")
#    fi
#  '';

  zigBuildFlags = [
    "-Doptimize=ReleaseSafe"
  ];

  meta = with lib; {
    description = "window manager for River Wayland cpmpositor (zig)";
    homepage = "https://github.com/kewuaa/kwm";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}

