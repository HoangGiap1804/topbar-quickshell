import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Io
import QtQuick

PanelWindow {
    id: volumeWindow
    anchors.top: true
    anchors.left: true
    anchors.right: true
    
    implicitHeight: 140
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
    readonly property int vol: sinkReady ? Math.min(100, Math.round(sink.audio.volume * 100)) : 0
    
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
        x: (parent.width * 0.75) - (280 / 2) - 30
        y: 0
        width: 380 // 280 + 100
        height: 140
    }
    mask: isOpen ? windowRegion : emptyRegion
    
    Process { id: volumeCommand }

    RotaryDialWidget {
        id: dialWidget
        anchors.fill: parent
        isOpen: volumeWindow.isOpen
        labelText: "VOLUME"
        accentColor: "#7a42ff"
        currentValue: volumeWindow.vol
        
        onScrolled: (newVal) => {
            volumeWindow.internalChange = true
            resetTimer.restart()
            
            // Cập nhật giá trị hiển thị lập tức
            dialWidget.currentValue = newVal
            
            // Sync to system using wpctl
            volumeCommand.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (newVal / 100.0).toFixed(2)]
            volumeCommand.running = true
            
            if (volumeWindow.isOpen) osdTimer.restart()
        }
    }
}
