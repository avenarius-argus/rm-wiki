#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const {
  DIST_DIR,
  ICON_PATH,
  MANIFEST_PATH,
  PACKAGE_SOURCE_DIR,
  RCC_PATH,
  ensurePlaceholderRcc,
  isRccPlaceholder,
  verifyPackageDirectory,
  writeManifest
} = require("./lib/appload");

function resetDir(directory) {
  fs.rmSync(directory, { recursive: true, force: true });
  fs.mkdirSync(directory, { recursive: true });
}

writeManifest(MANIFEST_PATH);
ensurePlaceholderRcc(RCC_PATH);

resetDir(DIST_DIR);
fs.copyFileSync(MANIFEST_PATH, path.join(DIST_DIR, "manifest.json"));
fs.copyFileSync(ICON_PATH, path.join(DIST_DIR, "icon.png"));
fs.copyFileSync(RCC_PATH, path.join(DIST_DIR, "resources.rcc"));

const verification = verifyPackageDirectory(DIST_DIR);

if (!verification.ok) {
  verification.problems.forEach((problem) => {
    console.error(problem);
  });
  process.exit(1);
}

if (isRccPlaceholder(fs.readFileSync(RCC_PATH))) {
  console.warn("Packaged with a placeholder resources.rcc. Run `npm run build-rcc` before device deployment.");
}

console.log(`Packaged AppLoad directory at ${DIST_DIR}`);

