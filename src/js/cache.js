var SEARCH_TTL_MS = 15 * 60 * 1000;
var ARTICLE_TTL_MS = 24 * 60 * 60 * 1000;

function safeString(value) {
  if (value === null || value === undefined) {
    return "";
  }

  return String(value);
}

function normalizeSegment(value) {
  return safeString(value).trim().toLowerCase().replace(/\s+/g, " ");
}

function makeCacheKey(kind, language, value) {
  return [
    normalizeSegment(kind),
    normalizeSegment(language || "en"),
    normalizeSegment(value)
  ].join("::");
}

function cloneValue(value) {
  if (value === null || value === undefined) {
    return value;
  }

  return JSON.parse(JSON.stringify(value));
}

function nowOrDefault(nowValue) {
  if (typeof nowValue === "number" && isFinite(nowValue)) {
    return nowValue;
  }

  return Date.now();
}

function createEntry(value, fetchedAt) {
  return {
    value: cloneValue(value),
    fetchedAt: nowOrDefault(fetchedAt)
  };
}

function ageMs(entry, nowValue) {
  if (!entry || typeof entry.fetchedAt !== "number") {
    return Number.POSITIVE_INFINITY;
  }

  return Math.max(0, nowOrDefault(nowValue) - entry.fetchedAt);
}

function isFresh(entry, ttlMs, nowValue) {
  if (!entry || typeof ttlMs !== "number" || ttlMs < 0) {
    return false;
  }

  return ageMs(entry, nowValue) <= ttlMs;
}

function unwrap(entry) {
  if (!entry || entry.value === undefined) {
    return null;
  }

  return cloneValue(entry.value);
}

function markPayloadFromCache(payload, isStale) {
  var next = cloneValue(payload) || {};
  next.fromCache = true;
  next.staleCache = !!isStale;
  return next;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    ARTICLE_TTL_MS: ARTICLE_TTL_MS,
    SEARCH_TTL_MS: SEARCH_TTL_MS,
    ageMs: ageMs,
    createEntry: createEntry,
    isFresh: isFresh,
    makeCacheKey: makeCacheKey,
    markPayloadFromCache: markPayloadFromCache,
    unwrap: unwrap
  };
}

