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
    hash = "sha256-UIBuOC+kAMQmKBwqmefUvz9PhSDb/TNWcNh5CxItnc8=";
  };
  
  zigCachePrefix = zig.fetchDeps {
    inherit pname version src;
    hash = "";
  };

  strictDeps = true;
 
  nativeBuildInputs = [
    zig.hook
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

  meta = with lib; {
    description = "Window manager for River Wayland cpmpositor (zig)";
    homepage = "https://github.com/kewuaa/kwm";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
