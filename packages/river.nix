{
  lib,
  stdenv,
  fetchFromGitHub,
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

stdenv.mkDerivation {
  pname = "river";
  version = "0.4.2";
  
  src = fetchFromGitHub {
    domain = "codeberg.org";
    owner = "river";
    repo = "river";
    rev = "v${version}";
    hash "";
  };

  strictDeps = true;

  nativeBuildInputs = [
    zig_0_16.hook
    scdoc
    wayland
    wayland-protocols
    pkg-config
    libinput
  ];
 
  buildInputs = [ 
    wayland
    wlroots_0_20
    libxkbcommon
    libevdev
    libinput
    pixman
    mesa
  ];

  meta = with lib; {
    description = "A dynamic tiling Wayland compositor";
    homepage = "https://codeberg.org/river/river";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "river";
  };
    
}
