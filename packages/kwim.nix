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
}:

let
  pname = "kwim";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "kewuaa";
    repo = "kwim";
    rev = "v${version}";
    hash = "sha256-ewg259zRCMGq75XXMmPqoFwD5NBEFXXsIj1rvMy31uw=";
  };

  patchedSrc = stdenv.mkDerivation {
    name = "kwim-src-final";
    inherit src;
    phases = [
      "unpackPhase"
      "patchPhase"
      "installPhase"
    ];
    patchPhase = ''
      sed -i "/lazy/d" build.zig.zon
    '';
    installPhase = "cp -r . $out";
  };

  zigDeps = zig_0_16.fetchDeps {
    inherit pname version;
    src = patchedSrc;
    hash = "sha256-rOZZu/Y/rZ7who3hl1qIBHXZtRP7s4FXo0+LNnM6dYo=";
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
  ];

  postConfigure = zigPostConfigure;

  zigBuildFlags = [
    "-Doptimize=ReleaseSafe"
  ];

  meta = with lib; {
    description = "Input device manager for River Wayland compositor";
    homepage = "https://github.com/kewuaa/kwim";
    license = licenses.gpl3;
    platforms = platforms.linux;
    mainProgram = "kwim";
  };
}
