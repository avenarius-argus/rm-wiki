const fs = require("fs");
const path = require("path");

const ROOT_DIR = path.resolve(__dirname, "..", "..");
const APP_ID = "rm-wiki";
const APP_NAME = "Wikipedia";
const MANIFEST_ENTRY = "main.qml";
const RCC_PLACEHOLDER_MARKER = "RM_WIKI_RCC_PLACEHOLDER";
const PACKAGE_SOURCE_DIR = path.join(ROOT_DIR, "package", "appload");
const DIST_DIR = path.join(ROOT_DIR, "dist", APP_ID);
const ICON_PATH = path.join(PACKAGE_SOURCE_DIR, "icon.png");
const MANIFEST_PATH = path.join(PACKAGE_SOURCE_DIR, "manifest.json");
const RCC_PATH = path.join(PACKAGE_SOURCE_DIR, "resources.rcc");

function createManifest() {
  return {
    id: APP_ID,
    name: APP_NAME,
    loadsBackend: false,
    entry: MANIFEST_ENTRY,
    canHaveMultipleFrontends: false,
    supportsScaling: true
  };
}

function manifestJson() {
  return JSON.stringify(createManifest(), null, 2) + "\n";
}

function writeManifest(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, manifestJson(), "utf8");
}

function placeholderRccContents() {
  return [
    RCC_PLACEHOLDER_MARKER,
    "Qt rcc is not available on this host yet.",
    "Run `npm run build-rcc` after installing a working Qt rcc binary."
  ].join("\n") + "\n";
}

function ensurePlaceholderRcc(filePath) {
  if (!fs.existsSync(filePath)) {
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    fs.writeFileSync(filePath, placeholderRccContents(), "utf8");
  }
}

function isRccPlaceholder(value) {
  if (Buffer.isBuffer(value)) {
    return value.includes(Buffer.from(RCC_PLACEHOLDER_MARKER, "utf8"));
  }

  return String(value || "").indexOf(RCC_PLACEHOLDER_MARKER) >= 0;
}

function verifyPackageDirectory(directory) {
  const manifest = createManifest();
  const problems = [];
  const manifestPath = path.join(directory, "manifest.json");
  const iconPath = path.join(directory, "icon.png");
  const rccPath = path.join(directory, "resources.rcc");
  let parsedManifest = null;

  if (!fs.existsSync(manifestPath)) {
    problems.push("Missing manifest.json");
  } else {
    try {
      parsedManifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
    } catch (error) {
      problems.push(`manifest.json is not valid JSON: ${error.message}`);
    }
  }

  if (parsedManifest) {
    Object.keys(manifest).forEach((key) => {
      if (parsedManifest[key] !== manifest[key]) {
        problems.push(`manifest.json field ${key} expected ${JSON.stringify(manifest[key])} but found ${JSON.stringify(parsedManifest[key])}`);
      }
    });
  }

  if (!fs.existsSync(iconPath)) {
    problems.push("Missing icon.png");
  }

  if (!fs.existsSync(rccPath)) {
    problems.push("Missing resources.rcc");
  }

  return {
    ok: problems.length === 0,
    problems,
    manifest: parsedManifest,
    manifestPath,
    iconPath,
    rccPath
  };
}

module.exports = {
  APP_ID,
  APP_NAME,
  DIST_DIR,
  ICON_PATH,
  MANIFEST_ENTRY,
  MANIFEST_PATH,
  PACKAGE_SOURCE_DIR,
  RCC_PATH,
  RCC_PLACEHOLDER_MARKER,
  ROOT_DIR,
  createManifest,
  ensurePlaceholderRcc,
  isRccPlaceholder,
  manifestJson,
  placeholderRccContents,
  verifyPackageDirectory,
  writeManifest
};

