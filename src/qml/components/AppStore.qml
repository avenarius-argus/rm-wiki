import QtQuick 2.15
import QtQuick.LocalStorage 2.0 as Sql
import Qt.labs.settings 1.1
import "../js/history.js" as History

QtObject {
    id: root

    property int maxRecentEntries: 50

    Settings {
        id: settings
        category: "rm-wiki"
        property string language: "en"
        property string lastQuery: ""
    }

    function database() {
        return Sql.LocalStorage.openDatabaseSync("rm-wiki", "1.0", "rm-wiki local store", 1024 * 1024);
    }

    function ensureSchema() {
        var db = database();
        db.transaction(function (tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS entries(bucket TEXT NOT NULL, entry_key TEXT NOT NULL, json_value TEXT NOT NULL, updated_at INTEGER NOT NULL, PRIMARY KEY(bucket, entry_key))");
        });
    }

    function readJson(bucket, entryKey) {
        var db = database();
        var result = null;
        ensureSchema();

        db.readTransaction(function (tx) {
            var rows = tx.executeSql("SELECT json_value FROM entries WHERE bucket = ? AND entry_key = ? LIMIT 1", [bucket, entryKey]);
            if (rows.rows.length > 0) {
                result = JSON.parse(rows.rows.item(0).json_value);
            }
        });

        return result;
    }

    function writeJson(bucket, entryKey, value, updatedAt) {
        var db = database();
        ensureSchema();

        db.transaction(function (tx) {
            tx.executeSql(
                "INSERT OR REPLACE INTO entries(bucket, entry_key, json_value, updated_at) VALUES (?, ?, ?, ?)",
                [bucket, entryKey, JSON.stringify(value), typeof updatedAt === "number" ? updatedAt : Date.now()]
            );
        });
    }

    function getList(bucket) {
        return readJson(bucket, "items") || [];
    }

    function writeList(bucket, items) {
        writeJson(bucket, "items", items, Date.now());
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

    function getCacheEntry(namespaceName, entryKey) {
        return readJson("cache:" + namespaceName, entryKey);
    }

    function putCacheEntry(namespaceName, entryKey, entry) {
        var updatedAt = entry && typeof entry.fetchedAt === "number" ? entry.fetchedAt : Date.now();
        writeJson("cache:" + namespaceName, entryKey, entry, updatedAt);
    }

    function getRecentSearches() {
        return getList("recent-searches");
    }

    function recordRecentSearch(entry) {
        var next = History.touchRecentSearch(getRecentSearches(), entry, maxRecentEntries);
        writeList("recent-searches", next);
        return next;
    }

    function getRecentArticles() {
        return getList("recent-articles");
    }

    function recordRecentArticle(entry) {
        var next = History.touchRecentArticle(getRecentArticles(), entry, maxRecentEntries);
        writeList("recent-articles", next);
        return next;
    }

    Component.onCompleted: ensureSchema()
}

