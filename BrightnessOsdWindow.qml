import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

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
    
    Brightness {
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
        x: (parent.width * 0.75) - (320 / 2)
        y: 0
        width: 320
        height: 100
    }
    mask: isOpen ? windowRegion : emptyRegion
    
    Process { id: brightnessCommand }

    LinearDialWidget {
        id: dialWidget
        x: (parent.width * 0.75) - (width / 2)
        isOpen: brightnessWindow.isOpen
        titleText: "BRIGHTNESS"
        accentColor: "#e0af68"
        currentValue: brightnessTracker.percent * 100
        
        onValueChanged: (newVal) => {
            brightnessWindow.internalChange = true
            resetTimer.restart()
            
            dialWidget.currentValue = newVal
            
            brightnessCommand.command = ["brightnessctl", "s", Math.round(newVal) + "%"]
            brightnessCommand.running = true
            
            if (brightnessWindow.isOpen) osdTimer.restart()
        }
    }
}
