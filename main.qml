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
    property color colBg: "#1a1b26"
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
            property real contentWidth: swipeView.count > 0 ? Math.max(grid1.implicitWidth, grid2.implicitWidth) : 0
            property real contentHeight: swipeView.count > 0 ? Math.max(grid1.implicitHeight, grid2.implicitHeight) : 0
            
            implicitWidth: isMini ? 60 : contentWidth + 50
            implicitHeight: isMini ? 30 : contentHeight + 60 // Căn vừa đủ kích thước lưới + PageIndicator
            radius: 15
            color: root.colBg
            
            border.color: root.colMuted
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
                anchors.topMargin: 15
                anchors.bottomMargin: 30
                anchors.leftMargin: 25
                anchors.rightMargin: 25
                clip: true
                
                opacity: pill.isMini ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150 } }

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
                        
                        // Thêm các module vào trang 2
                        ButtonModule {
                            text: "Mở Cài đặt"
                            colorBg: root.colCyan
                            colorHover: root.colBlue
                            colorText: root.colBg
                            fontFamily: root.fontFamily
                            fontSize: root.fontSize - 2
                        }
                        ButtonModule {
                            text: "Mở Terminal"
                            colorBg: root.colYellow
                            colorHover: root.colYellow
                            colorText: root.colBg
                            fontFamily: root.fontFamily
                            fontSize: root.fontSize - 2
                        }
                    }
                }
            }

            PageIndicator {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
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
