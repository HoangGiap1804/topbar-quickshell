import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "ChillPill-Shell/qml" as ChillPill

PanelWindow {
    id: brightnessWindow
    anchors.top: true
    anchors.left: true
    anchors.right: true
    
    implicitHeight: 140
    color: "transparent"
    
    exclusiveZone: 0
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "brightness-osd"
    
    property bool isOpen: false
    property bool internalChange: false
    
    ChillPill.Brightness {
        id: brightnessTracker
        visible: false
        onBrightnessUpdated: {
            if (internalChange) return;
            dialWidget.currentValue = brightnessTracker.percent * 100
            osdTimer.restart()
        }
    }
    
    Timer {
        id: osdTimer
        interval: 2500
        repeat: false
        onTriggered: brightnessWindow.isOpen = false
        onRunningChanged: if (running) brightnessWindow.isOpen = true
    }
    
    Timer {
        id: resetTimer
        interval: 100
        onTriggered: brightnessWindow.internalChange = false
    }
    
    Region { id: emptyRegion }
    Region {
        id: windowRegion
        x: (parent.width * 0.75) - (280 / 2) - 30
        y: 0
        width: 380 // 280 + 100
        height: 140
    }
    mask: isOpen ? windowRegion : emptyRegion
    
    Process { id: brightnessCommand }

    RotaryDialWidget {
        id: dialWidget
        anchors.fill: parent
        isOpen: brightnessWindow.isOpen
        labelText: "BRIGHTNESS"
        accentColor: "#e0af68"
        currentValue: brightnessTracker.percent * 100
        
        onScrolled: (newVal) => {
            brightnessWindow.internalChange = true
            resetTimer.restart()
            
            // Cập nhật giá trị hiển thị lập tức
            dialWidget.currentValue = newVal
            
            // Sync to system using brightnessctl
            brightnessCommand.command = ["brightnessctl", "s", Math.round(newVal) + "%"]
            brightnessCommand.running = true
            
            if (brightnessWindow.isOpen) osdTimer.restart()
        }
    }
}
