import QtQuick
import QtQuick.Layouts

Text {
    property int usage: 0
    property color colorText: "#0db9d7"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    text: "Mem: " + usage + "%"
    color: colorText
    font { family: fontFamily; pixelSize: fontSize; bold: true }
    Layout.alignment: Qt.AlignHCenter
}
