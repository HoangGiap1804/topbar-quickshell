import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes

import "core"
import "osd"

ShellRoot {
    id: root

    // Theme
    property color colBg: "#1a1819"
    property color colFg: "#a9b1d6"
    property color colMuted: "#444b6a"
    property color colCyan: "#0db9d7"
    property color colBlue: "#7aa2f7"
    property color colYellow: "#e0af68"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    // System data
    property int cpuUsage: 0
    property int memUsage: 0
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0
    property bool isSidebarOpen: false
    
    // Toast Notification Manager
    ToastManager {
        id: toastManager
        colBg: root.colBg
        colFg: root.colFg
        colCyan: root.colCyan
        colYellow: root.colYellow
        fontFamily: root.fontFamily
        fontSize: root.fontSize
    }
    
    function showToast(msg, type) {
        toastManager.show(msg, type);
    }
    
    signal toggleLauncher(string targetMonitor)
    
    property string focusedMonitorName: ""
    property int _fwId: Quickshell.Hyprland.focusedWorkspace ? Quickshell.Hyprland.focusedWorkspace.id : 0
    on_FwIdChanged: {
        focusedMonitorProc.running = true
    }
    
    Process {
        id: focusedMonitorProc
        command: ["bash", "-c", "hyprctl activeworkspace -j 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text.trim());
                    if (data && data.monitor) root.focusedMonitorName = data.monitor;
                } catch(e) {}
            }
        }
    }
    
    // Initialize focusedMonitorName
    Component.onCompleted: focusedMonitorProc.running = true

    Variants {
        model: Quickshell.screens
        delegate: Component {
            Scope {
                required property var modelData

                // Cửa sổ dự trữ khoảng không gian 40px ở mép trên cùng
                // Cửa sổ Overlay toàn màn hình chứa Pill
                PanelWindow {
                    id: overlay
                    screen: modelData
                    anchors.top: true
                    anchors.bottom: true
                    anchors.left: true
                    anchors.right: true
                    
                    color: "transparent"
                    WlrLayershell.exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.namespace: "quickshell-pill"
                    WlrLayershell.keyboardFocus: pill.showLauncher ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                    
                    // Không chiếm không gian của cửa sổ, pill sẽ luôn lơ lửng (overlay)
                    // Vì khi có cửa sổ pill sẽ tự động trượt lên ẩn đi nên không bị đè lên cửa sổ.
                    exclusiveZone: 0
                    
                    // Cấu hình vùng nhận diện click (Mask)
                    mask: (pill.isMini && !pill.showLauncher) ? pillRegion : fullRegion
                    
                    Region {
                        id: pillRegion
                        x: Math.floor(pill.x)
                        y: 0
                        width: Math.ceil(pill.width)
                        height: Math.ceil(Math.max(pill.y + pill.yOffset + pill.height, 10))
                    }
                    
                    // Bắt sự kiện di chuột ở viền trên cùng khi pill ẩn
                    MouseArea {
                        id: hoverTrigger
                        width: pill.width
                        height: 10
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        hoverEnabled: true
                        enabled: pill.isMini && pill.hasWindows && !pill.showLauncher
                    }
                    
                    Region {
                        id: fullRegion
                        width: overlay.width
                        height: overlay.height
                    }
                    
                    // Bắt click toàn màn hình (chỉ kích hoạt khi pill mở rộng hoặc launcher active)
                    MouseArea {
                        anchors.fill: parent
                        enabled: !pill.isMini || pill.showLauncher
                        onPressed: (mouse) => {
                            var inside = mouse.x >= pillRegion.x && mouse.x <= pillRegion.x + pillRegion.width
                                      && mouse.y >= pillRegion.y && mouse.y <= pillRegion.y + pillRegion.height;
                            if (pill.showLauncher && pill.isMini) {
                                // Đóng launcher khi click ra ngoài
                                if (!inside) {
                                    pill.showLauncher = false;
                                    pill.clearSearch();
                                    appLauncherItem.filteredApps = [];
                                }
                            } else if (!inside && !pill.minimizeAnim.running) {
                                pill.minimizeAnim.start();
                            }
                        }
                    }

                    // Hộp chứa (pill) nằm giữa (gọi từ core/DynamicPill.qml)
                    DynamicPill {
                        id: pill
                        root: root
                        appLauncherItem: appLauncherItem
                        monitorName: modelData.name
                        isTriggerHovered: hoverTrigger.containsMouse
                    }

                    // ── App Launcher cards (bên dưới pill notch) ─────────────────────────
                    AppLauncher {
                        id: appLauncherItem
                        anchors.top: parent.top
                        anchors.topMargin: pill.implicitHeight + pill.yOffset + 10
                        anchors.horizontalCenter: parent.horizontalCenter

                        opacity: pill.showLauncher ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

                        onCloseRequested: {
                            pill.showLauncher = false
                            pill.clearSearch()
                            filteredApps = []
                        }
                    }
                } // End overlay PanelWindow
                
                Connections {
                    target: root
                    function onToggleLauncher(targetMonitor) {
                        var isFocused = (targetMonitor === modelData.name);
                        
                        if (pill.showLauncher) {
                            // Đóng launcher
                            pill.showLauncher = false
                            pill.clearSearch()
                            appLauncherItem.filteredApps = []
                        } else if (isFocused) {
                            // Nếu pill đang mở → thu nhỏ trước
                            if (!pill.isMini) pill.minimizeAnim.start()
                            // Mở launcher (pill ở trạng thái mini, rộng ra, hiện search)
                            pill.showLauncher = true
                            appLauncherItem.filterApps("")
                            Qt.callLater(function() {
                                pill.clearSearch()
                            })
                        }
                    }
                }
                
                // Các OSD hiển thị dưới dạng Đĩa quay Radio, gắn với từng màn hình
                VolumeOsdWindow {
                    screen: modelData
                    isFocusedMonitor: root.focusedMonitorName === modelData.name
                }
                BrightnessOsdWindow {
                    screen: modelData
                    isFocusedMonitor: root.focusedMonitorName === modelData.name
                }
            } // End Scope
        } // End Component
    } // End Variants
    
    // ── FIFO trigger cho App Launcher ──────────────────────────────────────────
    // Hyprland: bind = SUPER, SPACE, exec, echo open > /tmp/.qs-launcher.fifo
    Process {
        id: launcherFifo
        command: ["bash", "-c",
            "mkfifo /tmp/.qs-launcher.fifo 2>/dev/null; " +
            "read line < /tmp/.qs-launcher.fifo && hyprctl activeworkspace -j 2>/dev/null"
        ]
        running: true
        onRunningChanged: { if (!running) Qt.callLater(function() { running = true }) }
        stdout: StdioCollector {
            onStreamFinished: {
                var output = this.text.trim();
                if (output === "") return;
                try {
                    var data = JSON.parse(output);
                    if (data && data.monitor) {
                        root.toggleLauncher(data.monitor);
                    }
                } catch(e) {
                    console.log("Error parsing hyprctl output:", e);
                }
            }
        }
    }
    
} // Đóng ShellRoot
