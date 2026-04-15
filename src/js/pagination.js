var DEFAULT_FONT_SIZE = 38;

function safeString(value) {
  if (value === null || value === undefined) {
    return "";
  }

  return String(value);
}

function normalizeBlockText(value) {
  return safeString(value)
    .replace(/\r\n/g, "\n")
    .replace(/\u00a0/g, " ")
    .replace(/[ \t]+\n/g, "\n")
    .replace(/\n[ \t]+/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

function mergeSummaryAndBody(summaryText, bodyText) {
  var safeSummary = normalizeBlockText(summaryText);
  var safeBody = normalizeBlockText(bodyText);

  if (!safeSummary) {
    return safeBody;
  }

  if (!safeBody) {
    return safeSummary;
  }

  if (safeBody.indexOf(safeSummary) === 0) {
    return safeBody;
  }

  return safeSummary + "\n\n" + safeBody;
}

function splitParagraphs(text) {
  var blocks = normalizeBlockText(text).split(/\n{2,}/);
  var index;
  var next = [];

  for (index = 0; index < blocks.length; index += 1) {
    if (blocks[index]) {
      next.push(blocks[index]);
    }
  }

  return next;
}

function splitLongParagraph(paragraph, targetLength) {
  var words = normalizeBlockText(paragraph).split(/\s+/);
  var chunks = [];
  var current = "";
  var index;
  var candidate;

  if (paragraph.length <= targetLength) {
    return [paragraph];
  }

  for (index = 0; index < words.length; index += 1) {
    candidate = current ? current + " " + words[index] : words[index];

    if (current && candidate.length > targetLength) {
      chunks.push(current);
      current = words[index];
    } else {
      current = candidate;
    }
  }

  if (current) {
    chunks.push(current);
  }

  return chunks;
}

function estimateCharsPerPage(viewWidth, viewHeight, fontSize) {
  var safeWidth = Math.max(320, Number(viewWidth) || 0);
  var safeHeight = Math.max(420, Number(viewHeight) || 0);
  var safeFontSize = Math.max(24, Number(fontSize) || DEFAULT_FONT_SIZE);
  var charsPerLine = Math.max(24, Math.floor(safeWidth / (safeFontSize * 0.78)));
  var linesPerPage = Math.max(10, Math.floor(safeHeight / (safeFontSize * 1.82)));

  return Math.max(320, Math.floor(charsPerLine * linesPerPage * 0.88));
}

function paginateArticle(summaryText, bodyText, viewWidth, viewHeight, fontSize) {
  var mergedText = mergeSummaryAndBody(summaryText, bodyText);
  var paragraphs;
  var budget;
  var oversizedLimit;
  var pages = [];
  var currentPage = "";
  var currentLength = 0;
  var index;
  var paragraph;
  var chunks;
  var chunkIndex;
  var chunk;
  var nextLength;

  if (!mergedText) {
    return [];
  }

  paragraphs = splitParagraphs(mergedText);
  budget = estimateCharsPerPage(viewWidth, viewHeight, fontSize);
  oversizedLimit = Math.max(220, Math.floor(budget * 0.55));

  for (index = 0; index < paragraphs.length; index += 1) {
    paragraph = paragraphs[index];
    chunks = splitLongParagraph(paragraph, oversizedLimit);

    for (chunkIndex = 0; chunkIndex < chunks.length; chunkIndex += 1) {
      chunk = chunks[chunkIndex];
      nextLength = currentPage ? currentLength + 2 + chunk.length : chunk.length;

      if (currentPage && nextLength > budget) {
        pages.push(currentPage);
        currentPage = chunk;
        currentLength = chunk.length;
      } else {
        currentPage = currentPage ? currentPage + "\n\n" + chunk : chunk;
        currentLength = nextLength;
      }
    }
  }

  if (currentPage) {
    pages.push(currentPage);
  }

  return pages;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    DEFAULT_FONT_SIZE: DEFAULT_FONT_SIZE,
    estimateCharsPerPage: estimateCharsPerPage,
    mergeSummaryAndBody: mergeSummaryAndBody,
    paginateArticle: paginateArticle,
    splitLongParagraph: splitLongParagraph,
    splitParagraphs: splitParagraphs
  };
}
