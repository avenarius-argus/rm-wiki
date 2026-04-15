import QtQuick 2.15

Rectangle {
    id: root

    property string titleText: ""
    property string bodyText: ""
    property string metaText: ""
    property bool active: false

    signal clicked()

    width: parent ? parent.width : 360
    radius: 28
    border.width: 1
    border.color: active ? "#1b1814" : "#ddd1bf"
    color: mouseArea.pressed ? "#efe6da" : active ? "#f2e8db" : "#fcf7ef"
    implicitHeight: Math.max(118, tileColumn.implicitHeight + 28)

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 16
        width: 5
        radius: 3
        color: active ? "#1b1814" : "#d5cab8"
    }

    Column {
        id: tileColumn
        anchors.fill: parent
        anchors.leftMargin: 30
        anchors.rightMargin: 18
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        spacing: 7

        Text {
            width: parent.width
            text: root.titleText
            color: "#1b1814"
            font.pixelSize: 29
            font.bold: true
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Text {
            visible: !!root.metaText
            width: parent.width
            text: root.metaText
            color: "#746b5d"
            font.pixelSize: 17
            font.bold: true
            font.letterSpacing: 1.0
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Text {
            visible: !!root.bodyText
            width: parent.width
            text: root.bodyText
            color: "#302c25"
            font.pixelSize: 22
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onPressed: root.forceActiveFocus()
        onClicked: root.clicked()
    }
}
