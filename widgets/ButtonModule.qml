import QtQuick
import QtQuick.Layouts

Rectangle {
    property string text: "Button"
    property color colorText: "#1a1b26"
    property color colorBg: "#0db9d7"
    property color colorHover: "#7aa2f7"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14
    
    signal clicked()

    Layout.alignment: Qt.AlignHCenter
    Layout.columnSpan: 2
    Layout.fillWidth: true
    Layout.preferredHeight: 32
    
    implicitWidth: 120
    implicitHeight: 32
    radius: 8
    color: mouseArea.containsMouse ? colorHover : Qt.alpha(colorBg, 0.8)
    Behavior on color { ColorAnimation { duration: 150 } }

    Text {
        anchors.centerIn: parent
        text: parent.text
        color: parent.colorText
        font { family: parent.fontFamily; pixelSize: parent.fontSize; bold: true }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            parent.clicked()
        }
    }
}
