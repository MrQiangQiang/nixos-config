{
  lib,
  stdenv,
  fetchFromGitHub,
  zig-overlay,
  pkg-config,
  wayland,
  libxkbcommon,
  pixman,
  fcft,
  wayland-protocols,
  git,
}:

let
  zig = zig-overlay.packages.${stdenv.hostPlatform.system}.default;

  src = fetchFromGitHub {
    owner = "kewuaa";
    repo = "kwm";
    rev = "d3d6ec2c13c830f312a79c8cb7b908964ecb5c84"; 
    hash = "sha256-UIBuOC+kAMQmKBwqmefUvz9PhSDb/TNWcNh5CxItnc8=";
  };

  deps = zig.fetchDeps {
    inherit src;
    name = "kwm-zig-deps";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
in
stdenv.mkDerivation {
  inherit src;  
  pname = "kwm";
  version = "2026-05-11";

  strictDeps = true;
 
  nativeBuildInputs = [
    zig
    pkg-config
    wayland-protocols
    git
  ];

  buildInputs = [
    wayland
    libxkbcommon
    pixman
    fcft
  ];

  preBuild = ''
    export HOME=$TMPDIR
  '';

  buildPhase = ''
    mkdir -p $HOME/.cache/zig
    cp -r ${deps}/* $HOME/.cache/zig/
    zig build -Doptimize=ReleaseSafe --prefix $out
  '';

  installPhase = ''
    zig build install --perfix $out
  '';

  meta = with lib; {
    description = "Window manager for River Wayland cpmpositor (zig)";
    homepage = "https://github.com/kewuaa/kwm";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
