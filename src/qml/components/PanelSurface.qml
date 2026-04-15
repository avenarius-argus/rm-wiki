import QtQuick 2.15

Rectangle {
    id: root

    default property alias contentData: container.data

    property color surfaceColor: "#f5f2e8"
    property color outlineColor: "#5e594d"
    property int contentPadding: 22

    radius: 28
    border.width: 1
    border.color: outlineColor
    color: surfaceColor

    Item {
        id: container
        anchors.fill: parent
        anchors.margins: root.contentPadding
    }
}

