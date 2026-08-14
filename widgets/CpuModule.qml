import QtQuick
import QtQuick.Layouts

Text {
    property int usage: 0
    property color colorText: "#e0af68"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    text: "CPU: " + usage + "%"
    color: colorText
    font { family: fontFamily; pixelSize: fontSize; bold: true }
    Layout.alignment: Qt.AlignHCenter
}
