import QtQuick 2.15

Rectangle {
    id: root

    default property alias contentData: container.data

    property color surfaceColor: "#f8f2e8"
    property color outlineColor: "#d7ccb9"
    property int contentPadding: 24

    radius: 38
    border.width: 1
    border.color: outlineColor
    color: surfaceColor

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 18
        radius: parent.radius
        color: Qt.rgba(1, 1, 1, 0.09)
        clip: true
    }

    Item {
        id: container
        anchors.fill: parent
        anchors.margins: root.contentPadding
    }
}
