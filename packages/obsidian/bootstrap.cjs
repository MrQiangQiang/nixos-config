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
const {app, nativeTheme} = require("electron");
const fs = require("fs");
const path = require("path");

const DARKMAN_MODE = path.join(process.env.HOME || "/tmp", ".cache/darkman/mode.txt");
const DARKMAN_DIR = path.dirname(DARKMAN_MODE);
const STARTER_CSS_PATH = path.join(process.env.HOME || "/tmp", ".config/obsidian/starter.css");

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

// Apply initial mode before app ready — ensures correct theme from startup
syncTheme();

// Disable XDG Portal color-scheme (broken on Linux, signals not reliably
// delivered to Electron). Same fix as trae-cn bootstrap.
try { app.commandLine.appendSwitch("disable-features", "PrefersColorSchemePortal"); } catch(e) {}

// Starter screen theme injection.
// Listens for any webContents creation, checks if it's the starter window
// (URL contains starter.html), then fixes body class + injects Rose Pine CSS.
// dom-ready fires after DOM parse but before paint — avoids flash of wrong theme.
app.on("web-contents-created", (event, webContents) => {
  webContents.on("dom-ready", () => {
    let url;
    try { url = webContents.getURL(); } catch(e) { return; }
    if (!url || !url.includes("starter.html")) return;

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
