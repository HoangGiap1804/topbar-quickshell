import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

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

    // Cửa sổ dự trữ khoảng không gian 40px ở mép trên cùng
    PanelWindow {
        id: reserve
        anchors.top: true
        anchors.left: true
        anchors.right: true
        
        implicitHeight: 40
        color: "transparent"
        
        exclusiveZone: 40
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
                if (!inside) {
                    pill.isMini = true;
                }
            }
        }

        // Hộp chứa (pill) nằm giữa
        Rectangle {
            id: pill
            anchors.top: parent.top
            anchors.topMargin: 5
            anchors.horizontalCenter: parent.horizontalCenter
            
            property bool isMini: true
            property real contentWidth: swipeView.count > 0 ? Math.max(grid1.implicitWidth, grid2.implicitWidth, layout3.implicitWidth, radial.implicitWidth) : 0
            property real contentHeight: swipeView.count > 0 ? Math.max(grid1.implicitHeight, grid2.implicitHeight, layout3.implicitHeight, radial.implicitHeight) : 0
            
            implicitWidth: isMini ? 60 : contentWidth + 50
            implicitHeight: isMini ? 30 : contentHeight + 60 // Căn vừa đủ kích thước lưới + PageIndicator
            radius: 15
            color: Qt.alpha(root.colBg, 0.6) // Làm trong suốt nền (60% opacity)
            
            border.color: Qt.alpha(root.colMuted, 0.5)
            border.width: 1
            clip: true

            Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
            Behavior on implicitHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

            // Icon hiển thị khi thu nhỏ
            Text {
                id: clockExpanded
                anchors.centerIn: parent
                
                color: root.colCyan
                font { family: root.fontFamily; pixelSize: 14 }
                opacity: pill.isMini ? 1 : 0
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
                
                opacity: pill.isMini ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
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

            }

            PageIndicator {
                anchors.top: parent.top
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                count: swipeView.count
                currentIndex: swipeView.currentIndex
                opacity: pill.isMini ? 0 : 1
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
} // Đóng ShellRoot
