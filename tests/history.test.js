const test = require("node:test");
const assert = require("node:assert/strict");

const History = require("../src/js/history");

test("touchRecentSearch deduplicates and keeps the newest item first", () => {
  const items = [
    { query: "remarkable", language: "en", openedAt: 1 },
    { query: "wikipedia", language: "en", openedAt: 2 }
  ];
  const next = History.touchRecentSearch(items, { query: "remarkable", language: "en", openedAt: 3 }, 50);

  assert.equal(next.length, 2);
  assert.equal(next[0].query, "remarkable");
  assert.equal(next[0].openedAt, 3);
  assert.equal(next[1].query, "wikipedia");
});

test("touchRecentArticle respects the 50 item limit", () => {
  let items = [];
  let index;

  for (index = 0; index < 60; index += 1) {
    items = History.touchRecentArticle(items, {
      title: "Article " + index,
      canonicalTitle: "Article " + index,
      description: "",
      snippetText: "",
      language: "en",
      openedAt: index
    }, 50);
  }

  assert.equal(items.length, 50);
  assert.equal(items[0].title, "Article 59");
  assert.equal(items[49].title, "Article 10");
});

