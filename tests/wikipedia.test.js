const test = require("node:test");
const assert = require("node:assert/strict");

const searchFixture = require("./fixtures/search-response.json");
const summaryFixture = require("./fixtures/summary-response.json");
const extractFixture = require("./fixtures/extract-response.json");
const Wikipedia = require("../src/js/wikipedia");

test("normalizeSearchResults strips HTML and decodes entities", () => {
  const results = Wikipedia.normalizeSearchResults(searchFixture);

  assert.deepEqual(results, [
    {
      title: "ReMarkable",
      snippetText: "ReMarkable is a paper tablet & note-taking device.",
      canonicalTitle: "ReMarkable"
    },
    {
      title: "Wikipedia",
      snippetText: "Wikipedia is a free \"encyclopedia\" written collaboratively.",
      canonicalTitle: "Wikipedia"
    }
  ]);
});

test("normalizeArticlePayload merges summary and extract into the stable article shape", () => {
  const article = Wikipedia.normalizeArticlePayload(summaryFixture, extractFixture, "en", 1234567890, "ReMarkable");

  assert.equal(article.title, "ReMarkable");
  assert.equal(article.description, "Paper tablet");
  assert.equal(article.summaryText, "reMarkable is a paper tablet.\n\nIt supports focused reading and note-taking.");
  assert.match(article.bodyText, /This is body text\./);
  assert.equal(article.sourceUrl, "https://en.wikipedia.org/wiki/ReMarkable");
  assert.equal(article.fetchedAt, 1234567890);
  assert.equal(article.fromCache, false);
});
