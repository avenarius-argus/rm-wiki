import QtQuick 2.15

Rectangle {
    id: root

    property string label: ""
    property bool disabled: false
    property bool emphasized: false
    property int pixelSize: 22
    property int minimumWidth: 124

    signal clicked()

    radius: implicitHeight / 2
    implicitWidth: Math.max(minimumWidth, labelText.implicitWidth + 34)
    implicitHeight: 54
    color: disabled ? "#ded6c7" : mouseArea.pressed ? (emphasized ? "#201d18" : "#ece4d6") : emphasized ? "#151310" : "#f8f2e6"
    border.width: 1
    border.color: emphasized ? "#151310" : "#c8bfaf"

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: root.emphasized ? "#f8f2e6" : "#181815"
        font.pixelSize: root.pixelSize
        font.bold: true
        font.letterSpacing: 0.4
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: !root.disabled
        onClicked: root.clicked()
    }
}
