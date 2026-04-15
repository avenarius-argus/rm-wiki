import QtQuick 2.15
import QtQuick.Layouts 1.15

FocusScope {
    id: root

    property alias text: inputField.text
    property string placeholderText: "Search Wikipedia"
    property bool busy: false
    readonly property bool editing: inputField.activeFocus

    signal submitted(string text)

    function dismissKeyboard() {
        inputField.focus = false;
        focusSink.forceActiveFocus();

        if (Qt.inputMethod && Qt.inputMethod.hide) {
            Qt.inputMethod.hide();
        }

        dismissTimer.restart();
    }

    function submit() {
        dismissKeyboard();
        root.submitted(root.text);
    }

    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight

    Item {
        id: focusSink
        width: 0
        height: 0
        opacity: 0
    }

    Timer {
        id: dismissTimer
        interval: 0
        repeat: false

        onTriggered: {
            inputField.focus = false;
            focusSink.forceActiveFocus();

            if (Qt.inputMethod && Qt.inputMethod.hide) {
                Qt.inputMethod.hide();
            }
        }
    }

    Rectangle {
        id: frame

        anchors.fill: parent
        radius: 30
        border.width: 1
        border.color: inputField.activeFocus ? "#1b1814" : "#d7ccb9"
        color: "#fbf7ef"
        implicitHeight: 90

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 20
                color: "#f4ede1"
                border.width: 0

                TextInput {
                    id: inputField
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    height: Math.max(52, Math.round(font.pixelSize * 1.45))
                    clip: false
                    color: "#1b1814"
                    font.pixelSize: 34
                    selectByMouse: true
                    verticalAlignment: TextInput.AlignVCenter
                    inputMethodHints: Qt.ImhNoPredictiveText
                    onAccepted: root.submit()
                    onActiveFocusChanged: {
                        if (!activeFocus && Qt.inputMethod && Qt.inputMethod.hide) {
                            Qt.inputMethod.hide();
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    visible: !inputField.text.length && !inputField.activeFocus
                    text: root.placeholderText
                    color: "#857b6d"
                    font.pixelSize: 30
                }
            }

            InkButton {
                Layout.preferredWidth: 154
                Layout.fillHeight: true
                label: root.busy ? "Wait" : "Search"
                emphasized: true
                disabled: root.busy
                minimumWidth: 154
                pixelSize: 20
                onClicked: root.submit()
            }
        }
    }
}
