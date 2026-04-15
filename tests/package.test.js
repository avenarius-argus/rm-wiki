const test = require("node:test");
const assert = require("node:assert/strict");

const {
  APP_ID,
  MANIFEST_ENTRY,
  PACKAGE_SOURCE_DIR,
  verifyPackageDirectory
} = require("../scripts/lib/appload");

test("AppLoad package contract matches the source package directory", () => {
  const verification = verifyPackageDirectory(PACKAGE_SOURCE_DIR);

  assert.equal(verification.ok, true, verification.problems.join("\n"));
  assert.equal(verification.manifest.id, APP_ID);
  assert.equal(verification.manifest.entry, MANIFEST_ENTRY);
});

