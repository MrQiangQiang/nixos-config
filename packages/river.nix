{
  lib,
  pkgs,
  stdenv,
  fetchgit,
  pkg-config,
  zig_0_16,
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
  version = "0.4.5";

  src = fetchgit {
    url = "https://codeberg.org/river/river";
    rev = "v${version}";
    hash = "sha256-q4JAlr9/ex+BEgktBmFwOvZzQEAGvxXPD1QyKqyha4g=";
    fetchSubmodules = true;
  };

  patchedSrc = pkgs.applyPatches {
    inherit src;
    name = "${pname}-src-patched";
    patches = [ ./river-kde-server-decoration.patch ];
    postPatch = ''
      sed -i "/lazy/d" build.zig.zon
    '';
  };

  zigDeps = zig_0_16.fetchDeps {
    inherit pname version;
    src = patchedSrc;
    hash = "sha256-Nb0iscPQV8P49vaI7hZQvSEtM/ZpXsWb7w/rpH79lTg=";
  };
in
stdenv.mkDerivation {
  inherit pname version;

  src = patchedSrc;

  strictDeps = true;

  nativeBuildInputs = [
    zig_0_16.hook
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
