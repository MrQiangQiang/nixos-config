{
  lib,
  stdenv,
  zig_0_15,
  pkg-config,
  wayland,
  libxkbcommon,
  pixman,
  fcft,
  wayland-protocols,
  git,
  src,
}:

stdenv.mkDerivation {
  pname = "kwm";
  version = "2026-05-11";

  inherit src;

  strictDeps = true;
 
  nativeBuildInputs = [
    zig_0_15
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
    platforms = platforms.linus;   
  };
}
