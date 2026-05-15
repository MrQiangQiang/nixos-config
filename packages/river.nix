{
  lib,
  stdenv,
  fetchgit,
  pkg-config,
  zig_0_16,
  wayland,
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
  
  zigDeps = zig_0_16.fetchDeps {
    inherit pname version src;
    hash = "sha256-17qCdlDdfnHirNu3kNnQRlvRL/ifPhQiYk1IfR7lVSw=";
  };
in
stdenv.mkDerivation {
  inherit pname version src;

  strictDeps = true;

  nativeBuildInputs = [
    zig_0_16.hook
    scdoc
    wayland
    pkg-config
  ];
 
  buildInputs = [ 
    wayland
    wayland-protocols
    wlroots_0_20
    libxkbcommon
    libevdev
    libinput
    pixman
    mesa
  ];

  postConfigure = ''
    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-cache"
    mkdir -p "$ZIG_GLOBAL_CACHE_DIR/p"
    if [ -d "${zigDeps}" ]; then
      cp -pr "${zigDeps}/." "$ZIG_gLOBAL_CACHE_DIR/p"
      chamod -R u+w "$ZIG_GLOBAL_CACHE_DIR"
    fi
  '';

  zigBuildFlahs = [
    "-Doptimize=ReleaseSafe"
    "-Dpie=true"
  ];

  meta = with lib; {
    description = "A dynamic tiling Wayland compositor";
    homepage = "https://codeberg.org/river/river";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "river";
  };
}
