#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");
const {
  PACKAGE_SOURCE_DIR,
  RCC_PATH,
  writeManifest
} = require("./lib/appload");

const qrcPath = path.join(__dirname, "..", "src", "resources.qrc");

function maybeAddCandidate(candidates, value) {
  if (value && !candidates.includes(value)) {
    candidates.push(value);
  }
}

function existingExecutable(filePath) {
  try {
    return fs.existsSync(filePath) ? filePath : null;
  } catch (_) {
    return null;
  }
}

function brewPrefix(formula) {
  const result = spawnSync("brew", ["--prefix", formula], { encoding: "utf8" });
  if (result.status === 0) {
    return result.stdout.trim();
  }

  return "";
}

function homeQtCandidates() {
  const candidates = [];
  const homeDir = process.env.HOME || "";
  const qtRoot = homeDir ? path.join(homeDir, "Qt") : "";
  let entries = [];

  if (!qtRoot || !fs.existsSync(qtRoot)) {
    return candidates;
  }

  try {
    entries = fs.readdirSync(qtRoot, { withFileTypes: true });
  } catch (_) {
    return candidates;
  }

  for (const entry of entries) {
    if (!entry.isDirectory()) {
      continue;
    }

    maybeAddCandidate(candidates, existingExecutable(path.join(qtRoot, entry.name, "macos", "libexec", "rcc")));
    maybeAddCandidate(candidates, existingExecutable(path.join(qtRoot, entry.name, "macos", "bin", "rcc")));
    maybeAddCandidate(candidates, existingExecutable(path.join(qtRoot, entry.name, "clang_64", "bin", "rcc")));
  }

  return candidates;
}

function findRccBinary() {
  const candidates = [];
  const envCandidate = process.env.RCC_BIN;
  const brewQt = brewPrefix("qt");
  const brewQt6 = brewPrefix("qt@6");

  maybeAddCandidate(candidates, envCandidate);
  maybeAddCandidate(candidates, "rcc");
  maybeAddCandidate(candidates, "rcc6");
  maybeAddCandidate(candidates, existingExecutable("/opt/homebrew/opt/qt/bin/rcc"));
  maybeAddCandidate(candidates, existingExecutable("/opt/homebrew/opt/qt/libexec/rcc"));
  maybeAddCandidate(candidates, existingExecutable("/opt/homebrew/opt/qt@6/bin/rcc"));
  maybeAddCandidate(candidates, brewQt ? path.join(brewQt, "bin", "rcc") : "");
  maybeAddCandidate(candidates, brewQt ? path.join(brewQt, "libexec", "rcc") : "");
  maybeAddCandidate(candidates, brewQt6 ? path.join(brewQt6, "bin", "rcc") : "");
  maybeAddCandidate(candidates, brewQt6 ? path.join(brewQt6, "libexec", "rcc") : "");
  for (const candidate of homeQtCandidates()) {
    maybeAddCandidate(candidates, candidate);
  }

  for (const candidate of candidates) {
    const check = spawnSync(candidate, ["-v"], { encoding: "utf8" });
    if (check.status === 0) {
      return candidate;
    }
  }

  return "";
}

writeManifest(path.join(PACKAGE_SOURCE_DIR, "manifest.json"));

const rccBinary = findRccBinary();

if (!rccBinary) {
  console.error("No Qt rcc binary was found. Install Qt and rerun `npm run build-rcc`.");
  process.exit(1);
}

const build = spawnSync(rccBinary, ["-binary", qrcPath, "-o", RCC_PATH], { encoding: "utf8" });

if (build.status !== 0) {
  if (build.stdout) {
    process.stdout.write(build.stdout);
  }
  if (build.stderr) {
    process.stderr.write(build.stderr);
  }
  process.exit(build.status || 1);
}

console.log(`Built ${RCC_PATH} using ${rccBinary}`);
