const test = require("node:test");
const assert = require("node:assert/strict");

const Pagination = require("../src/js/pagination");

test("mergeSummaryAndBody avoids duplicating a lead that already starts the body", () => {
  const summary = "reMarkable is a paper tablet.";
  const body = "reMarkable is a paper tablet.\n\nIt is designed for focused reading.";

  assert.equal(
    Pagination.mergeSummaryAndBody(summary, body),
    "reMarkable is a paper tablet.\n\nIt is designed for focused reading."
  );
});

test("paginateArticle splits long text into multiple reader pages", () => {
  const summary = "A quiet summary.";
  const body = Array.from({ length: 40 }, (_, index) => "Paragraph " + index + " with enough words to force pagination in the reader.").join("\n\n");
  const pages = Pagination.paginateArticle(summary, body, 760, 980, 34);

  assert.ok(pages.length > 1);
  assert.ok(pages[0].includes("A quiet summary."));
  assert.ok(pages[pages.length - 1].includes("Paragraph 39"));
});

