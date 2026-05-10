{ config, pkgs, lib, inputs, ... }:

let
  kwnSrc = pkgs.fetchFromGithub {
    owner = "unixchad";
    repo = "kwm";
    rev = "main";
    hash = "";
  };

  kwmPackage = pkgs.stdenv.mkDerivation {
    pname = "kwm";
    version = "unstable";
    src = kwmSrc;
    nativBuildInputs = with pkgs; [ zig scdoc ];
    buildPhase = "zig build -Doptimize=ReleaseFast";
    installPhase = "
      mkdir -p $out/bin
      cp zig-out/bin/kwm $out/bin/
    ";
  };

  in {
    nixosModules.river-kwm = { config, pkgs, ... }: {
      imports = [
        inputs.home-manager.nixosModules.default
      ];

      programs.river.enable = true;
      services.dbus.enable = true;
      xdg.portal.enable = true;
      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-wlr ];

      home-manager.users."a" = { config, pkgs, lib, ... }: {
      home-stateVersion = "25.05";
          
      home.packages = with pkgs; [
        kwmPackage
	river
        rivertile
        waybar
        mako
        swaybg
        foot
        firefox
      ];

      xdg.configFile."river/init" = {
	text = "
	
	${kwmPackage}/bin/kwm &
	${pkgs.rivertile}/bin/rivertile-view-padding 6 -outer-padding 6 &
        ${pkgs.waybar}/bin/waybar &
        ${pkgs.mako}/bin/mako &

        ${pkgs.river}/bin/riverctl border-color-focused 0x93cee9
        ${pkgs.river}/bin/riverctl border-color-unfocused 0x444444
        ${pkgs.river}/bin/riverctl border-width 2
        
        ${pkgs.river}/bin/riverctl map normal Super Return spawn "${pkgs.foot}/bin/foot"
        ${pkgs.river}/bin/riverctl map normal Super+Shift Q close
        ${pkgs.river}/bin/riverctl map normal Super+Shift E exit
        ${pkgs.river}/bin/riverctl map normal Super J fouce-view next
        ${pkgs.river}/bin/riverctl map normal Super K fouce-view previous
        ${pkgs.river}/bin/riverctl map normal Super+Shift J swap next
        ${pkgs.river}/bin/riverctl map normal Super+Shift K swap previous

	for i in $(seq 1 9); do
	  tags=$((1 << ($i - 1)))
          $(pkgs.river)/bin/riverctl map normal Super $i set-focused-tags $tags
          $(pkgs.river)/bin/riverctl map normal Super+Shift $i set-view-tags $tags
        done

	${pkgs.river}/bin/riverctl map-pointer normal Super BTN_LEFT move-view
	${pkgs.river}/bin/riverctl map-pointer normal Super BTN_RIGHT resize-view
	
	${pkgs.river}/bin/riverctl rule-add -app-id "pavucontrol" float
	${pkgs.river}/bin/riverctl rule-add -app-id "org.gnome.Calculator" float
        ";
        executable = true;
      };
    };
  };
}    
