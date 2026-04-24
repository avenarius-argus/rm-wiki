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
const password = process.env.RM_PASSWORD || "";
const remoteAppLoadDir = process.env.RM_APPLOAD_DIR || "/home/root/xovi/exthome/appload";
const remoteAppDir = `${remoteAppLoadDir}/${APP_ID}`;
const remoteBackupDir = process.env.RM_BACKUP_DIR || `/home/${user}/.appload-backups`;
const overwrite = process.env.RM_OVERWRITE === "1";
const remoteTarget = `${user}@${host}`;
const sshOptions = [
  "-o",
  "StrictHostKeyChecking=accept-new",
  "-o",
  "ConnectTimeout=15",
  "-o",
  "ServerAliveInterval=10",
  "-o",
  "ServerAliveCountMax=2"
];

function runCommand(command, args) {
  if (!password) {
    return spawnSync(command, args, { encoding: "utf8" });
  }

  function toTclLiteral(value) {
    return `{${String(value).replace(/([{}\\])/g, "\\$1")}}`;
  }

  const commandList = [command, ...args].map(toTclLiteral).join(" ");
  const expectProgram = [
    "set timeout 60",
    `set password ${toTclLiteral(password)}`,
    `set cmd [list ${commandList}]`,
    "eval spawn $cmd",
    "expect {",
    "  -re {(?i)are you sure you want to continue connecting} {",
    "    send -- \"yes\\r\"",
    "    exp_continue",
    "  }",
    "  -re {(?i)password:} {",
    "    send -- \"$password\\r\"",
    "    exp_continue",
    "  }",
    "  timeout {",
    "    close",
    "    wait",
    "    exit 124",
    "  }",
    "  eof",
    "}",
    "catch wait result",
    "set exit_status [lindex $result 3]",
    "exit $exit_status"
  ].join("\n");

  return spawnSync("expect", ["-c", expectProgram], { encoding: "utf8" });
}

function runOrExit(command, args) {
  const result = runCommand(command, args);

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
  ...sshOptions,
  "-p",
  port,
  remoteTarget,
  `test -d /home/root/xovi && test -d ${remoteAppLoadDir}`
]);

const existing = runCommand("ssh", [
  ...sshOptions,
  "-p",
  port,
  remoteTarget,
  `test -e ${remoteAppDir}`
]);

if (existing.status === 0 && !overwrite) {
  console.error(`Remote app directory already exists at ${remoteAppDir}. Re-run with RM_OVERWRITE=1 to replace it.`);
  process.exit(1);
}

if (existing.status === 0 && overwrite) {
  const backupPath = `${remoteBackupDir}/${APP_ID}.${Date.now()}`;
  runOrExit("ssh", [
    ...sshOptions,
    "-p",
    port,
    remoteTarget,
    `mkdir -p ${remoteBackupDir}`
  ]);
  runOrExit("ssh", [
    ...sshOptions,
    "-p",
    port,
    remoteTarget,
    `mv ${remoteAppDir} ${backupPath}`
  ]);
}

runOrExit("scp", [
  ...sshOptions,
  "-P",
  port,
  "-r",
  DIST_DIR,
  `${remoteTarget}:${remoteAppLoadDir}/`
]);

console.log(`Installed ${APP_ID} to ${remoteTarget}:${remoteAppLoadDir}`);
