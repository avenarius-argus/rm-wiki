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
    implicitWidth: Math.max(minimumWidth, labelText.implicitWidth + 38)
    implicitHeight: 58
    color: disabled ? "#ddd4c7" : mouseArea.pressed ? (emphasized ? "#26211a" : "#ece3d6") : emphasized ? "#1c1813" : "#f6efe3"
    border.width: 1
    border.color: emphasized ? "#1c1813" : "#cdc2b1"

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: root.emphasized ? "#f8f2e6" : "#1b1814"
        font.pixelSize: root.pixelSize
        font.bold: true
        font.letterSpacing: 0.2
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: !root.disabled
        onPressed: root.forceActiveFocus()
        onClicked: root.clicked()
    }
}
