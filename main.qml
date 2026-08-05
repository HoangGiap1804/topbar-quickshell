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
        
        // Cấu hình vùng nhận diện click (Mask)
        mask: pill.isMini ? pillRegion : fullRegion
        
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
        
        // Bắt click toàn màn hình (chỉ kích hoạt khi pill mở rộng)
        MouseArea {
            anchors.fill: parent
            enabled: !pill.isMini
            onPressed: (mouse) => {
                var inside = mouse.x >= pillRegion.x && mouse.x <= pillRegion.x + pillRegion.width
                          && mouse.y >= pillRegion.y && mouse.y <= pillRegion.y + pillRegion.height;
                // Chỉ thu nhỏ khi click ra ngoài vùng của Pill
                if (!inside && !minimizeAnim.running) {
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
                // 1. Thu nhỏ thành hình vuông đen nhỏ
                ScriptAction { script: { pill.isShrinking = true } }
                
                // 2. Chờ thu nhỏ một chút (giảm để nhanh hơn)
                PauseAnimation { duration: 200 }
                
                // 3. Trượt lên khỏi màn hình
                NumberAnimation { 
                    target: pill; property: "yOffset"; 
                    to: -(pill.height + 50); 
                    duration: 250; easing.type: Easing.InBack 
                }
                
                // 4. Chuyển sang trạng thái notch (ở ngoài màn hình)
                ScriptAction { script: { pill.isMini = true; pill.isShrinking = false } }
                
                // 5. Đặt vị trí chuẩn bị trượt xuống
                PropertyAction { target: pill; property: "yOffset"; value: -pill.miniHeight - 50 }
                PauseAnimation { duration: 20 }
                
                // 6. Từ từ trượt xuống
                NumberAnimation { 
                    target: pill; property: "yOffset"; 
                    to: 0; 
                    duration: 400; easing.type: Easing.OutExpo 
                }
            }
            
            property bool isMini: true
            property bool isShrinking: false
            property real miniWidth: 100 // Chiều rộng khi thu nhỏ (notch)
            property real miniHeight: 20 // Chiều cao khi thu nhỏ (notch)
            
            onIsMiniChanged: {
                if (isMini) {
                    root.isSidebarOpen = false;
                }
            }
            property real contentWidth: swipeView.count > 0 ? Math.max(grid1.implicitWidth, grid2.implicitWidth, layout3.implicitWidth, radial.implicitWidth, calendar.implicitWidth, testPage.implicitWidth) : 0
            property real contentHeight: swipeView.count > 0 ? Math.max(grid1.implicitHeight, grid2.implicitHeight, layout3.implicitHeight, radial.implicitHeight, calendar.implicitHeight, testPage.implicitHeight) : 0
            
            implicitWidth: isShrinking ? 60 : (isMini ? miniWidth : contentWidth + 50)
            implicitHeight: isShrinking ? 60 : (isMini ? miniHeight : contentHeight + 60) // Căn vừa đủ kích thước lưới + PageIndicator

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

            // Nền mở rộng (Floating Pill)
            Shape {
                id: pillBg
                anchors.fill: parent
                opacity: pill.isMini && !pill.isShrinking ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                
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

            // Icon hiển thị khi thu nhỏ
            Text {
                id: clockExpanded
                anchors.centerIn: parent
                
                color: "#ffffff"
                font { family: root.fontFamily; pixelSize: 12; bold: true }
                opacity: pill.isMini && !pill.isShrinking ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clockExpanded.text = Qt.formatDateTime(new Date(), "HH:mm")
                }
            }

            // Xử lý click để phóng to (vô hiệu hóa khi đã phóng to, mọi click khác được overlay xử lý)
            MouseArea {
                anchors.fill: parent
                cursorShape: pill.isMini ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: pill.isMini
                onClicked: { pill.isMini = false }
            }

            SwipeView {
                id: swipeView
                anchors.fill: parent
                anchors.topMargin: 30
                anchors.bottomMargin: 15
                anchors.leftMargin: 25
                anchors.rightMargin: 25
                clip: true
                
                opacity: pill.isMini || pill.isShrinking ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                Item {
                    ScrollView {
                        id: layout3
                        anchors.centerIn: parent
                        implicitWidth: 240
                        implicitHeight: Math.min(contentCol.implicitHeight, 200)
                        width: implicitWidth
                        height: implicitHeight
                        clip: true
                        
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                        
                        ColumnLayout {
                            id: contentCol
                            width: layout3.width
                            spacing: 12

                            ButtonModule {
                                text: root.isSidebarOpen ? "Đóng Sidebar" : "Mở Sidebar"
                                onClicked: root.isSidebarOpen = !root.isSidebarOpen
                                Layout.alignment: Qt.AlignHCenter
                                Layout.bottomMargin: 8
                            }

                            Text {
                                text: "To-Do List"
                                color: root.colCyan
                                font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                                Layout.alignment: Qt.AlignHCenter
                                Layout.bottomMargin: 8
                            }

                            TaskModule {
                                text: "Uống nước"
                                isDone: true
                                colorText: root.colFg
                                colorDone: root.colMuted
                                colorAccent: root.colCyan
                                fontFamily: root.fontFamily
                                fontSize: root.fontSize
                            }
                            
                            TaskModule {
                                text: "Check email"
                                colorText: root.colFg
                                colorDone: root.colMuted
                                colorAccent: root.colCyan
                                fontFamily: root.fontFamily
                                fontSize: root.fontSize
                            }
                            
                            TaskModule {
                                text: "Viết báo cáo"
                                colorText: root.colFg
                                colorDone: root.colMuted
                                colorAccent: root.colCyan
                                fontFamily: root.fontFamily
                                fontSize: root.fontSize
                            }
                            
                            TaskModule {
                                text: "Code tính năng mới"
                                colorText: root.colFg
                                colorDone: root.colMuted
                                colorAccent: root.colCyan
                                fontFamily: root.fontFamily
                                fontSize: root.fontSize
                            }
                            
                            TaskModule {
                                text: "Họp nhóm lúc 3h"
                                colorText: root.colFg
                                colorDone: root.colMuted
                                colorAccent: root.colCyan
                                fontFamily: root.fontFamily
                                fontSize: root.fontSize
                            }
                            
                            TaskModule {
                                text: "Tập thể dục"
                                colorText: root.colFg
                                colorDone: root.colMuted
                                colorAccent: root.colCyan
                                fontFamily: root.fontFamily
                                fontSize: root.fontSize
                            }
                        }
                    }
                }

                Item {
                    RadialMenuModule {
                        id: radial
                        anchors.centerIn: parent
                    }
                }
                Item {
                    GridLayout {
                        id: grid1
                        anchors.centerIn: parent
                        columns: 2
                        rowSpacing: 16
                        columnSpacing: 32

                        // Hàng 1: Workspaces chiếm cả 2 cột
                        Workspaces {
                            colCyan: root.colCyan
                            colBlue: root.colBlue
                            colMuted: root.colMuted
                            fontFamily: root.fontFamily
                            fontSize: root.fontSize
                        }

                        // Hàng 2: CPU và Memory (chia 2 cột)
                        CpuModule {
                            usage: root.cpuUsage
                            colorText: root.colYellow
                            fontFamily: root.fontFamily
                            fontSize: root.fontSize
                        }

                        MemoryModule {
                            usage: root.memUsage
                            colorText: root.colCyan
                            fontFamily: root.fontFamily
                            fontSize: root.fontSize
                        }

                        // Hàng 3: Clock chiếm 2 cột
                        ClockModule {
                            colorText: root.colBlue
                            fontFamily: root.fontFamily
                            fontSize: root.fontSize
                        }
                    }
                }
                
                Item {
                    GridLayout {
                        id: grid2
                        anchors.centerIn: parent
                        columns: 2
                        rowSpacing: 16
                        columnSpacing: 32
                        
                        ToggleButtonModule {
                            text: "󰤨  Wi-Fi"
                            isOn: true
                            colorActive: root.colCyan
                            colorInactive: root.colMuted
                            colorHover: root.colBlue
                            colorText: root.colBg
                            colorTextOff: root.colFg
                            fontFamily: root.fontFamily
                            fontSize: root.fontSize - 2
                        }
                        
                        ToggleButtonModule {
                            text: "󰂯  Bluetooth"
                            isOn: false
                            colorActive: root.colBlue
                            colorInactive: root.colMuted
                            colorHover: root.colCyan
                            colorText: root.colBg
                            colorTextOff: root.colFg
                            fontFamily: root.fontFamily
                            fontSize: root.fontSize - 2
                        }

                        SliderModule {
                            iconText: ""
                            value: 0.7
                            colorAccent: root.colYellow
                            colorMuted: root.colMuted
                            colorFg: root.colFg
                            fontFamily: root.fontFamily
                            fontSize: root.fontSize
                        }

                        SliderModule {
                            iconText: "󰃠"
                            value: 0.4
                            colorAccent: root.colCyan
                            colorMuted: root.colMuted
                            colorFg: root.colFg
                            fontFamily: root.fontFamily
                            fontSize: root.fontSize
                        }
                    }
                }
                
                Item {
                    CalendarModule {
                        id: calendar
                        anchors.centerIn: parent
                        colorBg: root.colBg
                        colorFg: root.colFg
                        colorMuted: root.colMuted
                        colorAccent: root.colCyan
                        fontFamily: root.fontFamily
                    }
                }
                
                Item {
                    implicitWidth: testPage.implicitWidth
                    implicitHeight: testPage.implicitHeight
                    
                    ColumnLayout {
                        id: testPage
                        anchors.centerIn: parent
                        spacing: 16
                        
                        Text {
                            text: "Test Toast Notification"
                            color: root.colCyan
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize + 2
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        ButtonModule {
                            text: "Thành công (Success)"
                            onClicked: root.showToast("Dữ liệu đã được lưu thành dfasd fasdfasdfasdf asdf sad fasfd asdf asdf asdf asdf asd fasdfasdfcông!", "success")
                        }
                        
                        ButtonModule {
                            text: "Cảnh báo (Warning)"
                            onClicked: root.showToast("Pin yếu! Vui lòng cắm sạc.", "warning")
                        }
                        
                        ButtonModule {
                            text: "Thông thường (Info)"
                            onClicked: root.showToast("Đã có bản cập nhật hệ thống mới.", "info")
                        }
                    }
                }

            }

            PageIndicator {
                anchors.top: parent.top
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                count: swipeView.count
                currentIndex: swipeView.currentIndex
                opacity: pill.isMini || pill.isShrinking ? 0 : 1
                visible: opacity > 0
                
                delegate: Rectangle {
                    implicitWidth: 8
                    implicitHeight: 8
                    radius: 4
                    color: index === swipeView.currentIndex ? root.colCyan : root.colMuted
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }
    }
    
    // Các OSD hiển thị dưới dạng Đĩa quay Radio
    VolumeOsdWindow {}
    BrightnessOsdWindow {}

    
    
} // Đóng ShellRoot
