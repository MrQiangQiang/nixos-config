{
  lib,
  stdenv,
  fetchFromGitHub,
  zig,
  pkg-config,
  wayland,
  libxkbcommon,
  pixman,
  fcft,
  wayland-protocols,
  git,
}:

stdenv.mkDerivation {
  pname = "kwm";
  version = "2026-05-11";

  src = fetchFromGitHub {
    owner = "kewuaa";
    repo = "kwm";
    rev = "d3d6ec2c13c830f312a79c8cb7b908964ecb5c84"; 
    hash = "sha256-U1BuQC+kAMOmKBwqmefUvz9PhSDb/TNwcNh5Cxltnc8=";
  };

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
