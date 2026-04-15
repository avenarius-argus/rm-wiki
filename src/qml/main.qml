import QtQuick 2.15
import "components"
import "js/cache.js" as Cache
import "js/pagination.js" as Pagination
import "js/wikipedia.js" as Wikipedia

Rectangle {
    id: root

    implicitWidth: 1404
    implicitHeight: 1872
    width: parent ? parent.width : implicitWidth
    height: parent ? parent.height : implicitHeight
    color: "#e8decc"
    focus: true

    signal close()

    function unloading() {
    }

    property color paperBase: "#e8decc"
    property color paperPanel: "#f6efe2"
    property color paperInset: "#fbf6eb"
    property color ink: "#171512"
    property color mutedInk: "#6b6254"
    property color lineInk: "#d0c6b6"
    property color accent: "#1b1813"

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
    property string searchStatusText: "Search for a subject, person, place, or event."
    property string articleStatusText: "Pick an article to open the reader."
    property string errorText: ""
    property int articleFontSize: 34
    property int pagePadding: 26
    property int columnGap: 24
    property var articlePages: []
    property int articlePageIndex: 0
    property string browseSection: "search"
    property int searchResultsPage: 0

    function dismissKeyboard() {
        searchField.dismissKeyboard();
        focus = true;
        if (Qt.inputMethod && Qt.inputMethod.hide) {
            Qt.inputMethod.hide();
        }
    }

    function schedulePagination() {
        paginateTimer.restart();
    }

    function rebuildArticlePages() {
        if (!currentArticle || articlePageViewport.width <= 0 || articlePageViewport.height <= 0) {
            articlePages = [];
            articlePageIndex = 0;
            return;
        }

        articlePages = Pagination.paginateArticle(
            currentArticle.summaryText,
            currentArticle.bodyText,
            articlePageViewport.width,
            articlePageViewport.height,
            articleFontSize
        );

        if (!articlePages.length) {
            articlePages = [currentArticle.summaryText || currentArticle.bodyText || ""];
        }

        articlePageIndex = Math.max(0, Math.min(articlePageIndex, articlePages.length - 1));
    }

    function setArticleFontSize(nextSize) {
        var clamped = Math.max(28, Math.min(44, nextSize));

        if (clamped === articleFontSize) {
            return;
        }

        articleFontSize = clamped;
        store.setArticleFontSize(clamped);
        schedulePagination();
    }

    function stepArticlePage(delta) {
        articlePageIndex = Math.max(0, Math.min(articlePages.length - 1, articlePageIndex + delta));
    }

    function hydrate() {
        currentLanguage = store.getLanguage();
        searchQuery = store.getLastQuery();
        recentSearches = store.getRecentSearches();
        recentArticles = store.getRecentArticles();
        articleFontSize = store.getArticleFontSize();
        schedulePagination();
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
        searchResultsPage = 0;
        browseSection = "search";
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
        articlePageIndex = 0;
        schedulePagination();

        if (!wideLayout) {
            articleFocused = focusArticle !== false;
        }
    }

    function performSearch(rawQuery, forceRefresh) {
        var trimmed = (rawQuery || "").trim();
        var searchKey;
        var cachedEntry;

        dismissKeyboard();

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

        dismissKeyboard();

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
                applyArticle(article, "Fresh text loaded from Wikipedia.", true);
            },
            function (error) {
                articleBusy = false;
                if (cachedEntry) {
                    applyArticle(Cache.markPayloadFromCache(Cache.unwrap(cachedEntry), true), "Offline. Showing cached article.", true);
                    return;
                }

                errorText = error && error.message ? error.message : "Unable to load this article right now.";
                articleStatusText = "Article failed to load.";
            }
        );
    }

    onWideLayoutChanged: {
        if (wideLayout) {
            articleFocused = false;
        }

        schedulePagination();
    }

    onWidthChanged: schedulePagination()
    onHeightChanged: schedulePagination()
    onCurrentArticleChanged: schedulePagination()
    onArticleFontSizeChanged: schedulePagination()

    Timer {
        id: paginateTimer

        interval: 0
        repeat: false
        onTriggered: root.rebuildArticlePages()
    }

    TapHandler {
        target: null
        onTapped: root.dismissKeyboard()
    }

    AppStore {
        id: store
    }

    Component.onCompleted: hydrate()

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height * 0.28
        color: "#efe5d5"
        opacity: 0.55
    }

    Item {
        id: stage

        anchors.fill: parent
        anchors.margins: root.pagePadding

        PanelSurface {
            id: browsePane

            x: 0
            y: 0
            width: root.wideLayout ? Math.floor(stage.width * 0.37) : stage.width
            height: stage.height
            visible: root.wideLayout || !root.articleFocused
            contentPadding: 26
            surfaceColor: root.paperPanel
            outlineColor: root.lineInk

            Item {
                anchors.fill: parent

                Column {
                    id: browseColumn

                    width: parent.width
                    spacing: 18

                    Text {
                        width: parent.width
                        text: "RM WIKI"
                        color: root.mutedInk
                        font.pixelSize: 18
                        font.bold: true
                        font.letterSpacing: 3.2
                    }

                    Text {
                        width: parent.width
                        text: "Wikipedia,\npared down for paper."
                        color: root.ink
                        font.pixelSize: root.wideLayout ? 54 : 46
                        font.bold: true
                        wrapMode: Text.Wrap
                    }

                    Text {
                        width: parent.width
                        text: "No in-app scrolling. Search, switch views, and read in pages."
                        color: root.mutedInk
                        font.pixelSize: 22
                        wrapMode: Text.Wrap
                    }

                    SearchField {
                        id: searchField

                        width: parent.width
                        text: root.searchQuery
                        busy: root.searchBusy
                        placeholderText: "Search people, places, or ideas"
                        onSubmitted: function (submittedText) {
                            root.performSearch(submittedText, false);
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 10

                        InkButton {
                            label: "Search"
                            minimumWidth: 120
                            emphasized: root.browseSection === "search"
                            onClicked: root.browseSection = "search"
                        }

                        InkButton {
                            label: "Library"
                            minimumWidth: 120
                            emphasized: root.browseSection === "library"
                            onClicked: root.browseSection = "library"
                        }

                        Item {
                            width: 16
                            height: 1
                        }

                        InkButton {
                            label: "A-"
                            minimumWidth: 72
                            onClicked: root.setArticleFontSize(root.articleFontSize - 2)
                        }

                        InkButton {
                            label: "A+"
                            minimumWidth: 72
                            onClicked: root.setArticleFontSize(root.articleFontSize + 2)
                        }
                    }
                }

                Item {
                    id: browseBody

                    anchors.top: browseColumn.bottom
                    anchors.topMargin: 20
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    PanelSurface {
                        anchors.fill: parent
                        visible: root.browseSection === "search"
                        surfaceColor: root.paperInset
                        outlineColor: root.lineInk

                        Item {
                            anchors.fill: parent

                            Column {
                                id: searchSectionHeader

                                width: parent.width
                                spacing: 10

                                Text {
                                    width: parent.width
                                    text: "RESULTS"
                                    color: root.mutedInk
                                    font.pixelSize: 18
                                    font.bold: true
                                    font.letterSpacing: 2.6
                                }

                                Text {
                                    width: parent.width
                                    text: root.searchStatusText
                                    color: root.ink
                                    font.pixelSize: 24
                                    wrapMode: Text.Wrap
                                }

                                Text {
                                    visible: !!root.errorText
                                    width: parent.width
                                    text: root.errorText
                                    color: "#5f342b"
                                    font.pixelSize: 22
                                    wrapMode: Text.Wrap
                                }
                            }

                            Item {
                                id: resultsViewport

                                anchors.top: searchSectionHeader.bottom
                                anchors.topMargin: 16
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: resultsFooter.top
                                anchors.bottomMargin: 14

                                Column {
                                    width: parent.width
                                    spacing: 10

                                    Text {
                                        visible: !(root.searchResults && root.searchResults.length)
                                        width: parent.width
                                        text: "Run a search to fill this shelf. Results are shown in pages instead of a scroll list."
                                        color: root.mutedInk
                                        font.pixelSize: 22
                                        wrapMode: Text.Wrap
                                    }

                                    Repeater {
                                        model: root.searchResults ? root.searchResults.slice(root.searchResultsPage * 4, root.searchResultsPage * 4 + 4) : []

                                        delegate: ResultTile {
                                            width: resultsViewport.width
                                            titleText: modelData.title
                                            bodyText: modelData.snippetText
                                            metaText: "Open in reader"
                                            active: root.currentArticle && root.currentArticle.canonicalTitle === modelData.canonicalTitle
                                            onClicked: root.openArticle(modelData.canonicalTitle, false)
                                        }
                                    }
                                }
                            }

                            Row {
                                id: resultsFooter

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                spacing: 10

                                InkButton {
                                    label: "Previous"
                                    minimumWidth: 120
                                    disabled: root.searchResultsPage <= 0
                                    onClicked: root.searchResultsPage = root.searchResultsPage - 1
                                }

                                Rectangle {
                                    width: Math.max(170, searchPageLabel.implicitWidth + 28)
                                    height: 54
                                    radius: 27
                                    color: root.paperPanel
                                    border.width: 1
                                    border.color: root.lineInk

                                    Text {
                                        id: searchPageLabel

                                        anchors.centerIn: parent
                                        text: "Page " + (root.searchResults.length ? root.searchResultsPage + 1 : 0) + " of " + Math.max(1, Math.ceil(root.searchResults.length / 4))
                                        color: root.ink
                                        font.pixelSize: 20
                                        font.bold: true
                                    }
                                }

                                InkButton {
                                    label: "Next"
                                    minimumWidth: 98
                                    disabled: !root.searchResults.length || (root.searchResultsPage + 1) * 4 >= root.searchResults.length
                                    onClicked: root.searchResultsPage = root.searchResultsPage + 1
                                }
                            }
                        }
                    }

                    PanelSurface {
                        anchors.fill: parent
                        visible: root.browseSection === "library"
                        surfaceColor: root.paperInset
                        outlineColor: root.lineInk

                        Column {
                            anchors.fill: parent
                            spacing: 14

                            Text {
                                width: parent.width
                                text: "LIBRARY"
                                color: root.mutedInk
                                font.pixelSize: 18
                                font.bold: true
                                font.letterSpacing: 2.6
                            }

                            Text {
                                width: parent.width
                                text: "A static home screen for the things you touched recently."
                                color: root.ink
                                font.pixelSize: 22
                                wrapMode: Text.Wrap
                            }

                            HistorySection {
                                width: parent.width
                                heading: "Recent searches"
                                emptyText: "Your last searches will live here."
                                items: root.recentSearches
                                searchMode: true
                                displayLimit: 3
                                surfaceColor: root.paperPanel
                                outlineColor: root.lineInk
                                onItemSelected: root.performSearch(item.query, false)
                            }

                            HistorySection {
                                width: parent.width
                                heading: "Recent articles"
                                emptyText: "Open an article and it will stay close at hand."
                                items: root.recentArticles
                                displayLimit: 3
                                surfaceColor: root.paperPanel
                                outlineColor: root.lineInk
                                onItemSelected: root.openArticle(item.canonicalTitle || item.title, false)
                            }
                        }
                    }
                }
            }
        }

        PanelSurface {
            id: articlePane

            x: root.wideLayout ? browsePane.width + root.columnGap : 0
            y: 0
            width: root.wideLayout ? stage.width - browsePane.width - root.columnGap : stage.width
            height: stage.height
            visible: root.wideLayout || root.articleFocused
            contentPadding: 26
            surfaceColor: root.paperPanel
            outlineColor: root.lineInk

            Item {
                anchors.fill: parent

                Item {
                    id: articleEmptyState

                    anchors.fill: parent
                    visible: !root.currentArticle

                    Column {
                        width: parent.width * 0.8
                        anchors.centerIn: parent
                        spacing: 18

                        Text {
                            width: parent.width
                            text: "A quiet reader, not a scrolling feed."
                            color: root.ink
                            font.pixelSize: root.wideLayout ? 52 : 44
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                        }

                        Text {
                            width: parent.width
                            text: "Search for an article, then read it one page at a time. The reader keeps the screen steady and the typography generous."
                            color: root.mutedInk
                            font.pixelSize: 26
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                        }
                    }
                }

                Item {
                    id: articleReader

                    anchors.fill: parent
                    visible: !!root.currentArticle

                    Item {
                        id: headerBlock

                        width: parent.width
                        height: headerTopRow.implicitHeight + articleTitleBlock.implicitHeight + 18

                        Column {
                            id: articleTitleBlock

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: headerTopRow.bottom
                            anchors.topMargin: 14
                            spacing: 10

                            Text {
                                width: parent.width
                                text: root.currentArticle ? root.currentArticle.title : ""
                                color: root.ink
                                font.pixelSize: root.wideLayout ? 54 : 46
                                font.bold: true
                                wrapMode: Text.Wrap
                            }

                            Text {
                                visible: !!(root.currentArticle && root.currentArticle.description)
                                width: parent.width
                                text: root.currentArticle ? root.currentArticle.description : ""
                                color: root.mutedInk
                                font.pixelSize: 24
                                wrapMode: Text.Wrap
                            }
                        }

                        Row {
                            id: headerTopRow

                            width: parent.width
                            spacing: 10

                            InkButton {
                                visible: !root.wideLayout
                                label: "Back"
                                minimumWidth: 98
                                onClicked: root.articleFocused = false
                            }

                            InkButton {
                                label: "A-"
                                minimumWidth: 74
                                onClicked: root.setArticleFontSize(root.articleFontSize - 2)
                            }

                            InkButton {
                                label: "A+"
                                minimumWidth: 74
                                onClicked: root.setArticleFontSize(root.articleFontSize + 2)
                            }

                            InkButton {
                                label: root.articleBusy ? "Refreshing" : "Refresh"
                                minimumWidth: 140
                                disabled: root.articleBusy
                                onClicked: {
                                    if (root.currentArticle) {
                                        root.openArticle(root.currentArticle.canonicalTitle || root.currentArticle.title, true);
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: readerCard

                        y: headerBlock.height + 16
                        width: parent.width
                        height: Math.max(260, parent.height - headerBlock.height - footerControls.height - 28)
                        radius: 34
                        color: root.paperInset
                        border.width: 1
                        border.color: root.lineInk

                        Item {
                            id: articlePageViewport

                            anchors.fill: parent
                            anchors.margins: 26

                            Text {
                                anchors.fill: parent
                                text: root.articlePages.length ? root.articlePages[root.articlePageIndex] : ""
                                color: root.ink
                                font.pixelSize: root.articleFontSize
                                wrapMode: Text.Wrap
                                lineHeight: 1.32
                                lineHeightMode: Text.ProportionalHeight
                                clip: true
                            }
                        }
                    }

                    Row {
                        id: footerControls

                        width: parent.width
                        y: parent.height - implicitHeight
                        spacing: 10

                        InkButton {
                            label: "Previous"
                            minimumWidth: 132
                            disabled: root.articlePageIndex <= 0
                            onClicked: root.stepArticlePage(-1)
                        }

                        Rectangle {
                            width: Math.max(180, pageLabel.implicitWidth + 28)
                            height: 54
                            radius: 27
                            color: root.paperInset
                            border.width: 1
                            border.color: root.lineInk

                            Text {
                                id: pageLabel

                                anchors.centerIn: parent
                                text: "Page " + (root.articlePages.length ? root.articlePageIndex + 1 : 0) + " of " + root.articlePages.length
                                color: root.ink
                                font.pixelSize: 21
                                font.bold: true
                            }
                        }

                        InkButton {
                            label: "Next"
                            minimumWidth: 112
                            disabled: !root.articlePages.length || root.articlePageIndex >= root.articlePages.length - 1
                            onClicked: root.stepArticlePage(1)
                        }

                        Rectangle {
                            width: Math.max(210, sourceLabel.implicitWidth + 28)
                            height: 54
                            radius: 27
                            color: root.paperInset
                            border.width: 1
                            border.color: root.lineInk

                            Text {
                                id: sourceLabel

                                anchors.centerIn: parent
                                text: root.currentArticle && root.currentArticle.fromCache ? (root.currentArticle.staleCache ? "Cached copy" : "Cached") : "Live article"
                                color: root.mutedInk
                                font.pixelSize: 20
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }
    }
}
