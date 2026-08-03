import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: rootSlider
    property string iconText: ""
    property real value: 0.5
    property color colorAccent: "#0db9d7"
    property color colorMuted: "#444b6a"
    property color colorFg: "#a9b1d6"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    Layout.columnSpan: 2
    Layout.fillWidth: true
    Layout.preferredHeight: 32
    
    implicitWidth: 200
    implicitHeight: 32

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Text {
            text: rootSlider.iconText
            color: rootSlider.colorAccent
            font { family: rootSlider.fontFamily; pixelSize: rootSlider.fontSize }
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 20
        }

        Slider {
            id: slider
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            value: rootSlider.value
            
            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 6
                width: slider.availableWidth
                height: implicitHeight
                radius: 3
                color: Qt.alpha(rootSlider.colorMuted, 0.5)

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    color: rootSlider.colorAccent
                    radius: 3
                }
            }

            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: slider.pressed ? Qt.lighter(rootSlider.colorAccent, 1.2) : rootSlider.colorAccent
            }
        }
    }
}
