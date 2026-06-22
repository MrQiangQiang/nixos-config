{
  lib,
  pkgs,
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
  libevdev,
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

  patchedSrc = pkgs.applyPatches {
    inherit src;
    name = "${pname}-src-patched";
    patches = [ ./kwm/sigusr1-reload.patch ];
    postPatch = ''
      sed -i "/lazy/d" build.zig.zon
    '';
  };

  zigDeps = zig_0_16.fetchDeps {
    inherit pname version;
    src = patchedSrc;
    hash = "sha256-Lz/Wcy40rxN81n/mBj4YJVbyGOolHzSFZMs93T1h0oQ=";
  };

  zigPostConfigure = import ./zig-post-configure.nix zigDeps;
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

  postConfigure = zigPostConfigure;

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
