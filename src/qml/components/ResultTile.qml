import QtQuick 2.15

Rectangle {
    id: root

    property string titleText: ""
    property string bodyText: ""
    property string metaText: ""
    property bool active: false

    signal clicked()

    width: parent ? parent.width : 360
    radius: 18
    border.width: 1
    border.color: active ? "#1a1a17" : "#6b665b"
    color: mouseArea.pressed ? "#e0dbcf" : active ? "#ece7d8" : "#faf8f2"
    implicitHeight: tileColumn.implicitHeight + 26

    Column {
        id: tileColumn
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        Text {
            width: parent.width
            text: root.titleText
            color: "#181815"
            font.pixelSize: 26
            font.bold: true
            wrapMode: Text.Wrap
        }

        Text {
            visible: !!root.metaText
            width: parent.width
            text: root.metaText
            color: "#4f493f"
            font.pixelSize: 20
            wrapMode: Text.Wrap
        }

        Text {
            visible: !!root.bodyText
            width: parent.width
            text: root.bodyText
            color: "#2c2a25"
            font.pixelSize: 22
            wrapMode: Text.Wrap
            maximumLineCount: 4
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: root.clicked()
    }
}

