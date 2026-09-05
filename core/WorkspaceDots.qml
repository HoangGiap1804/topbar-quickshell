import QtQuick
import Quickshell.Hyprland

Row {
    id: wsDots
    
    property bool isMini: true
    property bool isShrinking: false
    property bool showingWorkspace: false
    property bool showLauncher: false
    property int currentWorkspaceId: 1
    property var monitorWorkspaces: []
    
    spacing: 12
    
    anchors.verticalCenterOffset: (isMini && !isShrinking && showingWorkspace) ? 0 : -20
    opacity: (isMini && !isShrinking && showingWorkspace && !showLauncher) ? 1 : 0
    visible: opacity > 0
    
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
    Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
    
    Repeater {
        model: wsDots.monitorWorkspaces
        Rectangle {
            property int wsId: modelData.id
            property bool isActive: wsId === wsDots.currentWorkspaceId
            property bool hasWindows: modelData.windows > 0
            
            width: isActive ? 24 : 16
            height: 16
            radius: height / 2
            
            color: (isActive || hasWindows) ? "#ffffff" : "#444b6a"
            
            Text {
                anchors.centerIn: parent
                text: (parent.wsId - 1) % 10 + 1
                color: (parent.isActive || parent.hasWindows) ? "#1a1819" : "#ffffff"
                font.family: "sans-serif"
                font.pixelSize: 10
                font.bold: true
            }
            
            Behavior on width {
                NumberAnimation { duration: 300; easing.type: Easing.OutExpo }
            }
            Behavior on color {
                ColorAnimation { duration: 300 }
            }
        }
    }
}
