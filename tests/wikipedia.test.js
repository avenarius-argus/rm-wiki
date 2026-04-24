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

test("search ignores late callbacks after abort", () => {
  let callbacks;
  let called = false;
  const handle = Wikipedia.search("reMarkable", "en", {
    requestFn(_url, onSuccess, onError) {
      callbacks = { onSuccess, onError };
      return { abort() {} };
    }
  }, () => {
    called = true;
  }, () => {
    called = true;
  });

  handle.abort();
  callbacks.onSuccess(searchFixture);
  callbacks.onError(new Error("late failure"));

  assert.equal(called, false);
});

test("loadArticle ignores late callbacks after abort", () => {
  const requests = [];
  let called = false;
  const handle = Wikipedia.loadArticle("ReMarkable", "en", {
    requestFn(url, onSuccess, onError) {
      requests.push({ url, onSuccess, onError });
      return { abort() {} };
    }
  }, () => {
    called = true;
  }, () => {
    called = true;
  });

  handle.abort();
  requests[0].onSuccess(summaryFixture);
  requests[0].onError(new Error("late failure"));

  assert.equal(requests.length, 1);
  assert.equal(called, false);
});

test("loadArticle aborts the extract request after summary succeeds", () => {
  const requests = [];
  let extractAborted = false;
  let called = false;
  const handle = Wikipedia.loadArticle("ReMarkable", "en", {
    requestFn(url, onSuccess, onError) {
      const request = { url, onSuccess, onError };
      requests.push(request);
      return {
        abort() {
          if (requests.indexOf(request) === 1) {
            extractAborted = true;
          }
        }
      };
    }
  }, () => {
    called = true;
  }, () => {
    called = true;
  });

  requests[0].onSuccess(summaryFixture);
  assert.equal(requests.length, 2);

  handle.abort();
  requests[1].onSuccess(extractFixture);
  requests[1].onError(new Error("late failure"));

  assert.equal(extractAborted, true);
  assert.equal(called, false);
});
