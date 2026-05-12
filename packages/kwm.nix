{
  lib,
  stdenv,
  fetchFromGitHub,
  zig_0_15,
  pkg-config,
  wayland,
  libxkbcommon,
  pixman,
  fcft,
  wayland-protocols,
  git,
}:

let
  pname = "kwm";
  version = "2026-05-11";
  src = fetchFromGitHub {
    owner = "kewuaa";
    repo = "kwm";
    rev = "d3d6ec2c13c830f312a79c8cb7b908964ecb5c84"; 
    hash = "sha256-UIBuOC+kAMQmKBwqmefUvz9PhSDb/TNWcNh5CxItnc8=";
  };
  
  zigDeps = zig_0_15.fetchDeps {
    inherit pname version src;
    hash = "";
#    hash = "sha256-50jjjYCr6EkRrAfkL8u4CZii7jjUahM94ka3m2cCfM0=";
  };

in
stdenv.mkDerivation {
  inherit pname version src;
 
 # zigCachePrefix = zig.fetchDeps {
 #   inherit pname version src;
 #   hash = "sha256-50jjjYCr6EkRrAfkL8u4CZii7jjUahM94ka3m2cCfM0=";
 # };

  strictDeps = true;
 
  nativeBuildInputs = [
    zig_0_15.hook
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
  
#  zigBuildFlags = [
#    "--system" "${zigDeps}" 
#  ];
  
#  preBuild = ''
#    export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache
#    mkdir -p $ZIG_GLOBAL_CACHE_DIR/p
#    if [ -d ${zigDeps}/p ]; then
#      cp -a ${zigDeps}/p/. $ZIG_GLOBAL_CACHE_DIR/p/
#    else
#      cp -a ${zigDeps}/. $ZIG_GLOBAL_CACHE_DIR/p/
#    fi
#    chmod -R +w $ZIG_GLOBAL_CACHE_DIR
#  '';
  
  preBuild = ''
    export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache
    mkdir -p $ZIG_GLOBAL_CACHE_DIR/p
    cp -a ${zigDeps}/. $ZIG_GLOBAL_CACHE_DIR/p/
    chmod -R +rw "$ZIG_GLOBAL_CACHE_DIR"
  '';

  meta = with lib; {
    description = "Window manager for River Wayland cpmpositor (zig)";
    homepage = "https://github.com/kewuaa/kwm";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
