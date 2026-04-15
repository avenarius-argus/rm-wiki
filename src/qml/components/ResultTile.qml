import QtQuick 2.15

Rectangle {
    id: root

    property string titleText: ""
    property string bodyText: ""
    property string metaText: ""
    property bool active: false

    signal clicked()

    width: parent ? parent.width : 360
    radius: 24
    border.width: active ? 1 : 0
    border.color: "#181815"
    color: mouseArea.pressed ? "#ece3d5" : active ? "#efe6d8" : "#f9f4ea"
    implicitHeight: tileColumn.implicitHeight + 24

    Column {
        id: tileColumn
        anchors.fill: parent
        anchors.margins: 16
        spacing: 6

        Text {
            width: parent.width
            text: root.titleText
            color: "#181815"
            font.pixelSize: 28
            font.bold: true
            wrapMode: Text.Wrap
        }

        Text {
            visible: !!root.metaText
            width: parent.width
            text: root.metaText
            color: "#6b6254"
            font.pixelSize: 18
            font.letterSpacing: 1.2
            wrapMode: Text.Wrap
        }

        Text {
            visible: !!root.bodyText
            width: parent.width
            text: root.bodyText
            color: "#302c25"
            font.pixelSize: 22
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
