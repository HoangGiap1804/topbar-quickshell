import QtQuick
import Quickshell
import Quickshell.Hyprland

ShellRoot {
    Timer {
        interval: 1000
        running: true
        onTriggered: {
            var fw = Hyprland.focusedWorkspace;
            if (fw) {
                var ws = Hyprland.workspaces.values.find(w => w.id === fw.id);
                if (ws) {
                    console.log("Monitor for active workspace:", ws.monitor ? ws.monitor.name : "null");
                }
            }
            Qt.quit()
        }
    }
}
