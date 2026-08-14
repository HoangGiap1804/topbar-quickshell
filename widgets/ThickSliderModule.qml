import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: rootSlider
    property string iconText: ""
    property real value: 0.5
    property color colorAccent: "#0db9d7"
    property color colorBg: "#16161e" 
    property color colorFg: "#ffffff"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 18

    Layout.fillWidth: true
    Layout.preferredHeight: 48
    
    implicitWidth: 200
    implicitHeight: 48

    Slider {
        id: slider
        anchors.fill: parent
        value: rootSlider.value
        
        onValueChanged: {
            if (slider.pressed) {
                rootSlider.value = slider.value
            }
        }
        
        Connections {
            target: rootSlider
            function onValueChanged() {
                if (!slider.pressed) {
                    slider.value = rootSlider.value
                }
            }
        }

        background: Rectangle {
            anchors.fill: parent
            radius: 12
            color: rootSlider.colorBg
            clip: true
            
            // Viền nhẹ cho cảm giác kính
            border.color: Qt.alpha("#ffffff", 0.05)
            border.width: 1

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                color: rootSlider.colorAccent
                radius: parent.radius
            }

            Text {
                x: 16
                anchors.verticalCenter: parent.verticalCenter
                text: rootSlider.iconText
                color: (slider.visualPosition * parent.width) > x + width / 2 ? "#1a1b26" : rootSlider.colorFg
                font { family: rootSlider.fontFamily; pixelSize: rootSlider.fontSize; bold: true }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(slider.value * 100)
                color: (slider.visualPosition * parent.width) > (parent.width - 30) ? "#1a1b26" : rootSlider.colorFg
                font { family: rootSlider.fontFamily; pixelSize: rootSlider.fontSize - 4; bold: true }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        handle: Item {}
    }
}
