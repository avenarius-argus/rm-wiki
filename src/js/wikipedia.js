var DEFAULT_LANGUAGE = "en";
var DEFAULT_SEARCH_LIMIT = 20;

function safeString(value) {
  if (value === null || value === undefined) {
    return "";
  }

  return String(value);
}

function normalizeInlineWhitespace(value) {
  return safeString(value)
    .replace(/\u00a0/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function normalizeParagraphWhitespace(value) {
  return safeString(value)
    .replace(/\r\n/g, "\n")
    .replace(/\u00a0/g, " ")
    .replace(/[ \t]+\n/g, "\n")
    .replace(/\n[ \t]+/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

function decodeHtmlEntities(value) {
  var source = safeString(value);
  var named = {
    amp: "&",
    apos: "'",
    gt: ">",
    lt: "<",
    nbsp: " ",
    quot: "\""
  };

  source = source.replace(/&([a-z]+);/gi, function (_, name) {
    var lower = String(name).toLowerCase();
    return Object.prototype.hasOwnProperty.call(named, lower) ? named[lower] : "&" + name + ";";
  });

  source = source.replace(/&#(\d+);/g, function (_, codepoint) {
    return String.fromCharCode(Number(codepoint));
  });

  source = source.replace(/&#x([0-9a-f]+);/gi, function (_, codepoint) {
    return String.fromCharCode(parseInt(codepoint, 16));
  });

  return source;
}

function stripHtml(value) {
  return normalizeInlineWhitespace(decodeHtmlEntities(safeString(value).replace(/<[^>]*>/g, " ")));
}

function buildSearchUrl(query, language, limit) {
  var sanitizedQuery = normalizeInlineWhitespace(query);
  var safeLanguage = normalizeInlineWhitespace(language || DEFAULT_LANGUAGE) || DEFAULT_LANGUAGE;
  var safeLimit = typeof limit === "number" && limit > 0 ? Math.floor(limit) : DEFAULT_SEARCH_LIMIT;

  return "https://" + safeLanguage + ".wikipedia.org/w/api.php?action=query&format=json&formatversion=2&origin=*&list=search&srlimit=" + encodeURIComponent(String(safeLimit)) + "&srsearch=" + encodeURIComponent(sanitizedQuery);
}

function buildSummaryUrl(title, language) {
  var safeLanguage = normalizeInlineWhitespace(language || DEFAULT_LANGUAGE) || DEFAULT_LANGUAGE;
  return "https://" + safeLanguage + ".wikipedia.org/api/rest_v1/page/summary/" + encodeURIComponent(normalizeInlineWhitespace(title));
}

function buildExtractUrl(title, language) {
  var safeLanguage = normalizeInlineWhitespace(language || DEFAULT_LANGUAGE) || DEFAULT_LANGUAGE;
  return "https://" + safeLanguage + ".wikipedia.org/w/api.php?action=query&format=json&formatversion=2&origin=*&prop=extracts&explaintext=1&exsectionformat=plain&redirects=1&titles=" + encodeURIComponent(normalizeInlineWhitespace(title));
}

function normalizeSearchResults(response) {
  var searchItems = [];
  var next = [];
  var index;
  var item;

  if (response && response.query && response.query.search && response.query.search.length) {
    searchItems = response.query.search;
  }

  for (index = 0; index < searchItems.length; index += 1) {
    item = searchItems[index];
    next.push({
      title: normalizeInlineWhitespace(item.title),
      snippetText: stripHtml(item.snippet),
      canonicalTitle: normalizeInlineWhitespace(item.title)
    });
  }

  return next;
}

function pickExtractPage(extractResponse) {
  var pages = extractResponse && extractResponse.query && extractResponse.query.pages ? extractResponse.query.pages : [];
  if (pages.length > 0) {
    return pages[0];
  }

  return {};
}

function fallbackSourceUrl(language, title) {
  return "https://" + (normalizeInlineWhitespace(language || DEFAULT_LANGUAGE) || DEFAULT_LANGUAGE) + ".wikipedia.org/wiki/" + encodeURIComponent(normalizeInlineWhitespace(title).replace(/\s+/g, "_"));
}

function normalizeArticlePayload(summaryResponse, extractResponse, language, fetchedAt, requestedTitle) {
  var page = pickExtractPage(extractResponse);
  var summaryTitle = normalizeInlineWhitespace(summaryResponse && summaryResponse.title);
  var pageTitle = normalizeInlineWhitespace(page && page.title);
  var canonicalTitle = summaryTitle || pageTitle || normalizeInlineWhitespace(requestedTitle);
  var summaryText = normalizeParagraphWhitespace(summaryResponse && summaryResponse.extract);
  var bodyText = normalizeParagraphWhitespace(page && page.extract);
  var description = normalizeInlineWhitespace(summaryResponse && summaryResponse.description);
  var sourceUrl = summaryResponse &&
    summaryResponse.content_urls &&
    summaryResponse.content_urls.desktop &&
    summaryResponse.content_urls.desktop.page
      ? summaryResponse.content_urls.desktop.page
      : fallbackSourceUrl(language, canonicalTitle);

  if (!bodyText) {
    bodyText = summaryText;
  }

  return {
    title: canonicalTitle,
    canonicalTitle: canonicalTitle,
    description: description,
    summaryText: summaryText,
    bodyText: bodyText,
    sourceUrl: sourceUrl,
    fetchedAt: typeof fetchedAt === "number" ? fetchedAt : Date.now(),
    language: normalizeInlineWhitespace(language || DEFAULT_LANGUAGE) || DEFAULT_LANGUAGE,
    fromCache: false
  };
}

function defaultRequest(url, onSuccess, onError) {
  var xhr;

  if (typeof XMLHttpRequest === "undefined") {
    onError(new Error("XMLHttpRequest is not available in this runtime."));
    return;
  }

  xhr = new XMLHttpRequest();
  xhr.open("GET", url);
  xhr.onreadystatechange = function () {
    var payload;

    if (xhr.readyState !== XMLHttpRequest.DONE) {
      return;
    }

    if (xhr.status >= 200 && xhr.status < 300) {
      try {
        payload = JSON.parse(xhr.responseText);
        onSuccess(payload);
      } catch (error) {
        onError(error);
      }
      return;
    }

    onError(new Error("Request failed with status " + xhr.status + " for " + url));
  };
  xhr.onerror = function () {
    onError(new Error("Network request failed for " + url));
  };
  xhr.send();
}

function requestJson(url, options, onSuccess, onError) {
  var requestImpl = options && typeof options.requestFn === "function" ? options.requestFn : defaultRequest;
  requestImpl(url, onSuccess, onError);
}

function search(query, language, options, onSuccess, onError) {
  var safeQuery = normalizeInlineWhitespace(query);
  var safeLanguage = normalizeInlineWhitespace(language || DEFAULT_LANGUAGE) || DEFAULT_LANGUAGE;

  if (!safeQuery) {
    onSuccess([]);
    return;
  }

  requestJson(
    buildSearchUrl(safeQuery, safeLanguage, options && options.limit),
    options,
    function (response) {
      onSuccess(normalizeSearchResults(response));
    },
    onError
  );
}

function loadArticle(title, language, options, onSuccess, onError) {
  var safeTitle = normalizeInlineWhitespace(title);
  var safeLanguage = normalizeInlineWhitespace(language || DEFAULT_LANGUAGE) || DEFAULT_LANGUAGE;
  var fetchedAt = Date.now();

  if (!safeTitle) {
    onError(new Error("Article title is required."));
    return;
  }

  requestJson(
    buildSummaryUrl(safeTitle, safeLanguage),
    options,
    function (summaryResponse) {
      requestJson(
        buildExtractUrl(safeTitle, safeLanguage),
        options,
        function (extractResponse) {
          onSuccess(normalizeArticlePayload(summaryResponse, extractResponse, safeLanguage, fetchedAt, safeTitle));
        },
        function () {
          onSuccess(normalizeArticlePayload(summaryResponse, {}, safeLanguage, fetchedAt, safeTitle));
        }
      );
    },
    function () {
      requestJson(
        buildExtractUrl(safeTitle, safeLanguage),
        options,
        function (extractResponse) {
          onSuccess(normalizeArticlePayload({}, extractResponse, safeLanguage, fetchedAt, safeTitle));
        },
        onError
      );
    }
  );
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    DEFAULT_LANGUAGE: DEFAULT_LANGUAGE,
    DEFAULT_SEARCH_LIMIT: DEFAULT_SEARCH_LIMIT,
    buildExtractUrl: buildExtractUrl,
    buildSearchUrl: buildSearchUrl,
    buildSummaryUrl: buildSummaryUrl,
    loadArticle: loadArticle,
    normalizeArticlePayload: normalizeArticlePayload,
    normalizeSearchResults: normalizeSearchResults,
    search: search,
    stripHtml: stripHtml
  };
}

