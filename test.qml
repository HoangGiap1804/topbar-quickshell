import QtQuick
import Quickshell
import Quickshell.Hyprland

ShellRoot {
    Timer {
        interval: 1000
        running: true
        onTriggered: {
            var monitors = Hyprland.monitors.values;
            console.log("Monitors count:", monitors.length);
            for (var i = 0; i < monitors.length; i++) {
                var m = monitors[i];
                console.log("Monitor:", m.name, "activeWorkspace id:", m.activeWorkspace ? m.activeWorkspace.id : "null");
            }
            Qt.quit()
        }
    }
}
