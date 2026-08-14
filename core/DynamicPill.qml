import QtQuick
import QtQuick.Shapes

Item {
    id: pill
    
    property var root
    property var appLauncherItem
    
    anchors.top: parent.top
    anchors.topMargin: isMini ? 0 : 5
    anchors.horizontalCenter: parent.horizontalCenter
    
    property real yOffset: 0
    transform: Translate { y: pill.yOffset }
    
    Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
    
    property alias minimizeAnim: minimizeAnim
    property alias expandAnim: expandAnim
    
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
    
    // Workspace logic is passed down to WorkspaceDots, but we still trigger it here
    property int currentWorkspaceId: 1
    property bool _wsInitialized: false
    
    onCurrentWorkspaceIdChanged: {
        if (!_wsInitialized) {
            _wsInitialized = true;
            return;
        }
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
        if (isMini && root) {
            root.isSidebarOpen = false;
        }
    }
    
    property real contentWidth:  typeof bentoDashboard !== "undefined" ? bentoDashboard.implicitWidth  : 0
    property real contentHeight: typeof bentoDashboard !== "undefined" ? bentoDashboard.implicitHeight : 0
    
    implicitWidth: isShrinking ? 40 : (isMini ? miniWidth : contentWidth + 50)
    implicitHeight: isShrinking ? 40 : (isMini ? miniHeight : contentHeight + 60) // Căn vừa đủ kích thước lưới + PageIndicator

    Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
    Behavior on implicitHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

    NotchBackground {
        anchors.fill: parent
        opacity: pill.isMini && !pill.isShrinking ? 1 : 0
        visible: opacity > 0
        colBg: root ? root.colBg : "#1a1819"
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
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
            strokeColor: root ? Qt.alpha(root.colMuted, 0.5) : "transparent"
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

    MiniClock {
        anchors.centerIn: parent
        isMini: pill.isMini
        isShrinking: pill.isShrinking
        showingWorkspace: pill.showingWorkspace
        showLauncher: pill.showLauncher
        fontFamily: root ? root.fontFamily : "sans-serif"
    }

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
        font.family: root ? root.fontFamily : "sans-serif"
        font.pixelSize: 12; font.bold: true
        horizontalAlignment: TextInput.AlignHCenter

        Text {
            anchors.fill: parent
            text: "Search apps..."
            color: Qt.rgba(1,1,1,0.30)
            font: launcherSearchInput.font
            visible: launcherSearchInput.text.length === 0
            horizontalAlignment: Text.AlignHCenter
        }

        onTextChanged: {
            if (pill.appLauncherItem) pill.appLauncherItem.filterApps(text)
        }
        Keys.onEscapePressed: {
            pill.showLauncher = false
            text = ""
            if (pill.appLauncherItem) pill.appLauncherItem.filteredApps = []
        }
        Keys.onReturnPressed: {
            if (pill.appLauncherItem) pill.appLauncherItem.launchSelected()
        }
        Keys.onUpPressed:   { if (pill.appLauncherItem && pill.appLauncherItem.selectedIndex > 0) pill.appLauncherItem.selectedIndex-- }
        Keys.onDownPressed: { if (pill.appLauncherItem && pill.appLauncherItem.selectedIndex < pill.appLauncherItem.filteredApps.length - 1) pill.appLauncherItem.selectedIndex++ }
    }
    
    // Focus search input on show
    onShowLauncherChanged: {
        if (showLauncher) {
            launcherSearchInput.forceActiveFocus()
        }
    }
    
    // Clear search text from outside
    function clearSearch() {
        launcherSearchInput.text = ""
    }

    WorkspaceDots {
        anchors.centerIn: parent
        isMini: pill.isMini
        isShrinking: pill.isShrinking
        showingWorkspace: pill.showingWorkspace
        showLauncher: pill.showLauncher
        currentWorkspaceId: pill.currentWorkspaceId
    }

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
        
        // Pass theme properties if root is set
        colBg: root ? root.colBg : "#1a1819"
        colFg: root ? root.colFg : "#a9b1d6"
        colCyan: root ? root.colCyan : "#0db9d7"
        colBlue: root ? root.colBlue : "#7aa2f7"
        colYellow: root ? root.colYellow : "#e0af68"
        colMuted: root ? root.colMuted : "#444b6a"
        fontFamily: root ? root.fontFamily : "sans-serif"
    }
}
