import QtQuick

Text {
    id: miniClock
    
    property bool isMini: true
    property bool isShrinking: false
    property bool showingWorkspace: false
    property bool showLauncher: false
    
    property string fontFamily: "JetBrainsMono Nerd Font"
    
    anchors.verticalCenterOffset: {
        if (isMini && !isShrinking) {
            if (showingWorkspace) return -20
            if (showLauncher) return -20
            return 0
        }
        return 0
    }
    
    color: "#ffffff"
    font { family: miniClock.fontFamily; pixelSize: 12; bold: true }
    opacity: (isMini && !isShrinking && !showingWorkspace && !showLauncher) ? 1 : 0
    visible: opacity > 0
    
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
    Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
    
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: miniClock.text = Qt.formatDateTime(new Date(), "HH:mm")
    }
    
    Component.onCompleted: miniClock.text = Qt.formatDateTime(new Date(), "HH:mm")
}
