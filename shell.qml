import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes

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

    // Cửa sổ dự trữ khoảng không gian 40px ở mép trên cùng
    PanelWindow {
        id: reserve
        anchors.top: true
        anchors.left: true
        anchors.right: true
        
        implicitHeight: 25
        color: "transparent"
        
        exclusiveZone: 20
        WlrLayershell.layer: WlrLayer.Top
        
        // Không nhận click
        mask: Region {}
    }

    // Cửa sổ Overlay toàn màn hình chứa Pill
    PanelWindow {
        id: overlay
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        
        color: "transparent"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-pill"
        WlrLayershell.keyboardFocus: pill.showLauncher ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        
        // Cấu hình vùng nhận diện click (Mask)
        mask: (pill.isMini && !pill.showLauncher) ? pillRegion : fullRegion
        
        Region {
            id: pillRegion
            x: Math.floor(pill.x)
            y: Math.floor(pill.y)
            width: Math.ceil(pill.width)
            height: Math.ceil(pill.height)
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
                        launcherSearchInput.text = "";
                        appLauncherItem.filteredApps = [];
                    }
                } else if (!inside && !minimizeAnim.running) {
                    minimizeAnim.start();
                }
            }
        }

        // Hộp chứa (pill) nằm giữa
        Item {
            id: pill
            anchors.top: parent.top
            anchors.topMargin: isMini ? 0 : 5
            anchors.horizontalCenter: parent.horizontalCenter
            
            property real yOffset: 0
            transform: Translate { y: pill.yOffset }
            
            Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
            
            SequentialAnimation {
                id: minimizeAnim
                
                // 1. Fade out nội dung trước
                ScriptAction { script: { pill.isFadingOut = true } }
                PauseAnimation { duration: 150 } // Chờ dashboard fade out xong
                
                // 2. Thu nhỏ thành hình vuông đen nhỏ
                ScriptAction { script: { pill.isShrinking = true } }
                
                // 3. Chờ thu nhỏ
                PauseAnimation { duration: 200 }
                
                // 4. Trượt lên khỏi màn hình
                NumberAnimation { 
                    target: pill; property: "yOffset"; 
                    to: -(pill.height + 50); 
                    duration: 250; easing.type: Easing.InBack 
                }
                
                // 5. Chuyển sang trạng thái notch
                ScriptAction { script: { pill.isMini = true; pill.isShrinking = false; pill.isFadingOut = false; pill.showLauncher = false } }
                
                // 6. Đặt vị trí chuẩn bị trượt xuống
                PropertyAction { target: pill; property: "yOffset"; value: -pill.miniHeight - 50 }
                PauseAnimation { duration: 20 }
                
                // 7. Từ từ trượt xuống
                NumberAnimation { 
                    target: pill; property: "yOffset"; 
                    to: 0; 
                    duration: 400; easing.type: Easing.OutExpo 
                }
            }
            
            SequentialAnimation {
                id: expandAnim
                ScriptAction { script: { pill.isExpanding = true; pill.isMini = false } }
                PauseAnimation { duration: 300 }
                ScriptAction { script: { pill.isExpanding = false } }
            }

            property bool isMini: true
            property bool isShrinking: false
            property bool isFadingOut: false
            property bool isExpanding: false
            property bool showLauncher: false
            property bool showingWorkspace: false
            property int currentWorkspaceId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
            property bool _wsInitialized: false
            
            onCurrentWorkspaceIdChanged: {
                if (!_wsInitialized) {
                    _wsInitialized = true;
                    return;
                }
                // Chỉ hiển thị OSD workspace nếu đang ở chế độ notch
                if (isMini && !isShrinking) {
                    showingWorkspace = true;
                    wsTimer.restart();
                }
            }
            
            Timer {
                id: wsTimer
                interval: 1500
                onTriggered: pill.showingWorkspace = false
            }

            property real miniWidth: pill.showLauncher ? 300 : (showingWorkspace ? 240 : 100)
            property real miniHeight: 20 // Chiều cao khi thu nhỏ (notch)
            
            onIsMiniChanged: {
                if (isMini) {
                    root.isSidebarOpen = false;
                }
            }
            property real contentWidth:  typeof bentoDashboard !== "undefined" ? bentoDashboard.implicitWidth  : 0
            property real contentHeight: typeof bentoDashboard !== "undefined" ? bentoDashboard.implicitHeight : 0
            
            implicitWidth: isShrinking ? 40 : (isMini ? miniWidth : contentWidth + 50)
            implicitHeight: isShrinking ? 40 : (isMini ? miniHeight : contentHeight + 60) // Căn vừa đủ kích thước lưới + PageIndicator

            Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
            Behavior on implicitHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

            // Nền thu nhỏ (Notch)
            Shape {
                id: notchBg
                anchors.fill: parent
                opacity: pill.isMini && !pill.isShrinking ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                
                property real slant: 2 // Độ nghiêng (càng lớn thì cạnh càng vát chéo vào trong)
                property real flare: 18 // Độ cong của góc
                
                ShapePath {
                    fillGradient: RadialGradient {
                        centerX: notchBg.width / 2; centerY: 0
                        centerRadius: notchBg.width / 4
                        focalX: notchBg.width / 2; focalY: 0
                        GradientStop { position: 0.0; color: "#260b41" }
                        GradientStop { position: 1.0; color: "#000000" }
                    }
                    strokeColor: Qt.alpha(root.colMuted, 0.5)
                    strokeWidth: 1
                    
                    startX: -notchBg.flare; startY: 0
                    
                    // Cạnh trái uốn cong chữ S (từ mép trên xuống đáy)
                    PathCubic { 
                        x: notchBg.slant + notchBg.flare; y: notchBg.height
                        control1X: 0; control1Y: 0
                        control2X: notchBg.slant; control2Y: notchBg.height
                    }
                    
                    // Đường thẳng đáy
                    PathLine { x: notchBg.width - notchBg.slant - notchBg.flare; y: notchBg.height }
                    
                    // Cạnh phải uốn cong chữ S (từ đáy lên mép trên)
                    PathCubic {
                        x: notchBg.width + notchBg.flare; y: 0
                        control1X: notchBg.width - notchBg.slant; control1Y: notchBg.height
                        control2X: notchBg.width; control2Y: 0
                    }
                    
                    // Đường thẳng mép trên (đóng hình)
                    PathLine { x: -notchBg.flare; y: 0 }
                }
            }

            // Nền khối cầu khi thu nhỏ
            Rectangle {
                id: shrinkBg
                anchors.fill: parent
                radius: width / 2
                color: "#000000"
                opacity: pill.isShrinking ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            // Nền mở rộng (Floating Pill)
            Shape {
                id: pillBg
                anchors.fill: parent
                opacity: (pill.isMini && !pill.isShrinking) || pill.isShrinking ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutExpo } }
                
                ShapePath {
                    fillColor: Qt.alpha("#000000", 0.8)
                    strokeColor: Qt.alpha(root.colMuted, 0.5)
                    strokeWidth: 1
                    
                    startX: 15; startY: 0
                    PathLine { x: pillBg.width - 15; y: 0 }
                    PathQuad { x: pillBg.width; y: 15; controlX: pillBg.width; controlY: 0 }
                    PathLine { x: pillBg.width; y: pillBg.height - 15 }
                    PathQuad { x: pillBg.width - 15; y: pillBg.height; controlX: pillBg.width; controlY: pillBg.height }
                    PathLine { x: 15; y: pillBg.height }
                    PathQuad { x: 0; y: pillBg.height - 15; controlX: 0; controlY: pillBg.height }
                    PathLine { x: 0; y: 15 }
                    PathQuad { x: 15; y: 0; controlX: 0; controlY: 0 }
                }
            }

            // Icon đồng hồ khi thu nhỏ
            Text {
                id: clockExpanded
                anchors.centerIn: parent
                anchors.verticalCenterOffset: {
                    if (pill.isMini && !pill.isShrinking) {
                        if (pill.showingWorkspace) return -20
                        if (pill.showLauncher) return -20
                        return 0
                    }
                    return 0
                }
                
                color: "#ffffff"
                font { family: root.fontFamily; pixelSize: 12; bold: true }
                opacity: (pill.isMini && !pill.isShrinking && !pill.showingWorkspace && !pill.showLauncher) ? 1 : 0
                visible: opacity > 0
                
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                
                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clockExpanded.text = Qt.formatDateTime(new Date(), "HH:mm")
                }
            }

            // Search input (hiện khi launcher active thay cho đồng hồ)
            TextInput {
                id: launcherSearchInput
                anchors.centerIn: parent
                anchors.verticalCenterOffset: (pill.isMini && pill.showLauncher) ? 0 : -20
                width: pill.miniWidth - 24
                
                opacity: (pill.isMini && pill.showLauncher) ? 1 : 0
                visible: opacity > 0
                
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                
                color: "#c0caf5"
                font.family: root.fontFamily; font.pixelSize: 12; font.bold: true
                horizontalAlignment: TextInput.AlignHCenter

                Text {
                    anchors.fill: parent
                    text: "Search apps..."
                    color: Qt.rgba(1,1,1,0.30)
                    font: launcherSearchInput.font
                    visible: launcherSearchInput.text.length === 0
                    horizontalAlignment: Text.AlignHCenter
                }

                onTextChanged: appLauncherItem.filterApps(text)
                Keys.onEscapePressed: {
                    pill.showLauncher = false
                    text = ""
                    appLauncherItem.filteredApps = []
                }
                Keys.onReturnPressed: appLauncherItem.launchSelected()
                Keys.onUpPressed:   { if (appLauncherItem.selectedIndex > 0) appLauncherItem.selectedIndex-- }
                Keys.onDownPressed: { if (appLauncherItem.selectedIndex < appLauncherItem.filteredApps.length - 1) appLauncherItem.selectedIndex++ }
            }

            // Workspace dots
            Row {
                id: wsDots
                anchors.centerIn: parent
                anchors.verticalCenterOffset: (pill.isMini && !pill.isShrinking && pill.showingWorkspace) ? 0 : -20
                spacing: 12
                
                opacity: (pill.isMini && !pill.isShrinking && pill.showingWorkspace && !pill.showLauncher) ? 1 : 0
                visible: opacity > 0
                
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                
                Repeater {
                    model: 9
                    Rectangle {
                        property int wsId: index + 1
                        property bool isActive: wsId === pill.currentWorkspaceId
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

            // Xử lý click để phóng to (chỉ khi pill mini VÀ không phải launcher)
            MouseArea {
                anchors.fill: parent
                cursorShape: (pill.isMini && !pill.showLauncher) ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: pill.isMini && !pill.showLauncher
                onClicked: { if (!expandAnim.running) expandAnim.start() }
            }

            BentoDashboard {
                id: bentoDashboard
                anchors.centerIn: parent
                
                opacity: (pill.isMini || pill.isShrinking || pill.isFadingOut || pill.isExpanding) ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                
                // Pass theme properties
                colBg: root.colBg
                colFg: root.colFg
                colCyan: root.colCyan
                colBlue: root.colBlue
                colYellow: root.colYellow
                colMuted: root.colMuted
                fontFamily: root.fontFamily
            }
        }

        // ── App Launcher cards (bên dưới pill notch) ─────────────────────────
        AppLauncher {
            id: appLauncherItem
            anchors.top: parent.top
            anchors.topMargin: pill.miniHeight + pill.yOffset + 10
            anchors.horizontalCenter: parent.horizontalCenter

            opacity: pill.showLauncher ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

            onCloseRequested: {
                pill.showLauncher = false
                launcherSearchInput.text = ""
                filteredApps = []
            }
        }
    }
    
    // ── FIFO trigger cho App Launcher ──────────────────────────────────────────
    // Hyprland: bind = SUPER, SPACE, exec, echo open > /tmp/.qs-launcher.fifo
    Process {
        id: launcherFifo
        command: ["bash", "-c",
            "mkfifo /tmp/.qs-launcher.fifo 2>/dev/null; " +
            "read line < /tmp/.qs-launcher.fifo && echo \"$line\""
        ]
        running: true
        onRunningChanged: { if (!running) Qt.callLater(function() { running = true }) }
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() === "") return
                if (pill.showLauncher) {
                    // Đóng launcher
                    pill.showLauncher = false
                    launcherSearchInput.text = ""
                    appLauncherItem.filteredApps = []
                } else {
                    // Nếu pill đang mở → thu nhỏ trước
                    if (!pill.isMini) minimizeAnim.start()
                    // Mở launcher (pill ở trạng thái mini, rộng ra, hiện search)
                    pill.showLauncher = true
                    appLauncherItem.filterApps("")
                    Qt.callLater(function() {
                        launcherSearchInput.text = ""
                        launcherSearchInput.forceActiveFocus()
                    })
                }
            }
        }
    }

    // Các OSD hiển thị dưới dạng Đĩa quay Radio
    VolumeOsdWindow {}
    BrightnessOsdWindow {}
    
} // Đóng ShellRoot
