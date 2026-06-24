// Obsidian bootstrap — bridges darkman → nativeTheme → Obsidian's theme switcher
//
// Problem: On Linux, XDG Portal color-scheme signals are not reliably delivered
// to Electron (confirmed v1.12.4, Mar 2026). Obsidian has nativeTheme.on("updated")
// and matchMedia listeners, but they never fire because the portal signal is lost.
//
// Solution (same pattern as trae-cn bootstrap):
//   1. Read darkman mode → set nativeTheme.themeSource directly
//   2. Disable PrefersColorSchemePortal (broken on Linux)
//   3. Watch darkman mode file → update themeSource on change
//   4. Obsidian's own nativeTheme.on("updated") listener handles the rest
//      (calls updateTheme() which toggles .theme-dark/.theme-light on body)
//
// Starter screen fix (vault switcher + version info modal):
//   starter.html hardcodes <body class="theme-dark"> and only loads app.css —
//   vault-level theme.css/snippets are NOT loaded. We inject Rose Pine CSS
//   via webContents.insertCSS() and fix body class based on darkman mode.
//   CSS file is deployed by home-manager to ~/.config/obsidian/starter.css.
//
// Sandbox vault theme deployment:
//   The sandbox vault (~/.config/obsidian/Obsidian Sandbox/) is created on-demand
//   by Obsidian (Help → Sandbox vault). Obsidian's p() function DELETES and
//   RECREATES the directory from template if it's not in obsidian.json. This
//   creates a timing problem for home-manager activation scripts (sandbox may
//   not exist at switch time). We solve this by deploying theme files on every
//   startup — robust against sandbox recreation.
//   Theme files are deployed by home-manager to ~/.config/obsidian/rose-pine/
//   (declarative via xdg.configFile) and copied to the sandbox vault here.
const {app, nativeTheme} = require("electron");
const fs = require("fs");
const path = require("path");

const HOME = process.env.HOME || "/tmp";
const DARKMAN_MODE = path.join(HOME, ".cache/darkman/mode.txt");
const DARKMAN_DIR = path.dirname(DARKMAN_MODE);
const STARTER_CSS_PATH = path.join(HOME, ".config/obsidian/starter.css");
const ROSE_PINE_DIR = path.join(HOME, ".config/obsidian/rose-pine");
const SANDBOX_VAULT_DIR = path.join(HOME, ".config/obsidian/Obsidian Sandbox");

function readDarkmanMode() {
  try { return fs.readFileSync(DARKMAN_MODE, "utf-8").trim(); } catch(e) { return null; }
}

function readStarterCSS() {
  try { return fs.readFileSync(STARTER_CSS_PATH, "utf-8"); } catch(e) { return null; }
}

function syncTheme() {
  const mode = readDarkmanMode();
  if (!mode) return;
  const want = mode === "dark" ? "dark" : "light";
  if (nativeTheme.themeSource !== want) {
    nativeTheme.themeSource = want;
  }
}

// Copy a file from src to dest, handling two Nix-specific issues:
//   1. Source is a symlink to Nix store — copyFileSync may copy the symlink
//      itself instead of following it. readFileSync follows symlinks.
//   2. Previous copyFileSync may have preserved Nix store's 444 (read-only)
//      permissions on the destination, causing EACCES on overwrite.
//      rmSync(force) removes any stale read-only file; writeFileSync creates
//      a fresh file with default 644 permissions.
function copyThemeFile(src, dest) {
  fs.rmSync(dest, {force: true});
  fs.writeFileSync(dest, fs.readFileSync(src));
}

// Deploy Rose Pine theme to the sandbox vault on every startup.
// The sandbox vault is created on-demand by Obsidian; if it doesn't exist yet,
// skip (next startup after creation will deploy). Theme files are copied from
// the stable location (~/.config/obsidian/rose-pine/, deployed by home-manager).
function deploySandboxTheme() {
  try {
    // Sandbox vault may not exist yet (created on-demand by Obsidian)
    if (!fs.existsSync(SANDBOX_VAULT_DIR)) return;
    // Stable theme files may not exist yet (home-manager not switched)
    if (!fs.existsSync(ROSE_PINE_DIR)) return;

    // Deploy official Rose Pine theme (manifest.json + theme.css)
    const themeDir = path.join(SANDBOX_VAULT_DIR, ".obsidian/themes/Rose Pine");
    fs.mkdirSync(themeDir, {recursive: true});
    copyThemeFile(path.join(ROSE_PINE_DIR, "manifest.json"), path.join(themeDir, "manifest.json"));
    copyThemeFile(path.join(ROSE_PINE_DIR, "theme.css"), path.join(themeDir, "theme.css"));

    // Deploy CSS snippet (palette.nix colors via replaceVars)
    const snippetDir = path.join(SANDBOX_VAULT_DIR, ".obsidian/snippets");
    fs.mkdirSync(snippetDir, {recursive: true});
    copyThemeFile(path.join(ROSE_PINE_DIR, "snippet.css"), path.join(snippetDir, "rose-pine-obsidian.css"));

    // Write appearance.json (merge with existing to preserve user customizations)
    const appearancePath = path.join(SANDBOX_VAULT_DIR, ".obsidian/appearance.json");
    fs.mkdirSync(path.dirname(appearancePath), {recursive: true});
    let appearance = {};
    try { appearance = JSON.parse(fs.readFileSync(appearancePath, "utf-8")); } catch(e) {}
    appearance.theme = "system";
    appearance.cssTheme = "Rose Pine";
    appearance.enabledCssSnippets = ["rose-pine-obsidian", ...(appearance.enabledCssSnippets || [])]
      .filter((v, i, a) => a.indexOf(v) === i);
    fs.writeFileSync(appearancePath, JSON.stringify(appearance));
  } catch(e) {
    // Never crash Obsidian — theme deployment is best-effort
    console.error("deploySandboxTheme failed:", e);
  }
}

// Apply initial mode before app ready — ensures correct theme from startup
syncTheme();

// Deploy sandbox vault theme before app ready — ensures theme files exist
// before Obsidian's main.js opens the sandbox vault window.
deploySandboxTheme();

// Disable XDG Portal color-scheme (broken on Linux, signals not reliably
// delivered to Electron). Same fix as trae-cn bootstrap.
try { app.commandLine.appendSwitch("disable-features", "PrefersColorSchemePortal"); } catch(e) {}

// Starter screen theme injection.
// Listens for any webContents creation, checks if it's a starter/help window
// (URL contains starter.html or help.html — both hardcode <body class="theme-dark">
// and only load app.css, no vault-level theme.css/snippets). Fixes body class
// + injects Rose Pine CSS. dom-ready fires after DOM parse but before paint.
app.on("web-contents-created", (event, webContents) => {
  webContents.on("dom-ready", () => {
    let url;
    try { url = webContents.getURL(); } catch(e) { return; }
    if (!url || (!url.includes("starter.html") && !url.includes("help.html"))) return;

    const mode = readDarkmanMode();
    if (!mode) return;

    // Fix body class — starter.html hardcodes theme-dark, but system may be light
    const themeClass = mode === "dark" ? "theme-dark" : "theme-light";
    webContents.executeJavaScript(
      `document.body.classList.remove("theme-dark","theme-light");` +
      `document.body.classList.add("${themeClass}");`
    ).catch(() => {});

    // Inject Rose Pine CSS (covers --color-base-* + --accent-h/s/l)
    const css = readStarterCSS();
    if (css) {
      webContents.insertCSS(css, { cssOrigin: "author" }).catch(() => {});
    }
  });
});

// Load the original Obsidian main.js
require("./main.js");

// Safety net: if nativeTheme changes from any source, re-assert darkman mode
nativeTheme.on("updated", () => {
  const mode = readDarkmanMode();
  if (!mode) return;
  const want = mode === "dark" ? "dark" : "light";
  if (nativeTheme.themeSource !== want) {
    nativeTheme.themeSource = want;
  }
});

// Watch darkman mode file for changes (fs.watch = responsive, fs.watchFile = fallback)
try {
  fs.watch(DARKMAN_DIR, (eventType, filename) => {
    if (filename === "mode.txt") syncTheme();
  });
} catch(e) {}

fs.watchFile(DARKMAN_MODE, { interval: 1000 }, (curr, prev) => {
  if (curr.mtimeMs !== prev.mtimeMs) syncTheme();
});
