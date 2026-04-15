import QtQuick 2.15

PanelSurface {
    id: root

    property string heading: ""
    property string emptyText: ""
    property var items: []
    property bool searchMode: false
    property int displayLimit: 6

    signal itemSelected(var item)

    implicitHeight: sectionColumn.implicitHeight + contentPadding * 2

    Column {
        id: sectionColumn
        width: parent.width
        spacing: 12

        Text {
            width: parent.width
            text: root.heading
            color: "#181815"
            font.pixelSize: 30
            font.bold: true
        }

        Text {
            visible: !(root.items && root.items.length)
            width: parent.width
            text: root.emptyText
            color: "#565146"
            font.pixelSize: 22
            wrapMode: Text.Wrap
        }

        Repeater {
            model: root.items ? root.items.slice(0, root.displayLimit) : []

            delegate: ResultTile {
                width: sectionColumn.width
                titleText: root.searchMode ? modelData.query : modelData.title
                metaText: root.searchMode ? "Recent search" : modelData.description
                bodyText: root.searchMode ? "" : modelData.snippetText
                onClicked: root.itemSelected(modelData)
            }
        }
    }
}

