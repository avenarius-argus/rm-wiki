var DEFAULT_LIMIT = 50;

function safeString(value) {
  if (value === null || value === undefined) {
    return "";
  }

  return String(value);
}

function normalizeText(value) {
  return safeString(value).trim().replace(/\s+/g, " ");
}

function normalizeLanguage(value) {
  var normalized = normalizeText(value).toLowerCase();
  return normalized || "en";
}

function normalizeTimestamp(value) {
  if (typeof value === "number" && isFinite(value)) {
    return value;
  }

  return Date.now();
}

function searchIdentity(entry) {
  return normalizeLanguage(entry && entry.language) + "::" + normalizeText(entry && entry.query).toLowerCase();
}

function articleIdentity(entry) {
  var canonical = normalizeText(entry && (entry.canonicalTitle || entry.title)).toLowerCase();
  return normalizeLanguage(entry && entry.language) + "::" + canonical;
}

function normalizeSearchEntry(entry) {
  return {
    query: normalizeText(entry && entry.query),
    language: normalizeLanguage(entry && entry.language),
    openedAt: normalizeTimestamp(entry && entry.openedAt)
  };
}

function normalizeArticleEntry(entry) {
  return {
    title: normalizeText(entry && entry.title),
    canonicalTitle: normalizeText(entry && (entry.canonicalTitle || entry.title)),
    description: normalizeText(entry && entry.description),
    snippetText: normalizeText(entry && entry.snippetText),
    language: normalizeLanguage(entry && entry.language),
    openedAt: normalizeTimestamp(entry && entry.openedAt)
  };
}

function limitEntries(items, limit) {
  var capped = typeof limit === "number" && limit > 0 ? limit : DEFAULT_LIMIT;
  return (items || []).slice(0, capped);
}

function touchEntry(items, entry, identityFn, normalizeFn, limit) {
  var next = [];
  var normalizedEntry = normalizeFn(entry);
  var targetId = identityFn(normalizedEntry);
  var index;
  var current;

  next.push(normalizedEntry);

  for (index = 0; index < (items || []).length; index += 1) {
    current = normalizeFn(items[index]);
    if (identityFn(current) !== targetId) {
      next.push(current);
    }
  }

  return limitEntries(next, limit);
}

function touchRecentSearch(items, entry, limit) {
  return touchEntry(items, entry, searchIdentity, normalizeSearchEntry, limit);
}

function touchRecentArticle(items, entry, limit) {
  return touchEntry(items, entry, articleIdentity, normalizeArticleEntry, limit);
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    DEFAULT_LIMIT: DEFAULT_LIMIT,
    articleIdentity: articleIdentity,
    normalizeArticleEntry: normalizeArticleEntry,
    normalizeSearchEntry: normalizeSearchEntry,
    searchIdentity: searchIdentity,
    touchRecentArticle: touchRecentArticle,
    touchRecentSearch: touchRecentSearch
  };
}

