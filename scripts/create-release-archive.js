#!/usr/bin/env node

const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");
const {
  APP_ID,
  DIST_DIR,
  ROOT_DIR,
  isRccPlaceholder,
  verifyPackageDirectory
} = require("./lib/appload");

const packageMetadata = require("../package.json");

const version = packageMetadata.version;
const archiveName = `${APP_ID}-${version}-appload.tar.gz`;
const checksumName = `${APP_ID}-${version}-checksums.txt`;
const releaseStagingRoot = path.join(ROOT_DIR, "dist", ".release-staging");
const releaseAppDir = path.join(releaseStagingRoot, APP_ID);
const archivePath = path.join(ROOT_DIR, "dist", archiveName);
const checksumPath = path.join(ROOT_DIR, "dist", checksumName);

function fail(message) {
  console.error(message);
  process.exit(1);
}

function copyFile(name) {
  fs.copyFileSync(path.join(DIST_DIR, name), path.join(releaseAppDir, name));
}

function digestFile(algorithm, filePath) {
  const hash = crypto.createHash(algorithm);
  hash.update(fs.readFileSync(filePath));
  return hash.digest("hex");
}

function octal(value, length) {
  return value.toString(8).padStart(length - 1, "0") + "\0";
}

function writeString(buffer, offset, length, value) {
  buffer.write(value.slice(0, length), offset, length, "utf8");
}

function tarHeader(name, options) {
  const header = Buffer.alloc(512, 0);
  const mode = options.type === "5" ? 0o755 : 0o644;

  writeString(header, 0, 100, name);
  writeString(header, 100, 8, octal(mode, 8));
  writeString(header, 108, 8, octal(0, 8));
  writeString(header, 116, 8, octal(0, 8));
  writeString(header, 124, 12, octal(options.size || 0, 12));
  writeString(header, 136, 12, octal(0, 12));
  header.fill(0x20, 148, 156);
  writeString(header, 156, 1, options.type || "0");
  writeString(header, 257, 6, "ustar");
  writeString(header, 263, 2, "00");
  writeString(header, 265, 32, "root");
  writeString(header, 297, 32, "root");

  let checksum = 0;
  for (const byte of header) {
    checksum += byte;
  }
  writeString(header, 148, 8, checksum.toString(8).padStart(6, "0") + "\0 ");

  return header;
}

function padBlock(buffer) {
  const remainder = buffer.length % 512;
  if (remainder === 0) {
    return Buffer.alloc(0);
  }

  return Buffer.alloc(512 - remainder, 0);
}

function tarEntry(name, contents, type) {
  const payload = contents || Buffer.alloc(0);
  return [
    tarHeader(name, { size: payload.length, type }),
    payload,
    padBlock(payload)
  ];
}

function createArchive(fileNames) {
  const parts = [
    ...tarEntry(`${APP_ID}/`, Buffer.alloc(0), "5")
  ];

  for (const fileName of fileNames) {
    const contents = fs.readFileSync(path.join(releaseAppDir, fileName));
    parts.push(...tarEntry(`${APP_ID}/${fileName}`, contents, "0"));
  }

  parts.push(Buffer.alloc(1024, 0));

  return zlib.gzipSync(Buffer.concat(parts), { mtime: 0, level: 9 });
}

if (!fs.existsSync(DIST_DIR)) {
  fail("Missing dist/rm-wiki. Run `npm run package-appload` before creating a release archive.");
}

const verification = verifyPackageDirectory(DIST_DIR);

if (!verification.ok) {
  verification.problems.forEach((problem) => console.error(problem));
  process.exit(1);
}

if (isRccPlaceholder(fs.readFileSync(path.join(DIST_DIR, "resources.rcc")))) {
  fail("Refusing to release a placeholder resources.rcc. Run `npm run build-rcc` and `npm run package-appload` first.");
}

fs.rmSync(releaseStagingRoot, { recursive: true, force: true });
fs.mkdirSync(releaseAppDir, { recursive: true });

const packageFiles = ["manifest.json", "icon.png", "resources.rcc"];

for (const fileName of packageFiles) {
  copyFile(fileName);
}

fs.rmSync(archivePath, { force: true });
fs.rmSync(checksumPath, { force: true });

fs.writeFileSync(archivePath, createArchive(packageFiles));

const sha256 = digestFile("sha256", archivePath);
const sha512 = digestFile("sha512", archivePath);
const checksumContents = [
  `sha256  ${sha256}  ${archiveName}`,
  `sha512  ${sha512}  ${archiveName}`
].join("\n") + "\n";

fs.writeFileSync(checksumPath, checksumContents, "utf8");

console.log(`Created ${archivePath}`);
console.log(`Created ${checksumPath}`);
console.log(`sha512=${sha512}`);
