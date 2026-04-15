import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root

    property alias text: inputField.text
    property string placeholderText: "Search Wikipedia"
    property bool busy: false

    signal submitted(string text)

    function dismissKeyboard() {
        inputField.focus = false;
        if (Qt.inputMethod && Qt.inputMethod.hide) {
            Qt.inputMethod.hide();
        }
    }

    function submit() {
        dismissKeyboard();
        root.submitted(root.text);
    }

    radius: 28
    border.width: 1
    border.color: inputField.activeFocus ? "#181815" : "#d1c6b5"
    color: "#fbf6eb"
    implicitHeight: 84

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 18
            color: "#f8f2e6"
            border.width: 0

            TextInput {
                id: inputField
                anchors.fill: parent
                anchors.margins: 18
                clip: true
                color: "#181815"
                font.pixelSize: 32
                selectByMouse: true
                verticalAlignment: TextInput.AlignVCenter
                inputMethodHints: Qt.ImhNoPredictiveText
                Keys.onReturnPressed: root.submit()
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 18
                visible: !inputField.text.length && !inputField.activeFocus
                text: root.placeholderText
                color: "#817869"
                font.pixelSize: 30
            }
        }

        InkButton {
            Layout.preferredWidth: 150
            Layout.fillHeight: true
            label: root.busy ? "WAIT" : "SEARCH"
            emphasized: true
            disabled: root.busy
            minimumWidth: 150
            pixelSize: 19
            onClicked: root.submit()
        }
    }
}
