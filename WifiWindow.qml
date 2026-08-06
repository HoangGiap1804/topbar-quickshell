import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

PanelWindow {
    id: wifiWindow
    
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    
    color: "transparent"
    
    exclusiveZone: 0
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "wifi-window"
    
    property bool isOpen: false
    visible: isOpen || yAnim.running
    
    property string passwordPromptSsid: ""
    property bool passwordPromptVisible: false
    property string passwordValue: ""
    
    // Đối tượng điều khiển Wi-Fi nội bộ mô phỏng IslandBackend
    QtObject {
        id: wifiController
        property bool enabled: true
        property bool scanning: scanProcess.running
        property bool busy: connectProcess.running || disconnectProcess.running
        property string errorMessage: ""
        
        function refreshNetworks(rescan) {
            if (rescan) rescanProcess.running = true;
            scanProcess.running = true;
        }
        
        function connectToNetwork(ssid, password) {
            errorMessage = "";
            let cmd = ["nmcli", "device", "wifi", "connect", ssid];
            if (password && password.length > 0) {
                cmd.push("password");
                cmd.push(password);
            }
            connectProcess.command = cmd;
            connectProcess.running = true;
        }
        
        function disconnectCurrent() {
            errorMessage = "";
            disconnectProcess.running = true;
        }
    }
    
    ListModel { id: wifiModel }
    
    Process {
        id: rescanProcess
        command: ["nmcli", "device", "wifi", "rescan"]
    }
    
    Process {
        id: disconnectProcess
        command: ["nmcli", "device", "disconnect", "wlan0"]
        onExited: {
            wifiController.refreshNetworks(false);
        }
    }
    
    Process {
        id: connectProcess
        command: [] // Dynamic
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                wifiController.errorMessage = "Failed to connect to network.";
            }
            wifiController.refreshNetworks(false);
        }
    }
    
    Process {
        id: scanProcess
        command: ["nmcli", "-t", "-f", "ACTIVE,SIGNAL,SECURITY,SSID", "dev", "wifi"]
        
        onRunningChanged: {
            if (running) {
                wifiController.errorMessage = "";
            }
        }
        
        stdout: StdioCollector {
            onStreamFinished: {
                let tempNetworks = [];
                let lines = this.text.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i];
                    if (!line || line.trim() === "") continue;
                    let parts = line.split(":");
                    if (parts.length >= 4) {
                        let active = parts[0] === "yes";
                        let signalStr = parts[1];
                        let signal = parseInt(signalStr) || 0;
                        let secure = parts[2] !== "";
                        let ssidStr = parts.slice(3).join(":").replace(/\\:/g, ":");
                        
                        tempNetworks.push({
                            ssid: ssidStr,
                            displayName: ssidStr,
                            signal: signal,
                            secure: secure,
                            connected: active,
                            savedConnection: false
                        });
                    }
                }
                
                let uniqueMap = {};
                for (let i = 0; i < tempNetworks.length; i++) {
                    let net = tempNetworks[i];
                    if (!net.ssid || net.ssid.trim() === "") continue;
                    if (!uniqueMap[net.ssid] || net.connected || (!uniqueMap[net.ssid].connected && net.signal > uniqueMap[net.ssid].signal)) {
                        uniqueMap[net.ssid] = net;
                    }
                }
                
                let uniqueList = Object.values(uniqueMap);
                uniqueList.sort((a, b) => {
                    if (a.connected !== b.connected) return a.connected ? -1 : 1;
                    if (a.signal !== b.signal) return b.signal - a.signal;
                    return a.displayName.localeCompare(b.displayName);
                });
                
                wifiModel.clear();
                for (let i = 0; i < uniqueList.length; i++) {
                    wifiModel.append(uniqueList[i]);
                }
            }
        }
    }
    
    onIsOpenChanged: {
        if (isOpen && wifiController.enabled) {
            wifiController.refreshNetworks(true)
        }
    }
    
    WlrLayershell.keyboardFocus: passwordPromptVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    
    Region { id: emptyRegion }
    Region {
        id: windowRegion
        x: contentItem.x
        y: contentItem.y
        width: contentItem.width
        height: contentItem.height
    }
    mask: isOpen ? windowRegion : emptyRegion
    
    Rectangle {
        id: contentItem
        width: 300
        height: 400
        
        x: (parent.width / 2) + 216
        
        // Căn mép trên bằng với mép trên của Pill lớn (cách trần 5px)
        property real targetY: 5
        y: isOpen ? targetY : -height
        
        Behavior on y {
            NumberAnimation { id: yAnim; duration: 250; easing.type: Easing.OutQuint }
        }
        
        color: "#16161e"
        radius: 12
        border.color: Qt.alpha("#ffffff", 0.1)
        clip: true
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16
            
            Text {
                text: "Wi-Fi Networks"
                color: "#ffffff"
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 18; bold: true }
            }
            
            Text {
                visible: false
                text: "Đang dò tìm mạng..."
                color: "#a9b1d6"
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
            }
            
            Text {
                visible: false
                text: "Vui lòng bật Wi-Fi để xem danh sách mạng."
                color: "#a9b1d6"
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            
            // Removed dummy model
            
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: networkColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                
                Column {
                    id: networkColumn
                    width: parent.width
                    spacing: 4
                    
                    Repeater {
                        model: wifiModel
                        
                        delegate: Rectangle {
                            width: networkColumn.width
                            height: 45
                            radius: 8
                            color: connected ? "#0db9d7" : (networkMouse.containsMouse ? "#292e42" : "transparent")
                            border.color: connected ? "transparent" : (networkMouse.containsMouse ? "#414868" : "transparent")
                            border.width: 1
                            
                            MouseArea {
                                id: networkMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (connected) {
                                        wifiController.disconnectCurrent();
                                        return;
                                    }
                                    if (savedConnection || !secure) {
                                        wifiController.connectToNetwork(ssid, "");
                                        return;
                                    }
                                    wifiWindow.passwordPromptSsid = ssid;
                                    wifiWindow.passwordPromptVisible = true;
                                }
                            }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 12
                                
                                Text {
                                    text: secure ? "" : ""
                                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 14 }
                                    color: connected ? "#16161e" : "#a9b1d6"
                                }
                                
                                Column {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2
                                    Text {
                                        text: displayName || ssid
                                        color: connected ? "#16161e" : "#ffffff"
                                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 13; bold: connected }
                                    }
                                    Text {
                                        text: connected ? "Connected" : (signal >= 0 ? signal + "%" : "")
                                        color: connected ? "#16161e" : "#565f89"
                                        elide: Text.ElideRight
                                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 10 }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            Text {
                visible: wifiController.errorMessage.length > 0
                text: wifiController.errorMessage
                color: "#f7768e"
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 11 }
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
        
        // Màn hình nhập mật khẩu (Overlay)
        Rectangle {
            visible: wifiWindow.passwordPromptVisible
            onVisibleChanged: if (visible) passwordField.forceActiveFocus()
            anchors.fill: parent
            color: "#16161e"
            radius: 12
            z: 10
            
            // Chặn click lọt xuống dưới
            MouseArea { anchors.fill: parent }
            
            Column {
                anchors.centerIn: parent
                width: parent.width - 32
                spacing: 16
                
                Text {
                    width: parent.width
                    text: "Password for " + wifiWindow.passwordPromptSsid
                    color: "#ffffff"
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 14; bold: true }
                    wrapMode: Text.Wrap
                }
                
                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 8
                    color: "#1a1b26"
                    border.color: "#414868"
                    border.width: 1
                    
                    TextInput {
                        id: passwordField
                        focus: true
                        anchors.fill: parent
                        anchors.margins: 10
                        color: "#c0caf5"
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
                        echoMode: TextInput.Normal
                        verticalAlignment: TextInput.AlignVCenter
                        onTextChanged: wifiWindow.passwordValue = text
                        Keys.onReturnPressed: submitBtn.clicked()
                    }
                }
                
                RowLayout {
                    width: parent.width
                    spacing: 12
                    
                    Rectangle {
                        id: submitBtn
                        Layout.fillWidth: true
                        height: 36; radius: 8
                        color: submitBtnMA.containsMouse ? "#7dcfff" : "#0db9d7"
                        signal clicked()
                        Text { anchors.centerIn: parent; text: "Join"; color: "#16161e"; font { family: "JetBrainsMono Nerd Font"; pixelSize: 13; bold: true } }
                        Behavior on color { ColorAnimation { duration: 100 } }
                        MouseArea {
                            id: submitBtnMA
                            hoverEnabled: true
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                wifiController.connectToNetwork(wifiWindow.passwordPromptSsid, wifiWindow.passwordValue);
                                wifiWindow.passwordPromptVisible = false;
                                wifiWindow.passwordValue = ""
                                passwordField.text = ""
                            }
                        }
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36; radius: 8
                        color: cancelBtnMA.containsMouse ? "#414868" : "#24283b"
                        Text { anchors.centerIn: parent; text: "Cancel"; color: "#c0caf5"; font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 } }
                        Behavior on color { ColorAnimation { duration: 100 } }
                        MouseArea {
                            id: cancelBtnMA
                            hoverEnabled: true
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                wifiWindow.passwordPromptVisible = false
                                wifiWindow.passwordValue = ""
                                passwordField.text = ""
                            }
                        }
                    }
                }
            }
        }
    }
}
