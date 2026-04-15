import QtQuick 2.15
import "components"
import "js/cache.js" as Cache
import "js/wikipedia.js" as Wikipedia

Rectangle {
    id: root

    width: 1404
    height: 1872
    color: "#e8e2d3"

    signal close()

    function unloading() {
    }

    property bool wideLayout: Math.min(width, height) >= 1200
    property bool articleFocused: false
    property string currentLanguage: "en"
    property string searchQuery: ""
    property var searchResults: []
    property var recentSearches: []
    property var recentArticles: []
    property var currentArticle: null
    property bool searchBusy: false
    property bool articleBusy: false
    property string searchStatusText: "Search Wikipedia by title or topic."
    property string articleStatusText: "Open an article to start reading."
    property string errorText: ""
    property int pagePadding: 26
    property int columnGap: 22

    onWideLayoutChanged: {
        if (wideLayout) {
            articleFocused = false;
        }
    }

    function hydrate() {
        currentLanguage = store.getLanguage();
        searchQuery = store.getLastQuery();
        recentSearches = store.getRecentSearches();
        recentArticles = store.getRecentArticles();
    }

    function articleHistoryEntry(article) {
        return {
            title: article.title,
            canonicalTitle: article.canonicalTitle,
            description: article.description,
            snippetText: article.summaryText,
            language: article.language || currentLanguage,
            openedAt: Date.now()
        };
    }

    function searchHistoryEntry(queryText) {
        return {
            query: queryText,
            language: currentLanguage,
            openedAt: Date.now()
        };
    }

    function applySearchResults(results, statusText, queryText) {
        searchResults = results || [];
        searchStatusText = statusText;
        errorText = "";
        recentSearches = store.recordRecentSearch(searchHistoryEntry(queryText));
        store.setLastQuery(queryText);
        searchQuery = queryText;
        articleFocused = false;
    }

    function applyArticle(article, statusText, focusArticle) {
        currentArticle = article;
        articleStatusText = statusText;
        errorText = "";
        recentArticles = store.recordRecentArticle(articleHistoryEntry(article));
        if (!wideLayout) {
            articleFocused = focusArticle !== false;
        }
    }

    function performSearch(rawQuery, forceRefresh) {
        var trimmed = (rawQuery || "").trim();
        var searchKey;
        var cachedEntry;

        if (!trimmed) {
            searchStatusText = "Enter a title or topic to search.";
            searchResults = [];
            errorText = "";
            return;
        }

        searchKey = Cache.makeCacheKey("search", currentLanguage, trimmed);
        cachedEntry = store.getCacheEntry("search", searchKey);

        if (!forceRefresh && Cache.isFresh(cachedEntry, Cache.SEARCH_TTL_MS)) {
            applySearchResults(Cache.unwrap(cachedEntry), "Showing cached results for \"" + trimmed + "\".", trimmed);
            return;
        }

        searchBusy = true;
        searchStatusText = "Searching for \"" + trimmed + "\"...";
        errorText = "";

        Wikipedia.search(
            trimmed,
            currentLanguage,
            {},
            function (results) {
                searchBusy = false;
                store.putCacheEntry("search", searchKey, Cache.createEntry(results));
                applySearchResults(
                    results,
                    results.length ? "Results for \"" + trimmed + "\"." : "No Wikipedia results for \"" + trimmed + "\".",
                    trimmed
                );
            },
            function (error) {
                searchBusy = false;
                if (cachedEntry) {
                    applySearchResults(Cache.unwrap(cachedEntry), "Offline. Showing cached results for \"" + trimmed + "\".", trimmed);
                    return;
                }

                errorText = error && error.message ? error.message : "Unable to search Wikipedia right now.";
                searchStatusText = "Search failed.";
                searchResults = [];
            }
        );
    }

    function openArticle(rawTitle, forceRefresh) {
        var requestedTitle = (rawTitle || "").trim();
        var cacheKey;
        var cachedEntry;

        if (!requestedTitle) {
            return;
        }

        cacheKey = Cache.makeCacheKey("article", currentLanguage, requestedTitle);
        cachedEntry = store.getCacheEntry("article", cacheKey);

        if (!forceRefresh && Cache.isFresh(cachedEntry, Cache.ARTICLE_TTL_MS)) {
            applyArticle(Cache.markPayloadFromCache(Cache.unwrap(cachedEntry), false), "Showing cached article.", true);
            return;
        }

        articleBusy = true;
        articleStatusText = "Loading \"" + requestedTitle + "\"...";
        errorText = "";

        Wikipedia.loadArticle(
            requestedTitle,
            currentLanguage,
            {},
            function (article) {
                var canonicalKey;

                articleBusy = false;
                store.putCacheEntry("article", cacheKey, Cache.createEntry(article, article.fetchedAt));
                canonicalKey = Cache.makeCacheKey("article", currentLanguage, article.canonicalTitle || requestedTitle);
                if (canonicalKey !== cacheKey) {
                    store.putCacheEntry("article", canonicalKey, Cache.createEntry(article, article.fetchedAt));
                }
                applyArticle(article, "Live article loaded from Wikipedia.", true);
            },
            function (error) {
                articleBusy = false;
                if (cachedEntry) {
                    applyArticle(Cache.markPayloadFromCache(Cache.unwrap(cachedEntry), true), "Offline. Showing stale cached article.", true);
                    return;
                }

                errorText = error && error.message ? error.message : "Unable to load this article right now.";
                articleStatusText = "Article failed to load.";
            }
        );
    }

    AppStore {
        id: store
    }

    Component.onCompleted: hydrate()

    Flickable {
        id: shell
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: layoutHost.implicitHeight + root.pagePadding * 2

        Item {
            id: layoutHost
            x: root.pagePadding
            y: root.pagePadding
            width: shell.width - root.pagePadding * 2
            implicitHeight: {
                var leftHeight = leftPane.visible ? leftPane.implicitHeight : 0;
                var articleHeight = articlePane.visible ? articlePane.implicitHeight : 0;

                if (root.wideLayout) {
                    return Math.max(leftHeight, articleHeight);
                }

                if (leftHeight && articleHeight) {
                    return leftHeight + root.columnGap + articleHeight;
                }

                return Math.max(leftHeight, articleHeight);
            }

            PanelSurface {
                id: leftPane
                x: 0
                y: 0
                width: root.wideLayout ? Math.floor(layoutHost.width * 0.39) : layoutHost.width
                visible: root.wideLayout || !root.articleFocused || !root.currentArticle
                implicitHeight: leftColumn.implicitHeight + contentPadding * 2

                Column {
                    id: leftColumn
                    width: parent.width
                    spacing: 18

                    Text {
                        width: parent.width
                        text: "Wikipedia"
                        color: "#171714"
                        font.pixelSize: 48
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: "Paper-first search and reading for reMarkable Paper Pro and Move."
                        color: "#4e4a41"
                        font.pixelSize: 24
                        wrapMode: Text.Wrap
                    }

                    SearchField {
                        width: parent.width
                        text: root.searchQuery
                        busy: root.searchBusy
                        onSubmitted: root.performSearch(text, false)
                    }

                    Text {
                        width: parent.width
                        text: root.searchStatusText
                        color: "#302e29"
                        font.pixelSize: 22
                        wrapMode: Text.Wrap
                    }

                    Text {
                        visible: !!root.errorText
                        width: parent.width
                        text: root.errorText
                        color: "#3f261f"
                        font.pixelSize: 22
                        wrapMode: Text.Wrap
                    }

                    PanelSurface {
                        width: parent.width
                        implicitHeight: resultsColumn.implicitHeight + contentPadding * 2

                        Column {
                            id: resultsColumn
                            width: parent.width
                            spacing: 12

                            Text {
                                width: parent.width
                                text: "Results"
                                color: "#181815"
                                font.pixelSize: 30
                                font.bold: true
                            }

                            Text {
                                visible: !(root.searchResults && root.searchResults.length)
                                width: parent.width
                                text: root.searchBusy ? "Waiting for Wikipedia..." : "Search results appear here."
                                color: "#595348"
                                font.pixelSize: 22
                                wrapMode: Text.Wrap
                            }

                            Repeater {
                                model: root.searchResults || []

                                delegate: ResultTile {
                                    width: resultsColumn.width
                                    titleText: modelData.title
                                    bodyText: modelData.snippetText
                                    metaText: "Wikipedia article"
                                    active: root.currentArticle && root.currentArticle.canonicalTitle === modelData.canonicalTitle
                                    onClicked: root.openArticle(modelData.canonicalTitle, false)
                                }
                            }
                        }
                    }

                    HistorySection {
                        width: parent.width
                        heading: "Recent searches"
                        emptyText: "Your search history will appear here."
                        items: root.recentSearches
                        searchMode: true
                        onItemSelected: root.performSearch(item.query, false)
                    }

                    HistorySection {
                        width: parent.width
                        heading: "Recent articles"
                        emptyText: "Open an article to build a reading trail."
                        items: root.recentArticles
                        onItemSelected: root.openArticle(item.canonicalTitle || item.title, false)
                    }
                }
            }

            PanelSurface {
                id: articlePane
                x: root.wideLayout ? leftPane.width + root.columnGap : 0
                y: root.wideLayout ? 0 : (leftPane.visible ? leftPane.implicitHeight + root.columnGap : 0)
                width: root.wideLayout ? layoutHost.width - leftPane.width - root.columnGap : layoutHost.width
                visible: root.wideLayout || (root.articleFocused && !!root.currentArticle)
                implicitHeight: articleColumn.implicitHeight + contentPadding * 2

                Column {
                    id: articleColumn
                    width: parent.width
                    spacing: 18

                    Row {
                        width: parent.width
                        spacing: 12

                        InkButton {
                            visible: !root.wideLayout
                            label: "Back"
                            onClicked: root.articleFocused = false
                        }

                        InkButton {
                            label: root.articleBusy ? "Refreshing" : "Refresh"
                            disabled: !root.currentArticle || root.articleBusy
                            onClicked: {
                                if (root.currentArticle) {
                                    root.openArticle(root.currentArticle.canonicalTitle || root.currentArticle.title, true);
                                }
                            }
                        }
                    }

                    Text {
                        visible: !root.currentArticle
                        width: parent.width
                        text: "Search for a topic, then open an article to start reading."
                        color: "#595348"
                        font.pixelSize: 28
                        wrapMode: Text.Wrap
                    }

                    Text {
                        visible: !!root.currentArticle
                        width: parent.width
                        text: root.currentArticle ? root.currentArticle.title : ""
                        color: "#171714"
                        font.pixelSize: 44
                        font.bold: true
                        wrapMode: Text.Wrap
                    }

                    Text {
                        visible: !!(root.currentArticle && root.currentArticle.description)
                        width: parent.width
                        text: root.currentArticle ? root.currentArticle.description : ""
                        color: "#514d43"
                        font.pixelSize: 26
                        wrapMode: Text.Wrap
                    }

                    Row {
                        visible: !!root.currentArticle
                        width: parent.width
                        spacing: 12

                        Rectangle {
                            radius: 12
                            height: 38
                            width: badgeText.implicitWidth + 26
                            color: "#1b1b17"

                            Text {
                                id: badgeText
                                anchors.centerIn: parent
                                text: root.currentArticle && root.currentArticle.fromCache ? (root.currentArticle.staleCache ? "Cached • stale" : "Cached") : "Live"
                                color: "#f8f5eb"
                                font.pixelSize: 18
                                font.bold: true
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.articleStatusText
                            color: "#3d3a33"
                            font.pixelSize: 20
                            wrapMode: Text.Wrap
                        }
                    }

                    Text {
                        visible: !!(root.currentArticle && root.currentArticle.summaryText)
                        width: parent.width
                        text: root.currentArticle ? root.currentArticle.summaryText : ""
                        color: "#24211d"
                        font.pixelSize: 28
                        wrapMode: Text.Wrap
                    }

                    Rectangle {
                        visible: !!(root.currentArticle && root.currentArticle.bodyText)
                        width: parent.width
                        height: 1
                        color: "#8b8679"
                    }

                    Text {
                        visible: !!(root.currentArticle && root.currentArticle.bodyText)
                        width: parent.width
                        text: root.currentArticle ? root.currentArticle.bodyText : ""
                        color: "#191815"
                        font.pixelSize: 25
                        lineHeight: 1.22
                        wrapMode: Text.Wrap
                    }

                    Text {
                        visible: !!(root.currentArticle && root.currentArticle.sourceUrl)
                        width: parent.width
                        text: root.currentArticle ? root.currentArticle.sourceUrl : ""
                        color: "#4f493f"
                        font.pixelSize: 18
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }
    }
}

