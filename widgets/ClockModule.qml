import QtQuick
import QtQuick.Layouts

Text {
    property color colorText: "#7aa2f7"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14
    
    id: clockExpanded
    color: colorText
    font { family: fontFamily; pixelSize: fontSize; bold: true }
    text: Qt.formatDateTime(new Date(), "dddd, MMM dd - HH:mm")
    Layout.columnSpan: 2
    Layout.alignment: Qt.AlignHCenter
    
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockExpanded.text = Qt.formatDateTime(new Date(), "dddd, MMM dd - HH:mm")
    }
}
