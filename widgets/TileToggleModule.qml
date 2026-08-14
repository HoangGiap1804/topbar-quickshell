import QtQuick
import QtQuick.Layouts

Rectangle {
    id: rootTile
    property string text: "Toggle"
    property string iconText: "󰤨"
    property bool isOn: false
    
    signal expandClicked()
    
    // Màu sắc
    property color colorText: "#1a1b26"
    property color colorTextOff: "#a9b1d6"
    property color colorActive: "#0db9d7"
    property color colorInactive: "#16161e"
    property color colorHover: Qt.lighter(colorInactive, 1.2)
    
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    Layout.fillWidth: true
    Layout.preferredHeight: 64
    
    implicitWidth: 250
    implicitHeight: 64
    radius: 12
    
    color: mouseArea.containsMouse ? (isOn ? Qt.lighter(colorActive, 1.1) : colorHover) : (isOn ? colorActive : colorInactive)
    Behavior on color { ColorAnimation { duration: 150 } }
    
    // Viền kính
    border.color: Qt.alpha("#ffffff", 0.05)
    border.width: 1

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            rootTile.isOn = !rootTile.isOn
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        
        // Icon bên trái
        Rectangle {
            width: 32
            height: 32
            radius: 16
            color: rootTile.isOn ? "#ffffff" : "#2a2c3f"
            Layout.alignment: Qt.AlignVCenter
            
            Text {
                anchors.centerIn: parent
                text: rootTile.iconText
                color: rootTile.isOn ? rootTile.colorActive : rootTile.colorTextOff
                font { family: rootTile.fontFamily; pixelSize: rootTile.fontSize; bold: true }
            }
        }
        
        // Tên ở giữa
        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: rootTile.text
            color: rootTile.isOn ? rootTile.colorText : rootTile.colorTextOff
            font { family: rootTile.fontFamily; pixelSize: rootTile.fontSize - 2; bold: true }
        }
        
        // Nút mũi tên bên phải
        Rectangle {
            width: 32
            height: 32
            radius: 16
            color: arrowMouseArea.containsMouse ? Qt.alpha("#ffffff", 0.2) : "transparent"
            Layout.alignment: Qt.AlignVCenter
            
            Text {
                anchors.centerIn: parent
                text: "" // Nerd Font right arrow
                color: rootTile.isOn ? rootTile.colorText : rootTile.colorTextOff
                font { family: rootTile.fontFamily; pixelSize: rootTile.fontSize; bold: true }
            }
            
            MouseArea {
                id: arrowMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                // Prevent click from propagating to the main toggle
                propagateComposedEvents: false
                onClicked: (mouse) => {
                    mouse.accepted = true
                    rootTile.expandClicked()
                }
            }
        }
    }
}
