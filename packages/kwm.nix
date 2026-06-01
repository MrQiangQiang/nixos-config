{
  lib,
  stdenv,
  fetchFromGitHub,
  zig_0_16,
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
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "kewuaa";
    repo = "kwm";
    rev = "v${version}";
    hash = "sha256-hX76wTHPTgg5RAHILfd3CjRKPlgAwGSK3lG82IFoUUs=";
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

  zigDeps = zig_0_16.fetchDeps {
    inherit pname version;
    src = patchedSrc;
    hash = "sha256-Lz/Wcy40rxN81n/mBj4YJVbyGOolHzSFZMs93T1h0oQ=";
  };
in
stdenv.mkDerivation {
  inherit pname version;

  src = patchedSrc;

  strictDeps = true;

  nativeBuildInputs = [
    zig_0_16.hook
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
  '';

  zigBuildFlags = [
    "-Doptimize=ReleaseSafe"
    "-Dbackground=true"
  ];

  meta = with lib; {
    description = "Window manager for River Wayland compositor";
    homepage = "https://github.com/kewuaa/kwm";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
