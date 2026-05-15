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
    rev = "master";  
    hash = "sha256-NyKFSlIpb2m2kQRBJ/4+koJpIaRjbs5hRPJZ34KGJrc=";
  };

  patchedSrc = stdenv.mkDerivation {
    name = "kwm-src-final";
    inherit src;
    phases = [ "unpackPhase" "patchPhase" "installPhase" ];
    patchPhase = ''
      sed -i "/lazy/d" build.zig.zon
    '';
    installPhase = "cp -r . $out"; 
  }; 

  zigDeps = zig_0_15.fetchDeps {
    inherit pname version;
    src = patchedSrc;
    hash = "sha256-cCe9Fy0snuyHFU5H3qMTK1Cpzl1KJDdO8q1MW+mzu1s=";
  };
in
stdenv.mkDerivation {
  inherit pname version;

  src = patchedSrc;
    
  strictDeps = true;

  nativeBuildInputs = [
    zig_0_15.hook
    wayland-protocols
    wayland-scanner
    pkg-config 
  ];

  buildInputs = [
    wayland
    wayland-protocols
    wayland-scanner
    libxkbcommon
    pixman
    fcft
    libevdev
  ];

  postConfigure = ''
    export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache
    mkdir -p "$ZIG_GLOBAL_CACHE_DIR"

    if [ -d "${zigDeps}/p" ]; then
      cp -af "${zigDeps}/." "$ZIG_GLOBAL_CACHE_DIR/"
    else
      mkdir -p "$ZIG_GLOBAL_CACHE_DIR/p"
      cp -af "${zigDeps}/." "$ZIG_GLOBAL_CACHE_DIR/p/"
    fi

    chmod -R u+w "$ZIG_GLOBAL_CACHE_DIR"
    echo "--- Current PKG_CONFIG_PATH: $PKG_CONFIG_PATH"
  '';
  
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

