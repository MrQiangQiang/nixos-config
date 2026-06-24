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
const {app, nativeTheme} = require("electron");
const fs = require("fs");
const path = require("path");

const DARKMAN_MODE = path.join(process.env.HOME || "/tmp", ".cache/darkman/mode.txt");
const DARKMAN_DIR = path.dirname(DARKMAN_MODE);

function readDarkmanMode() {
  try { return fs.readFileSync(DARKMAN_MODE, "utf-8").trim(); } catch(e) { return null; }
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
