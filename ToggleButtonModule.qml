import QtQuick
import QtQuick.Layouts

Rectangle {
    property string text: "Toggle"
    property bool isOn: false
    property color colorText: "#1a1b26"
    property color colorTextOff: "#a9b1d6"
    property color colorActive: "#0db9d7"
    property color colorInactive: "#444b6a"
    property color colorHover: "#7aa2f7"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    Layout.alignment: Qt.AlignHCenter
    Layout.fillWidth: true
    Layout.preferredHeight: 36
    
    implicitWidth: 100
    implicitHeight: 36
    radius: 10
    
    color: mouseArea.containsMouse ? colorHover : (isOn ? Qt.alpha(colorActive, 0.9) : Qt.alpha(colorInactive, 0.4))
    Behavior on color { ColorAnimation { duration: 150 } }

    Text {
        anchors.centerIn: parent
        text: parent.text
        color: parent.isOn ? parent.colorText : parent.colorTextOff
        font { family: parent.fontFamily; pixelSize: parent.fontSize; bold: true }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            isOn = !isOn
        }
    }
}
