import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Services.UPower
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../osd" as Osd

import "../widgets"

Item {
    id: rootDashboard
    implicitWidth: gridLayout.implicitWidth
    implicitHeight: gridLayout.implicitHeight

    // System properties from parent root
    property color colBg: "#1a1819"
    property color colFg: "#a9b1d6"
    property color colCyan: "#0db9d7"
    property color colBlue: "#7aa2f7"
    property color colYellow: "#e0af68"
    property color colMuted: "#444b6a"
    property string fontFamily: "JetBrainsMono Nerd Font"
    // Custom background image for the cards (set to any file:// or http:// URL)
    property string cardBackgroundImage: "/home/nqim/.dotfiles/wallpapers/wallpaper2.jpg"

    component BentoCard: Item {
        id: cardRoot
        property int rowSpan: 1
        property int colSpan: 1
        
        // Redirect children into the content container
        default property alias contentData: contentContainer.data
        
        Layout.rowSpan: rowSpan
        Layout.columnSpan: colSpan
        Layout.fillWidth: true
        Layout.fillHeight: true
        
        Layout.minimumWidth: colSpan * 120 + (colSpan - 1) * 20
        Layout.minimumHeight: rowSpan * 120 + (rowSpan - 1) * 20

        // Content container — everything inside gets clipped to rounded corners
        Item {
            id: contentContainer
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                maskSource: ShaderEffectSource {
                    sourceItem: Rectangle {
                        width: contentContainer.width
                        height: contentContainer.height
                        radius: 28
                    }
                    hideSource: true
                }
            }

            // Background image slice
            Image {
                source: rootDashboard.cardBackgroundImage
                visible: rootDashboard.cardBackgroundImage !== ""
                width: gridLayout.width
                height: gridLayout.height
                x: -cardRoot.x
                y: -cardRoot.y
                fillMode: Image.PreserveAspectCrop
                z: -2
            }

            // Translucent dark overlay
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0.08, 0.08, 0.12, 0.75)
                z: -1
                radius: 28
            }
        }

        // Border drawn on top (not affected by mask)
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: 28
            border.color: Qt.alpha(colMuted, 0.4)
            border.width: 1
        }
    }

    GridLayout {
        id: gridLayout
        anchors.centerIn: parent
        columns: 4
        rowSpacing: 20
        columnSpacing: 20
        
        // --- Row 1 ---
        // Wi-Fi (1x1)
        BentoCard {
            id: wifiCard
            colSpan: 1; rowSpan: 1
            
            property string wifiName: "Disconnected"
            
            Timer {
                interval: 5000
                running: true
                repeat: true
                onTriggered: wifiProc.running = true
            }
            Component.onCompleted: wifiProc.running = true
            
            Process {
                id: wifiProc
                command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        var val = this.text.trim();
                        wifiCard.wifiName = val !== "" ? val : "Disconnected";
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 12
                Rectangle {
                    width: 56; height: 56; radius: 28; color: wifiCard.wifiName !== "Disconnected" ? colBlue : Qt.alpha(colMuted, 0.5)
                    anchors.horizontalCenter: parent.horizontalCenter
                    Text { anchors.centerIn: parent; text: "󰤨"; color: "#fff"; font.family: rootDashboard.fontFamily; font.pixelSize: 28 }
                }
                MarqueeText { 
                    text: wifiCard.wifiName
                    color: colFg
                    fontFamily: rootDashboard.fontFamily
                    pixelSize: 12
                    bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 100
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
        
        // Bluetooth (1x1)
        BentoCard {
            id: btCard
            colSpan: 1; rowSpan: 1
            
            property bool btEnabled: typeof Bluetooth !== "undefined" && Bluetooth && Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
            property var btDevices: typeof Bluetooth !== "undefined" && Bluetooth ? Bluetooth.devices.values : []
            property string btName: {
                if (!btEnabled) return "Off";
                for (var i = 0; i < btDevices.length; i++) {
                    if (btDevices[i].connected) return btDevices[i].name;
                }
                return "On";
            }

            Column {
                anchors.centerIn: parent
                spacing: 12
                Rectangle {
                    width: 56; height: 56; radius: 28; color: btCard.btEnabled ? colCyan : Qt.alpha(colMuted, 0.5)
                    anchors.horizontalCenter: parent.horizontalCenter
                    Text { anchors.centerIn: parent; text: "󰂯"; color: "#fff"; font.family: rootDashboard.fontFamily; font.pixelSize: 28 }
                }
                MarqueeText { 
                    text: btCard.btName
                    color: colFg
                    fontFamily: rootDashboard.fontFamily
                    pixelSize: 12
                    bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 100
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
        
        // System Stats (2x1)
        BentoCard {
            id: sysStatsCard
            colSpan: 2; rowSpan: 1
            
            property int cpuVal: 0
            property string ramValStr: "0.0GB"
            property real ramRatio: 0
            property string tempValStr: "0°C"
            property real tempRatio: 0
            property real prevCpuTotal: 0
            property real prevCpuIdle: 0

            Timer {
                interval: 2000
                running: true
                repeat: true
                onTriggered: sysProc.running = true
            }
            
            Component.onCompleted: sysProc.running = true

            Process {
                id: sysProc
                command: ["sh", "-c", "read -r _ a b c d e f g h _ < /proc/stat; echo \"CPU $((a+b+c+d+e+f+g+h)) $((d+e))\"; awk '/^MemTotal:/{mt=$2}/^MemAvailable:/{ma=$2}END{print \"MEM\",mt,ma}' /proc/meminfo; echo \"TEMP $(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)\""]
                stdout: StdioCollector {
                    onStreamFinished: {
                        var lines = this.text.split("\n");
                        for (var i = 0; i < lines.length; i++) {
                            var p = lines[i].trim().split(/\s+/);
                            if (p[0] === "CPU") {
                                var total = parseFloat(p[1]);
                                var idle = parseFloat(p[2]);
                                if (sysStatsCard.prevCpuTotal > 0) {
                                    var dt = total - sysStatsCard.prevCpuTotal;
                                    var di = idle - sysStatsCard.prevCpuIdle;
                                    sysStatsCard.cpuVal = dt > 0 ? Math.max(0, Math.min(100, Math.round(100 * (dt - di) / dt))) : 0;
                                }
                                sysStatsCard.prevCpuTotal = total;
                                sysStatsCard.prevCpuIdle = idle;
                            } else if (p[0] === "MEM") {
                                var mt = parseFloat(p[1]); // KB
                                var ma = parseFloat(p[2]); // KB
                                var usedGB = (mt - ma) / (1024 * 1024);
                                sysStatsCard.ramValStr = usedGB.toFixed(1) + "GB";
                                sysStatsCard.ramRatio = mt > 0 ? (mt - ma) / mt : 0;
                            } else if (p[0] === "TEMP") {
                                var tempC = parseFloat(p[1]) / 1000.0;
                                sysStatsCard.tempValStr = Math.round(tempC) + "°C";
                                sysStatsCard.tempRatio = tempC > 0 ? Math.min(1.0, tempC / 100.0) : 0;
                            }
                        }
                    }
                }
            }
            
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 32
                spacing: 6
                
                // CPU Section
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text { text: "CPU"; color: "#ffffff"; font.family: rootDashboard.fontFamily; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 32 }
                    
                    Row {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 1
                        Repeater {
                            model: 26
                            Column {
                                spacing: 1
                                property bool isActive: (index / 26.0) <= (sysStatsCard.cpuVal / 100.0)
                                Repeater {
                                    model: 3
                                    Rectangle {
                                        width: 4
                                        height: 4
                                        color: parent.isActive ? "#ffffff" : Qt.rgba(1, 1, 1, 0.15)
                                    }
                                }
                            }
                        }
                    }
                    
                    Text { text: sysStatsCard.cpuVal + "%"; color: "#ffffff"; font.family: rootDashboard.fontFamily; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight }
                }
                
                // RAM Section
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text { text: "RAM"; color: "#ffffff"; font.family: rootDashboard.fontFamily; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 32 }
                    
                    Row {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 1
                        Repeater {
                            model: 26
                            Column {
                                spacing: 1
                                property bool isActive: (index / 26.0) <= sysStatsCard.ramRatio
                                Repeater {
                                    model: 3
                                    Rectangle {
                                        width: 4
                                        height: 4
                                        color: parent.isActive ? "#ffffff" : Qt.rgba(1, 1, 1, 0.15)
                                    }
                                }
                            }
                        }
                    }
                    
                    Text { text: sysStatsCard.ramValStr; color: "#ffffff"; font.family: rootDashboard.fontFamily; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight }
                }
                
                // TEMP Section
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text { text: "TEMP"; color: "#ffffff"; font.family: rootDashboard.fontFamily; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 32 }
                    
                    Row {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 1
                        Repeater {
                            model: 26
                            Column {
                                spacing: 1
                                property bool isActive: (index / 26.0) <= sysStatsCard.tempRatio
                                Repeater {
                                    model: 3
                                    Rectangle {
                                        width: 4
                                        height: 4
                                        color: parent.isActive ? "#ffffff" : Qt.rgba(1, 1, 1, 0.15)
                                    }
                                }
                            }
                        }
                    }
                    
                    Text { text: sysStatsCard.tempValStr; color: "#ffffff"; font.family: rootDashboard.fontFamily; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight }
                }
            }
        }
        
        // --- Row 2 ---
        // Daily Activities / Calendar (2x2)
        BentoCard {
            colSpan: 2; rowSpan: 2
            CalendarModule {
                anchors.fill: parent
                anchors.margins: 16
                
                // Inherit colors for seamless integration
                colorBg: "transparent"
                colorFg: colFg
                colorMuted: colMuted
                colorAccent: colCyan
                fontFamily: rootDashboard.fontFamily
            }
        }
        
        // Music Player (2x1)
        BentoCard {
            id: mprisCard
            colSpan: 2; rowSpan: 1
            
            property var playersList: typeof Mpris !== "undefined" && Mpris.players ? Mpris.players.values : []
            property var _lastPlaying: null
            property var activePlayer: null
            
            function updateActivePlayer() {
                var playing = null;
                var paused = null;
                for (var i = 0; i < playersList.length; i++) {
                    if (playersList[i].playbackState === MprisPlaybackState.Playing) playing = playersList[i];
                    else if (playersList[i].playbackState === MprisPlaybackState.Paused) paused = playersList[i];
                }
                if (playing) {
                    _lastPlaying = playing;
                    activePlayer = playing;
                    return;
                }
                if (_lastPlaying) {
                    for (var j = 0; j < playersList.length; j++) {
                        if (playersList[j] === _lastPlaying) {
                            activePlayer = _lastPlaying;
                            return;
                        }
                    }
                }
                activePlayer = paused ? paused : (playersList.length > 0 ? playersList[0] : null);
            }
            
            onPlayersListChanged: updateActivePlayer()
            Component.onCompleted: updateActivePlayer()
            
            property bool isPlaying: activePlayer ? activePlayer.playbackState === MprisPlaybackState.Playing : false
            property string trackTitle: activePlayer && activePlayer.trackTitle ? activePlayer.trackTitle : "No Music"
            property string trackArtist: activePlayer && activePlayer.trackArtists && activePlayer.trackArtists.length > 0 ? activePlayer.trackArtists[0] : (activePlayer && activePlayer.identity ? activePlayer.identity : "Unknown Artist")
            property string _lastValidArtUrl: ""
            property string artUrl: {
                var currentUrl = activePlayer ? (activePlayer.trackArtUrl || activePlayer.artUrl || "") : "";
                if (currentUrl !== "") _lastValidArtUrl = currentUrl;
                return currentUrl !== "" ? currentUrl : _lastValidArtUrl;
            }
            
            property real polledLength: 0
            property real polledPosition: 0
            
            function updateProgress() {
                if (mprisCard.activePlayer) {
                    mprisCard.polledPosition = Number(mprisCard.activePlayer.position) || 0;
                    mprisCard.polledLength = Number(mprisCard.activePlayer.length) || 0;
                } else {
                    mprisCard.polledPosition = 0;
                    mprisCard.polledLength = 0;
                }
            }
            
            Timer {
                interval: 500
                running: mprisCard.activePlayer !== null
                repeat: true
                triggeredOnStart: true
                onTriggered: mprisCard.updateProgress()
            }
            
            Connections {
                target: mprisCard.activePlayer
                function onPositionChanged() { mprisCard.updateProgress() }
                function onLengthChanged() { mprisCard.updateProgress() }
            }
            
            function formatTime(secs) {
                if (!secs || secs < 0) return "0:00";
                var m = Math.floor(secs / 60);
                var s = Math.floor(secs % 60);
                return m + ":" + (s < 10 ? "0" : "") + s;
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20
                Item {
                    width: 72; height: 72
                    
                    Item {
                        id: artContent
                        anchors.fill: parent
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                            maskSource: ShaderEffectSource {
                                sourceItem: Rectangle {
                                    width: artContent.width
                                    height: artContent.height
                                    radius: 16
                                }
                                hideSource: true
                            }
                        }
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 16
                            color: mprisCard.artUrl ? "transparent" : "#f7768e"
                        }
                        
                        Image {
                            anchors.fill: parent
                            source: mprisCard.artUrl
                            visible: mprisCard.artUrl !== ""
                            fillMode: Image.PreserveAspectCrop
                        }
                        
                        Text { anchors.centerIn: parent; text: "󰝚"; color: "#fff"; font.family: rootDashboard.fontFamily; font.pixelSize: 40; visible: mprisCard.artUrl === "" }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    
                    MarqueeText { 
                        text: mprisCard.trackTitle
                        color: colFg
                        fontFamily: rootDashboard.fontFamily
                        pixelSize: 16
                        bold: true
                        Layout.fillWidth: true
                    }
                    
                    Text { text: mprisCard.formatTime(mprisCard.polledPosition); color: colMuted; font.family: rootDashboard.fontFamily; font.pixelSize: 12; font.bold: true }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        Text { 
                            text: "󰒮"; color: colFg; font.family: rootDashboard.fontFamily; font.pixelSize: 20
                            MouseArea { anchors.fill: parent; anchors.margins: -10; onClicked: if (mprisCard.activePlayer) mprisCard.activePlayer.previous() }
                        }
                        Text { 
                            text: mprisCard.isPlaying ? "󰏤" : "󰐊"; color: colFg; font.family: rootDashboard.fontFamily; font.pixelSize: 24 
                            MouseArea { anchors.fill: parent; anchors.margins: -10; onClicked: if (mprisCard.activePlayer) mprisCard.activePlayer.togglePlaying() }
                        }
                        Text { 
                            text: "󰒭"; color: colFg; font.family: rootDashboard.fontFamily; font.pixelSize: 20 
                            MouseArea { anchors.fill: parent; anchors.margins: -10; onClicked: if (mprisCard.activePlayer) mprisCard.activePlayer.next() }
                        }
                        Item { Layout.fillWidth: true }
                        Text { text: "󰓃"; color: colMuted; font.family: rootDashboard.fontFamily; font.pixelSize: 20 }
                    }
                }
            }
        }
        
        // Battery / Charging (1x1)
        BentoCard {
            id: batteryCard
            colSpan: 1; rowSpan: 1
            
            property real batteryLevel: UPower.displayDevice ? UPower.displayDevice.percentage * 100 : 0
            property bool isCharging: !UPower.onBattery
            property real timeRemaining: UPower.displayDevice ? (UPower.onBattery ? UPower.displayDevice.timeToEmpty : UPower.displayDevice.timeToFull) : 0
            
            function formatHours(seconds) {
                if (!seconds || seconds <= 0) return isCharging ? "Fully charged" : "Calculating...";
                var h = Math.floor(seconds / 3600);
                var m = Math.floor((seconds % 3600) / 60);
                if (h > 0) return "~ " + h + " hours";
                return "~ " + m + " mins";
            }
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                
                // Top: Icon + Percentage
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4
                    Text { 
                        text: batteryCard.isCharging ? "󰂄" : "󰁹"
                        color: "#a855f7" 
                        font.family: rootDashboard.fontFamily
                        font.pixelSize: 20 
                    }
                    Text { 
                        text: Math.round(batteryCard.batteryLevel) + "%"
                        color: "#ffffff"
                        font.family: rootDashboard.fontFamily
                        font.pixelSize: 20
                        font.bold: true 
                    }
                }
                
                // Middle: 5 Vertical Bars
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 5 * 12 + 4 * 4 + 12 // 5 bars (12px), 4 spaces (4px), padding (6px * 2) = 60 + 16 + 12 = 88
                    height: 36 // 24px bar + 12px padding
                    color: Qt.rgba(0.1, 0.1, 0.15, 0.5) // Dark shell
                    radius: 6
                    border.color: Qt.rgba(1, 1, 1, 0.05)
                    border.width: 1
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        
                        Repeater {
                            model: 5
                            Item {
                                width: 12
                                height: 24
                                
                                // Background (empty cell)
                                Rectangle {
                                    anchors.fill: parent
                                    color: Qt.rgba(0, 0, 0, 0.5)
                                    radius: 3
                                }
                                
                                // Foreground (filled cell)
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    
                                    property real barMin: index * 20
                                    property real barMax: (index + 1) * 20
                                    property real fillRatio: {
                                        if (batteryCard.batteryLevel >= barMax) return 1.0;
                                        if (batteryCard.batteryLevel <= barMin) return 0.0;
                                        return (batteryCard.batteryLevel - barMin) / 20.0;
                                    }
                                    
                                    height: parent.height * fillRatio
                                    color: Qt.alpha("#a855f7", 0.4 + index * 0.15)
                                    radius: 3
                                    visible: fillRatio > 0
                                    
                                    Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                }
                            }
                        }
                    }
                }
                
                // Bottom: Time Remaining
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: batteryCard.formatHours(batteryCard.timeRemaining)
                    color: "#8e8e93"
                    font.family: rootDashboard.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }
        

        
        // Radial Tick Clock (1x1)
        BentoCard {
            colSpan: 1; rowSpan: 1
            Item {
                id: clockItem
                anchors.fill: parent
                
                property var currentTime: new Date()
                
                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clockItem.currentTime = new Date()
                }
                
                // Center text
                Column {
                    anchors.centerIn: parent
                    spacing: 0
                    Text {
                        text: Qt.formatTime(clockItem.currentTime, "hh:mm")
                        color: "#ffffff"
                        font.family: rootDashboard.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
                
                // Radial ticks
                Repeater {
                    model: 60
                    Item {
                        anchors.centerIn: parent
                        rotation: index * 6
                        
                        property bool isMinute: index === clockItem.currentTime.getMinutes()
                        property bool isHour: index === ((clockItem.currentTime.getHours() % 12) * 5 + Math.floor(clockItem.currentTime.getMinutes() / 12))
                        property bool isHourMarker: index % 5 === 0
                        
                        Rectangle {
                            width: isHour ? 3 : 2
                            height: isMinute ? 38 : (isHour ? 28 : (isHourMarker ? 22 : 16))
                            
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: isMinute ? "#f7768e" : (isHour ? "#e0af68" : (isHourMarker ? Qt.rgba(1, 1, 1, 0.8) : Qt.rgba(1, 1, 1, 0.3))) }
                                GradientStop { position: 1.0; color: isMinute ? Qt.alpha("#f7768e", 0.1) : (isHour ? Qt.alpha("#e0af68", 0.1) : Qt.rgba(1, 1, 1, 0.05)) }
                            }
                            
                            // Base inner radius is 22. Ticks extend outward.
                            x: -width / 2
                            y: -22 - height
                            radius: 1
                            
                            // Smooth animation for when the hand moves
                            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                        }
                    }
                }
            }
        }
        
        // --- Row 3 ---
        // Volume Radio Widget (1x1)
        BentoCard {
            id: volCard
            colSpan: 1; rowSpan: 1
            
            property var sink: typeof Pipewire !== "undefined" ? Pipewire.defaultAudioSink : null
            readonly property bool sinkReady: sink && sink.ready
            property int vol: sinkReady ? Math.min(200, Math.round(sink.audio.volume * 100)) : 0
            property bool internalVolChange: false
            
            PwObjectTracker {
                objects: [volCard.sink]
            }
            
            Process { id: volumeCommand }
            
            Timer {
                id: volResetTimer
                interval: 100
                onTriggered: volCard.internalVolChange = false
            }

            Item {
                anchors.fill: parent
                // Không dùng clip: true ở đây để BentoCard tự cắt bằng mask viền cong
                
                Item {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    transformOrigin: Item.Right
                    // Scale cho ô 1x1, đảm bảo mép phải sát viền
                    scale: Math.max(parent.width / 450, parent.height / 300) * 1.05
                    width: 450
                    height: 300
                    
                    RadioWidget {
                        anchors.centerIn: parent
                        minValue: 0
                        maxValue: 200
                        tickMarks: [0, 50, 100, 150, 200]
                        unitText: "󰕾" // Icon loa
                        currentValue: volCard.internalVolChange ? currentValue : volCard.vol
                        
                        onCurrentValueChanged: {
                            if (!volCard.sinkReady) return;
                            if (Math.abs(volCard.vol - currentValue) >= 1) {
                                volCard.internalVolChange = true;
                                volResetTimer.restart();
                                volumeCommand.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (currentValue / 100.0).toFixed(2)];
                                volumeCommand.running = true;
                            }
                        }
                    }
                }
            }
        }
        
        // Brightness Radio Widget (1x1)
        BentoCard {
            id: briCard
            colSpan: 1; rowSpan: 1
            
            Osd.Brightness {
                id: brightnessTracker
                visible: false
            }
            
            property bool internalBriChange: false
            
            Process { id: brightnessCommand }
            
            Timer {
                id: briResetTimer
                interval: 100
                onTriggered: briCard.internalBriChange = false
            }
            
            Item {
                anchors.fill: parent
                // Không dùng clip: true ở đây để BentoCard tự cắt bằng mask viền cong
                
                Item {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    transformOrigin: Item.Right
                    // Scale cho ô 1x1, đảm bảo mép phải sát viền
                    scale: Math.max(parent.width / 450, parent.height / 300) * 1.05
                    width: 450
                    height: 300
                    
                    RadioWidget {
                        anchors.centerIn: parent
                        minValue: 0
                        maxValue: 100
                        tickMarks: [0, 20, 40, 60, 80, 100]
                        unitText: "󰃠" // Icon mặt trời
                        currentValue: briCard.internalBriChange ? currentValue : brightnessTracker.percent * 100
                        
                        onCurrentValueChanged: {
                            if (Math.abs((brightnessTracker.percent * 100) - currentValue) >= 1) {
                                briCard.internalBriChange = true;
                                briResetTimer.restart();
                                brightnessCommand.command = ["brightnessctl", "s", Math.round(currentValue) + "%"];
                                brightnessCommand.running = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
