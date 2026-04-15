import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root

    property alias text: inputField.text
    property string placeholderText: "Search Wikipedia"
    property bool busy: false

    signal submitted(string text)

    radius: 18
    border.width: 1
    border.color: "#5d574d"
    color: "#fcfaf3"
    implicitHeight: 74

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: "#f7f4eb"
            border.width: 0

            TextInput {
                id: inputField
                anchors.fill: parent
                anchors.margins: 14
                clip: true
                color: "#181815"
                font.pixelSize: 28
                selectByMouse: true
                verticalAlignment: TextInput.AlignVCenter
                inputMethodHints: Qt.ImhNoPredictiveText
                Keys.onReturnPressed: root.submitted(text)
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 14
                visible: !inputField.text.length && !inputField.activeFocus
                text: root.placeholderText
                color: "#757064"
                font.pixelSize: 28
            }
        }

        InkButton {
            Layout.preferredWidth: 164
            Layout.fillHeight: true
            label: root.busy ? "Working" : "Search"
            emphasized: true
            disabled: root.busy
            onClicked: root.submitted(root.text)
        }
    }
}

