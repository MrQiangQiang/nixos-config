{
  lib,
  stdenv,
  fetchgit,
  pkg-config,
  zig_0_15,
  wayland,
  wayland-scanner,
  wayland-protocols,
  wlroots_0_20,
  libxkbcommon,
  libevdev,
  libinput,
  pixman,
  scdoc,
  mesa
}:

let
  pname = "river";
  version = "0.4.2";
 
  src = fetchgit {
    url = "https://codeberg.org/river/river";
    rev = "v${version}";
    hash = "sha256-Nufonz39XphxPW1lERq2acVgE5mGmW+x1yimyS6O4tc=";
    fetchSubmodules = true;
  };

  patchedSrc = stdenv.mkDerivation {
    name = "${pname}-src-final";
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
    hash = "sha256-LxOzVQC4yKPHLacoqFZSvjMSyTN7zDZIzeqITUj3VwU=";
  };
in
stdenv.mkDerivation {
  inherit pname version;

  src = patchedSrc;

  strictDeps = true;

  nativeBuildInputs = [
    zig_0_15.hook
    scdoc
    wayland-protocols
    wayland-scanner
    pkg-config
  ];
 
  buildInputs = [ 
    wayland
    wayland-protocols
    wayland-scanner
    wlroots_0_20
    libxkbcommon
    libevdev
    libinput
    pixman
    mesa
  ];

  postConfigure = ''
    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-cache"
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
  ];

  meta = with lib; {
    description = "A dynamic tiling Wayland compositor";
    homepage = "https://codeberg.org/river/river";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "river";
  };
}
