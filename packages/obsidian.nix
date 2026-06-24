# Obsidian package override — injects bootstrap.cjs into app.asar
#
# Architecture (same pattern as trae-cn.nix):
#   - nixpkgs obsidian already extracts/repacks app.asar in installPhase
#     (for corsEnabled fix). We hook postInstall to inject bootstrap.cjs.
#   - bootstrap.cjs reads darkman mode → sets nativeTheme.themeSource →
#     Obsidian's nativeTheme.on("updated") listener triggers theme switch.
#   - Disables PrefersColorSchemePortal (broken on Linux, see bootstrap.cjs).
#
# app.asar has no asarIntegrity field → safe to repack.
# This is a function: original obsidian → overridden obsidian.
# Called from default.nix overlay as: (import ./obsidian.nix) prev.obsidian
obsidian:
obsidian.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    cd $out/share/obsidian
    asar extract app.asar app-src
    cp ${./obsidian/bootstrap.cjs} app-src/bootstrap.cjs
    sed -i 's|"main": "main.js"|"main": "bootstrap.cjs"|' app-src/package.json
    rm -f app.asar
    asar pack app-src app.asar
    rm -rf app-src
  '';
})
