const test = require("node:test");
const assert = require("node:assert/strict");

const Cache = require("../src/js/cache");

test("cache entry freshness respects TTL boundaries", () => {
  const entry = Cache.createEntry({ hello: "world" }, 1_000);

  assert.equal(Cache.isFresh(entry, 500, 1_500), true);
  assert.equal(Cache.isFresh(entry, 500, 1_501), false);
});

test("markPayloadFromCache marks stale and cached state without mutating source", () => {
  const source = { title: "Example", fromCache: false };
  const marked = Cache.markPayloadFromCache(source, true);

  assert.equal(marked.fromCache, true);
  assert.equal(marked.staleCache, true);
  assert.equal(source.fromCache, false);
});

