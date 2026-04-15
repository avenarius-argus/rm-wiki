import QtQuick 2.15
import Qt.labs.settings 1.1
import "../js/history.js" as History

QtObject {
    id: root

    property int maxRecentEntries: 50
    property var cacheEntries: ({})
    property var recentSearchItems: parseArray(settings.recentSearchesJson)
    property var recentArticleItems: parseArray(settings.recentArticlesJson)

    Settings {
        id: settings

        category: "rm-wiki"
        property string language: "en"
        property string lastQuery: ""
        property int articleFontSize: 34
        property string recentSearchesJson: "[]"
        property string recentArticlesJson: "[]"
    }

    function parseArray(value) {
        var parsed;

        try {
            parsed = JSON.parse(value || "[]");
        } catch (_) {
            parsed = [];
        }

        return Array.isArray(parsed) ? parsed : [];
    }

    function persistRecentSearches() {
        settings.recentSearchesJson = JSON.stringify(recentSearchItems || []);
    }

    function persistRecentArticles() {
        settings.recentArticlesJson = JSON.stringify(recentArticleItems || []);
    }

    function getLanguage() {
        return settings.language || "en";
    }

    function setLanguage(value) {
        settings.language = value || "en";
    }

    function getLastQuery() {
        return settings.lastQuery || "";
    }

    function setLastQuery(value) {
        settings.lastQuery = value || "";
    }

    function getArticleFontSize() {
        return settings.articleFontSize > 0 ? settings.articleFontSize : 34;
    }

    function setArticleFontSize(value) {
        settings.articleFontSize = value > 0 ? value : 34;
    }

    function getCacheEntry(namespaceName, entryKey) {
        var scoped = cacheEntries[namespaceName];
        if (!scoped || !Object.prototype.hasOwnProperty.call(scoped, entryKey)) {
            return null;
        }

        return scoped[entryKey];
    }

    function putCacheEntry(namespaceName, entryKey, entry) {
        var scoped = cacheEntries[namespaceName];
        if (!scoped) {
            scoped = {};
        }

        scoped[entryKey] = entry;
        cacheEntries[namespaceName] = scoped;
    }

    function getRecentSearches() {
        return recentSearchItems || [];
    }

    function recordRecentSearch(entry) {
        recentSearchItems = History.touchRecentSearch(getRecentSearches(), entry, maxRecentEntries);
        persistRecentSearches();
        return recentSearchItems;
    }

    function getRecentArticles() {
        return recentArticleItems || [];
    }

    function recordRecentArticle(entry) {
        recentArticleItems = History.touchRecentArticle(getRecentArticles(), entry, maxRecentEntries);
        persistRecentArticles();
        return recentArticleItems;
    }
}
