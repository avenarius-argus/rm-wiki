#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const {
  DIST_DIR,
  PACKAGE_SOURCE_DIR,
  RCC_PATH,
  ensurePlaceholderRcc,
  isRccPlaceholder,
  verifyPackageDirectory,
  writeManifest
} = require("./lib/appload");

const targetDir = process.argv[2] ? path.resolve(process.argv[2]) : (fs.existsSync(DIST_DIR) ? DIST_DIR : PACKAGE_SOURCE_DIR);

writeManifest(path.join(PACKAGE_SOURCE_DIR, "manifest.json"));
ensurePlaceholderRcc(RCC_PATH);

const verification = verifyPackageDirectory(targetDir);

if (!verification.ok) {
  verification.problems.forEach((problem) => {
    console.error(problem);
  });
  process.exit(1);
}

console.log(`Verified AppLoad package structure in ${targetDir}`);

if (isRccPlaceholder(fs.readFileSync(path.join(targetDir, "resources.rcc")))) {
  console.warn("resources.rcc is still the placeholder artifact.");
}

