const {app, nativeTheme} = require("electron");
const fs = require("fs");
const path = require("path");

const DARKMAN_MODE = path.join(process.env.HOME || "/tmp", ".cache/darkman/mode.txt");
const DARKMAN_DIR = path.dirname(DARKMAN_MODE);
const SETTINGS_PATH = path.join(process.env.HOME || "/tmp", ".config/Trae CN/User/settings.json");

const DARK_THEME = "@vscodeDarkTheme@";
const LIGHT_THEME = "@vscodeLightTheme@";

function readDarkmanMode() {
  try { return fs.readFileSync(DARKMAN_MODE, "utf-8").trim(); } catch(e) { return null; }
}

function writeColorTheme(themeName) {
  try {
    let data = "{}";
    try { data = fs.readFileSync(SETTINGS_PATH, "utf-8"); } catch(e) {}
    const settings = JSON.parse(data);
    if (settings["workbench.colorTheme"] === themeName) return;
    settings["workbench.colorTheme"] = themeName;
    const tmp = SETTINGS_PATH + ".tmp";
    fs.writeFileSync(tmp, JSON.stringify(settings, null, 2));
    fs.renameSync(tmp, SETTINGS_PATH);
  } catch(e) {}
}

const initialMode = readDarkmanMode();
if (initialMode) {
  nativeTheme.themeSource = initialMode === "dark" ? "dark" : "light";
  writeColorTheme(initialMode === "dark" ? DARK_THEME : LIGHT_THEME);
}

try { app.commandLine.appendSwitch("no-proxy-server"); } catch(e) {}
try { app.commandLine.appendSwitch("password-store", "basic"); } catch(e) {}
try { app.commandLine.appendSwitch("disable-features", "PrefersColorSchemePortal"); } catch(e) {}

const mainModule = require("./main.js");

if (process.env.XDG_SESSION_TYPE === "wayland" || process.env.WAYLAND_DISPLAY) {
  app.commandLine.appendSwitch("ozone-platform-hint", "auto");
  app.commandLine.appendSwitch("enable-wayland-ime");
}

let syncTimer = null;
function syncTheme() {
  clearTimeout(syncTimer);
  syncTimer = setTimeout(() => {
    const mode = readDarkmanMode();
    if (!mode) return;
    const wantDark = mode === "dark";
    const want = wantDark ? "dark" : "light";
    if (nativeTheme.themeSource !== want) {
      nativeTheme.themeSource = want;
    }
    writeColorTheme(wantDark ? DARK_THEME : LIGHT_THEME);
  }, 100);
}

nativeTheme.on("updated", () => {
  const mode = readDarkmanMode();
  if (!mode) return;
  const want = mode === "dark" ? "dark" : "light";
  if (nativeTheme.themeSource !== want) {
    nativeTheme.themeSource = want;
  }
});

app.whenReady().then(() => {
  syncTheme();
  setTimeout(syncTheme, 2000);
  setTimeout(syncTheme, 5000);
});

try {
  fs.watch(DARKMAN_DIR, (eventType, filename) => {
    if (filename === "mode.txt") syncTheme();
  });
} catch(e) {}

fs.watchFile(DARKMAN_MODE, { interval: 1000 }, (curr, prev) => {
  if (curr.mtimeMs !== prev.mtimeMs) syncTheme();
});

module.exports = mainModule;
