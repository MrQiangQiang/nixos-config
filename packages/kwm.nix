{
  lib,
  stdenv,
  fetchFromGitHub,
  zig_0_15,
  pkg-config,
  wayland,
  wayland-protocols,
  wayland-scanner,
  libxkbcommon,
  pixman,
  fcft
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
    hash = "sha256-RxaOdKCDduRBGMb1bb5cYgQ6WAfIG9tpuxiVhOmaEvE=";
  };
in
stdenv.mkDerivation {
  inherit pname version src;

  strictDeps = true;

  nativeBuildInputs = [
    zig_0_15.hook
    pkg-config
    wayland
    wayland-protocols
    wayland-scanner
  ];

  buildInputs = [
    wayland
    libxkbcommon
    pixman
    fcft
  ];

  postConfigure = ''
    ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
    export ZIG_GLOBAL_CACHE_DIR
    cp -r ${zigDeps}/. "$ZIG_GLOBAL_CACHE_DIR/p"
    chmod -R +w "$ZIG_GLOBAL_CACHE_DIR"
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

