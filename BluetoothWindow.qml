import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: bluetoothWindow
    
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    
    color: "transparent"
    
    exclusiveZone: 0
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "bluetooth-window"
    
    property bool isOpen: false
    visible: isOpen || yAnim.running
    
    Region { id: emptyRegion }
    Region {
        id: windowRegion
        x: contentItem.x
        y: contentItem.y
        width: contentItem.width
        height: contentItem.height
    }
    mask: isOpen ? windowRegion : emptyRegion
    
    Rectangle {
        id: contentItem
        width: 300
        height: 400
        
        x: (parent.width / 2) + 216
        
        // Căn mép trên bằng với mép trên của Pill lớn (cách trần 5px)
        property real targetY: 5
        y: isOpen ? targetY : -height
        
        Behavior on y {
            NumberAnimation { id: yAnim; duration: 250; easing.type: Easing.OutQuint }
        }
        
        color: "#16161e"
        radius: 12
        border.color: Qt.alpha("#ffffff", 0.1)
        clip: true
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16
            
            Text {
                text: "Bluetooth Devices"
                color: "#ffffff"
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 18; bold: true }
            }
            Text {
                text: "Chưa có thiết bị nào kết nối."
                color: "#a9b1d6"
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 14 }
            }
            Item { Layout.fillHeight: true }
        }
    }
}
