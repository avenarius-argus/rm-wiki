import QtQuick 2.15

Rectangle {
    id: root

    property string label: ""
    property bool disabled: false
    property bool emphasized: false
    property int pixelSize: 24

    signal clicked()

    radius: 16
    implicitWidth: Math.max(180, labelText.implicitWidth + 36)
    implicitHeight: 58
    color: disabled ? "#d9d4c8" : mouseArea.pressed ? (emphasized ? "#23231e" : "#d8d1c3") : emphasized ? "#181815" : "#f4f1e7"
    border.width: 1
    border.color: emphasized ? "#181815" : "#575248"

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: root.emphasized ? "#f4f1e7" : "#181815"
        font.pixelSize: root.pixelSize
        font.bold: true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: !root.disabled
        onClicked: root.clicked()
    }
}

