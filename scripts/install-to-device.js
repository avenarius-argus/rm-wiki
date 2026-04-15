#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");
const {
  APP_ID,
  DIST_DIR,
  RCC_PATH,
  isRccPlaceholder
} = require("./lib/appload");

const host = process.env.RM_HOST || "10.11.99.1";
const port = process.env.RM_PORT || "22";
const user = process.env.RM_USER || "root";
const remoteAppLoadDir = process.env.RM_APPLOAD_DIR || "/home/root/xovi/exthome/appload";
const remoteAppDir = `${remoteAppLoadDir}/${APP_ID}`;
const overwrite = process.env.RM_OVERWRITE === "1";
const remoteTarget = `${user}@${host}`;

function runOrExit(command, args) {
  const result = spawnSync(command, args, { encoding: "utf8" });

  if (result.status !== 0) {
    if (result.stdout) {
      process.stdout.write(result.stdout);
    }
    if (result.stderr) {
      process.stderr.write(result.stderr);
    }
    process.exit(result.status || 1);
  }

  return result;
}

if (!fs.existsSync(path.join(DIST_DIR, "manifest.json"))) {
  runOrExit(process.execPath, [path.join(__dirname, "package-appload.js")]);
}

if (!fs.existsSync(RCC_PATH) || isRccPlaceholder(fs.readFileSync(RCC_PATH))) {
  console.error("Refusing to install with a placeholder resources.rcc. Run `npm run build-rcc` first.");
  process.exit(1);
}

runOrExit("ssh", [
  "-p",
  port,
  remoteTarget,
  `test -d /home/root/xovi && test -d ${remoteAppLoadDir}`
]);

const existing = spawnSync("ssh", [
  "-p",
  port,
  remoteTarget,
  `test -e ${remoteAppDir}`
], { encoding: "utf8" });

if (existing.status === 0 && !overwrite) {
  console.error(`Remote app directory already exists at ${remoteAppDir}. Re-run with RM_OVERWRITE=1 to replace it.`);
  process.exit(1);
}

if (existing.status === 0 && overwrite) {
  const backupPath = `${remoteAppDir}.bak.${Date.now()}`;
  runOrExit("ssh", [
    "-p",
    port,
    remoteTarget,
    `mv ${remoteAppDir} ${backupPath}`
  ]);
}

runOrExit("scp", [
  "-P",
  port,
  "-r",
  DIST_DIR,
  `${remoteTarget}:${remoteAppLoadDir}/`
]);

console.log(`Installed ${APP_ID} to ${remoteTarget}:${remoteAppLoadDir}`);

