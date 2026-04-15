import QtQuick 2.15

Rectangle {
    id: root

    default property alias contentData: container.data

    property color surfaceColor: "#f7f1e4"
    property color outlineColor: "#d1c7b7"
    property int contentPadding: 24

    radius: 34
    border.width: 1
    border.color: outlineColor
    color: surfaceColor

    Item {
        id: container
        anchors.fill: parent
        anchors.margins: root.contentPadding
    }
}
