import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Services.UPower
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Mpris

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
    property string cardBackgroundImage: "/home/nqim/.dotfiles/wallpapers/wallpaper.jpeg"

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
                command: ["sh", "-c", "read -r _ a b c d e f g h _ < /proc/stat; echo \"CPU $((a+b+c+d+e+f+g+h)) $((d+e))\"; awk '/^MemTotal:/{mt=$2}/^MemAvailable:/{ma=$2}END{print \"MEM\",mt,ma}' /proc/meminfo"]
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
                            }
                        }
                    }
                }
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 0
                
                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "CPU"; color: colFg; font.family: rootDashboard.fontFamily; font.pixelSize: 11; font.bold: true }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: sysStatsCard.cpuVal + "%"; color: colYellow; font.family: rootDashboard.fontFamily; font.pixelSize: 22; font.bold: true }
                }
                
                Rectangle { width: 1; height: 40; color: Qt.alpha(colFg, 0.5); Layout.alignment: Qt.AlignVCenter }
                
                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "RAM"; color: colFg; font.family: rootDashboard.fontFamily; font.pixelSize: 11; font.bold: true }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: sysStatsCard.ramValStr; color: colCyan; font.family: rootDashboard.fontFamily; font.pixelSize: 22; font.bold: true }
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
            colSpan: 1; rowSpan: 1
            Column {
                anchors.centerIn: parent
                spacing: 6
                
                property real batteryLevel: UPower.displayDevice ? UPower.displayDevice.percentage * 100 : 0
                property bool isCharging: !UPower.onBattery
                property real timeRemaining: UPower.displayDevice ? (UPower.onBattery ? UPower.displayDevice.timeToEmpty : UPower.displayDevice.timeToFull) : 0
                
                function formatTime(seconds) {
                    if (!seconds || seconds <= 0) return isCharging ? "Fully charged" : "Calculating...";
                    var h = Math.floor(seconds / 3600);
                    var m = Math.floor((seconds % 3600) / 60);
                    var suffix = isCharging ? "until full" : "left";
                    if (h > 0) return h + "h " + m + "m " + suffix;
                    return m + "m " + suffix;
                }
                
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: (parent.isCharging ? "󰂄 " : "󰁹 ") + Math.round(parent.batteryLevel) + "%"; color: "#9ece6a"; font.family: rootDashboard.fontFamily; font.pixelSize: 22; font.bold: true }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.formatTime(parent.timeRemaining); color: colMuted; font.family: rootDashboard.fontFamily; font.pixelSize: 10; font.bold: true }
                Item { width: 1; height: 8 } // Spacer
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6
                    Rectangle { width: 14; height: 24; radius: 5; color: parent.parent.batteryLevel >= 15 ? "#ff9e64" : Qt.alpha(colMuted, 0.5) }
                    Rectangle { width: 14; height: 24; radius: 5; color: parent.parent.batteryLevel >= 45 ? "#ff9e64" : Qt.alpha(colMuted, 0.5) }
                    Rectangle { width: 14; height: 24; radius: 5; color: parent.parent.batteryLevel >= 75 ? "#ff9e64" : Qt.alpha(colMuted, 0.5) }
                }
            }
        }
        

        
        // Analog Clock (1x1)
        BentoCard {
            colSpan: 1; rowSpan: 1
            Item {
                id: clockItem
                anchors.fill: parent
                
                property var currentTime: new Date()
                property real hourAngle: (currentTime.getHours() % 12) * 30 + (currentTime.getMinutes() / 60) * 30
                property real minuteAngle: currentTime.getMinutes() * 6 + (currentTime.getSeconds() / 60) * 6
                property real secondAngle: currentTime.getSeconds() * 6
                
                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clockItem.currentTime = new Date()
                }
                
                Rectangle {
                    anchors.centerIn: parent
                    width: 96; height: 96; radius: 48
                    color: "transparent"
                    border.color: Qt.alpha(colMuted, 0.5); border.width: 3
                    
                    // Markers
                    Repeater {
                        model: 12
                        Rectangle {
                            width: 2; height: index % 3 === 0 ? 8 : 4
                            color: colFg; radius: 1
                            x: 48 - 1
                            y: 6
                            transform: Rotation { origin.x: 1; origin.y: 42; angle: index * 30 }
                        }
                    }
                    
                    // Hands
                    // Hour Hand
                    Rectangle { x: 47; y: 22; width: 3; height: 26; color: colFg; radius: 1.5; transform: Rotation { origin.x: 1.5; origin.y: 26; angle: clockItem.hourAngle } }
                    // Minute Hand
                    Rectangle { x: 47; y: 12; width: 3; height: 36; color: colCyan; radius: 1.5; transform: Rotation { origin.x: 1.5; origin.y: 36; angle: clockItem.minuteAngle } }

                    
                    // Center Dot
                    Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: "#f7768e" }
                }
            }
        }
    }
}
