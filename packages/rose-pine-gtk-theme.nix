{
  stdenvNoCC,
  lib,
  fetchFromGitHub,
}:

# Rose Pine GTK 主题自包含打包。
# 上游 nixpkgs 在 2026-10 移除了 rose-pine-gtk-theme(依赖的 gtk-engine-murrine
# 因 GTK2 EOL 被移除)。此处仅保留主题文件复制,不引入 GTK2 引擎依赖;
# GTK2 应用会回退到默认主题但不影响功能。项目主要使用 GTK3/GTK4 应用。
stdenvNoCC.mkDerivation rec {
  pname = "rose-pine-gtk-theme";
  version = "2.2.0";
  src = fetchFromGitHub {
    owner = "rose-pine";
    repo = "gtk";
    tag = "v${version}";
    hash = "sha256-vCWs+TOVURl18EdbJr5QAHfB+JX9lYJ3TPO6IklKeFE=";
  };
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    variants=("rose-pine" "rose-pine-dawn" "rose-pine-moon")
    for n in "''${variants[@]}"; do
      mkdir -p $out/share/themes/"''${n}"/gtk-4.0
      cp -r $src/gtk3/"''${n}"-gtk/* $out/share/themes/"''${n}"/
      cp -r $src/gtk4/"''${n}".css $out/share/themes/"''${n}"/gtk-4.0/gtk.css
    done
    runHook postInstall
  '';
  meta = {
    description = "Rosé Pine theme for GTK";
    homepage = "https://github.com/rose-pine/gtk";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
