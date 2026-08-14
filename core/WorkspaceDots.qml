import QtQuick
import Quickshell.Hyprland

Row {
    id: wsDots
    
    property bool isMini: true
    property bool isShrinking: false
    property bool showingWorkspace: false
    property bool showLauncher: false
    property int currentWorkspaceId: 1
    
    spacing: 12
    
    anchors.verticalCenterOffset: (isMini && !isShrinking && showingWorkspace) ? 0 : -20
    opacity: (isMini && !isShrinking && showingWorkspace && !showLauncher) ? 1 : 0
    visible: opacity > 0
    
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
    Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
    
    Repeater {
        model: 9
        Rectangle {
            property int wsId: index + 1
            property bool isActive: wsId === wsDots.currentWorkspaceId
            property bool hasWindows: Hyprland.workspaces.values.find(w => w.id === wsId) !== undefined
            
            width: isActive ? 28 : 10
            height: 10
            radius: height / 2
            
            color: (isActive || hasWindows) ? "#ffffff" : "#444b6a"
            
            Behavior on width {
                NumberAnimation { duration: 300; easing.type: Easing.OutExpo }
            }
            Behavior on color {
                ColorAnimation { duration: 300 }
            }
        }
    }
}
