import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Io
import QtQuick
import "../widgets"

PanelWindow {
    id: volumeWindow
    anchors.top: true
    anchors.left: true
    anchors.right: true
    
    implicitHeight: 20
    color: "transparent"
    
    exclusiveZone: 0
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "volume-osd"
    
    property bool isOpen: false
    property bool internalChange: false
    
    // Pipewire logic
    property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: sink && sink.ready
    readonly property int vol: sinkReady ? Math.min(500, Math.round(sink.audio.volume * 100)) : 0
    
    PwObjectTracker {
        objects: [volumeWindow.sink]
    }
    
    onVolChanged: {
        if (internalChange) return;
        
        dialWidget.currentValue = vol
        osdTimer.restart()
    }
    
    Timer {
        id: osdTimer
        interval: 2500
        repeat: false
        onTriggered: volumeWindow.isOpen = false
        onRunningChanged: if (running) volumeWindow.isOpen = true
    }
    
    Timer {
        id: resetTimer
        interval: 100
        onTriggered: volumeWindow.internalChange = false
    }
    
    Region { id: emptyRegion }
    Region {
        id: windowRegion
        x: (volumeWindow.width * 0.75) - (320 / 2)
        y: 0
        width: 320
        height: 20
    }
    mask: isOpen ? windowRegion : emptyRegion
    
    Process { id: volumeCommand }

    LinearDialWidget {
        id: dialWidget
        x: (volumeWindow.width * 0.75) - (width / 2)
        isOpen: volumeWindow.isOpen
        titleText: "VOLUME"
        accentColor: "#7a42ff"
        maxValue: 500
        currentValue: volumeWindow.vol
        
        onValueChanged: (newVal) => {
            volumeWindow.internalChange = true
            resetTimer.restart()
            
            dialWidget.currentValue = newVal
            
            volumeCommand.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (newVal / 100.0).toFixed(2)]
            volumeCommand.running = true
            
            if (volumeWindow.isOpen) osdTimer.restart()
        }
    }
}
