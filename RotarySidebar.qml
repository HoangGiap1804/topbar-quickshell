import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Io

PanelWindow {
    id: sidebarWindow
    anchors.top: true
    anchors.left: true
    anchors.right: true
    
    implicitHeight: 800 // Tăng chiều cao cửa sổ tạm thời để có chỗ vẽ test widget ở giữa màn hình
    implicitWidth: 800
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    
    property bool isOpen: false
    property bool isOsdOpen: osdTimer.running
    property bool effectivelyOpen: isOpen || isOsdOpen
    
    Timer {
        id: osdTimer
        interval: 2500
        repeat: false
    }

    // Khai báo kết nối với Pipewire và PwObjectTracker để duy trì đối tượng không bị unbound
    property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: sink && sink.ready
    // Giới hạn max ở 100% để kim đồng hồ không bao giờ bị vượt ra ngoài dải số
    readonly property int vol: sinkReady ? Math.min(100, Math.round(sink.audio.volume * 100)) : 0
    property bool internalChange: false
    
    PwObjectTracker {
        objects: [sidebarWindow.sink]
    }
    
    onVolChanged: {
        if (sidebarWindow.internalChange) return;
        
        dialContainer.currentValue = vol
        
        // Tự động hiển thị OSD nếu sidebar chưa mở
        if (!sidebarWindow.isOpen) {
            osdTimer.restart()
        }
    }
    
    Region { id: emptyRegion }
    mask: effectivelyOpen ? sidebarRegion : emptyRegion
    
    Region {
        id: sidebarRegion
        x: Math.floor(dialContainer.x) - 30 // Mở rộng mask để chứa mượt mà 2 góc fillet
        y: Math.floor(dialContainer.y) + 140 // Chỉ mask đúng nửa dưới của đĩa quay
        width: Math.ceil(dialContainer.width) + 100
        height: 140
    }

    // Đĩa quay Radio Widget thay thế cho side-pill cũ
    Item {
        id: dialContainer
        width: 280 // Thu nhỏ từ 360
        height: 280
        
        // Vị trí ngang: 1/4 lệch bên phải (chiếm vị trí 75% chiều rộng màn hình)
        x: (parent.width * 0.75) - (width / 2)
        
        // Xoay -90 độ để mép phẳng hướng lên trần màn hình
        rotation: -90
        
        // Trượt theo trục y từ -280 (ẩn) xuống -140 (hiện nửa dưới)
        y: sidebarWindow.effectivelyOpen ? -140 : -280
        opacity: sidebarWindow.effectivelyOpen ? 1 : 0
        
        Behavior on y { 
            NumberAnimation { 
                duration: sidebarWindow.effectivelyOpen ? 500 : 300 
                easing.type: sidebarWindow.effectivelyOpen ? Easing.OutExpo : Easing.InExpo
            } 
        }
        Behavior on opacity {
            NumberAnimation {
                duration: sidebarWindow.effectivelyOpen ? 400 : 250
            }
        }
        
        property real currentValue: 50.0
        property real minValue: 0.0
        property real maxValue: 100.0
        property real angleRange: 270
        property real valueRange: maxValue - minValue
        function valueToAngle(val) {
            return ((val - minValue) / valueRange - 0.5) * angleRange
        }
        
        // Nền nguyên khối (Vẽ toàn bộ hình tròn và 2 góc fillet bằng 1 đường liền mạch)
        Shape {
            anchors.fill: parent
            antialiasing: true
            
            ShapePath {
                fillColor: "#000000"
                strokeColor: Qt.alpha(root.colMuted, 0.5)
                strokeWidth: 1
                
                // Mép trái trần (Physical Left) - Bắt đầu từ Y = 320 (cách tâm 140 một khoảng là +180)
                startX: 140; startY: 320
                
                // LƯU Ý TOÁN HỌC QUAN TRỌNG:
                // Tâm của cụm đĩa quay nằm chính xác tại tọa độ Y = 140.
                // Để hình vẽ không bị lệch, mọi điểm bên trái và bên phải phải đối xứng nhau qua số 140!
                // Trước đây bạn dùng Y: 300 và Y: 0 -> Tâm của bạn là (300 + 0) / 2 = 150.
                // Do 150 lệch 10px so với 140 nên cả hình của bạn bị lệch 10px!
                
                // Điểm chạm vào vòng tròn bên trái: Y = 278.5 (140 + 138.5)
                PathQuad {
                    controlX: 140; controlY: 278.5
                    x: 120; y: 278.5
                }
                
                // Vòng cung đĩa quay. Bán kính chuẩn là 140.
                // Điểm kết thúc bên phải phải là: Y = 1.5 (140 - 138.5)
                // Khoảng cách từ 278.5 đến 1.5 = 277 (nhỏ hơn đường kính 280), nên PathArc chạy hoàn hảo!
                PathArc {
                    x: 120; y: 1.5
                    radiusX: 140; radiusY: 140
                    direction: PathArc.CounterClockwise
                }
                
                // Bo góc lõm bên phải nối lên trần màn hình
                // Điểm kết thúc trên trần: Y = -40 (cách tâm 140 một khoảng là -180, đối xứng hoàn hảo với 320)
                PathQuad {
                    controlX: 140; controlY: 1.5
                    x: 140; y: -40
                }
                
                // Đường trần nối lại về điểm xuất phát
                PathLine { x: 140; y: 320 }
            }
        }

        // Vòng cung tím với hiệu ứng Neon Blur (nhạt dần ở 2 mép)
        Shape {
            anchors.fill: parent
            antialiasing: true
            layer.enabled: true
            layer.samples: 4
            
            // === Lớp Glow 1 (Rộng nhất, mờ nhất) ===
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha("#cba6ff", 0.05)
                strokeWidth: 24
                capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: 140; centerY: 140; radiusX: 110; radiusY: 110; startAngle: 45; sweepAngle: 135 }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha("#7a42ff", 0.05)
                strokeWidth: 24
                capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: 140; centerY: 140; radiusX: 110; radiusY: 110; startAngle: 180; sweepAngle: 135 }
            }

            // === Lớp Glow 2 (Trung bình) ===
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha("#cba6ff", 0.15)
                strokeWidth: 12
                capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: 140; centerY: 140; radiusX: 110; radiusY: 110; startAngle: 45; sweepAngle: 135 }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha("#7a42ff", 0.15)
                strokeWidth: 12
                capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: 140; centerY: 140; radiusX: 110; radiusY: 110; startAngle: 180; sweepAngle: 135 }
            }

            // === Lớp Glow 3 (Sáng bao quanh lõi) ===
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha("#cba6ff", 0.4)
                strokeWidth: 6
                capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: 140; centerY: 140; radiusX: 110; radiusY: 110; startAngle: 45; sweepAngle: 135 }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha("#7a42ff", 0.4)
                strokeWidth: 6
                capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: 140; centerY: 140; radiusX: 110; radiusY: 110; startAngle: 180; sweepAngle: 135 }
            }

            // === Lõi viền sắc nét (Viền nhỏ bên trong cùng) ===
            ShapePath {
                fillColor: "transparent"
                strokeColor: "#cba6ff"
                strokeWidth: 2
                capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: 140; centerY: 140; radiusX: 110; radiusY: 110; startAngle: 45; sweepAngle: 135 }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: "#7a42ff"
                strokeWidth: 2
                capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: 140; centerY: 140; radiusX: 110; radiusY: 110; startAngle: 180; sweepAngle: 135 }
            }
        }

        // Lõi đĩa quay chứa vạch và số
        Item {
            id: dial
            anchors.centerIn: parent
            // Góc quay tính toán để currentValue luôn hướng ra gốc 180 độ (bên trái)
            rotation: -dialContainer.valueToAngle(dialContainer.currentValue)
            Behavior on rotation { SpringAnimation { spring: 3; damping: 0.3 } }

            Repeater {
                model: 100
                Item {
                    property real val: dialContainer.minValue + (index / 100) * dialContainer.valueRange
                    rotation: 180 + dialContainer.valueToAngle(val)
                    Rectangle {
                        x: 85
                        y: -1
                        width: index % 10 === 0 ? 8 : 4
                        height: 2
                        color: index % 10 === 0 ? "#ffffff" : "#444"
                    }
                }
            }

            Repeater {
                model: 50
                Item {
                    property real val: dialContainer.minValue + (index / 50) * dialContainer.valueRange
                    rotation: 180 + dialContainer.valueToAngle(val)
                    Rectangle {
                        x: 76
                        y: -1
                        width: 2
                        height: 2
                        radius: 1
                        color: "#555"
                    }
                }
            }

            Repeater {
                model: [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
                Item {
                    property real val: modelData
                    rotation: 180 + dialContainer.valueToAngle(val)
                    Text {
                        x: 120 // Dịch chữ số vào trong một chút để không sát mép viền ngoài
                        y: -height / 2
                        text: modelData
                        color: "#888"
                        font.pixelSize: 9
                        font.family: "JetBrainsMono Nerd Font"
                        // Chống lật chữ và bù trừ góc xoay -90 của toàn bộ Container
                        rotation: -dial.rotation - parent.rotation + 90
                    }
                }
            }
        }

        // Kim chỉ tĩnh nằm ngang (Nay sẽ thành nằm dọc chỉ xuống do xoay -90)
        Item {
            anchors.centerIn: parent
            Rectangle {
                x: -120
                y: -1
                width: 12
                height: 2
                color: "#cba6ff"
            }
            Shape {
                x: -115
                ShapePath {
                    fillColor: "#cba6ff"
                    startX: 0; startY: -4
                    PathLine { x: -5; y: 0 }
                    PathLine { x: 0; y: 4 }
                    PathLine { x: 0; y: -4 }
                }
            }
        }

        // Text hiển thị tần số
        Item {
            // Tọa độ tính trong hệ quy chiếu đã bị xoay -90 độ
            // Thay đổi x để kéo chữ lên/xuống. Giá trị x càng nhỏ thì chữ càng gần tâm (nóc màn hình)
            x: 80
            y: 115
            width: 60
            height: 50
            rotation: 90 // Bù trừ góc xoay để chữ nằm thẳng đứng
            
            Text {
                id: freqText
                anchors.centerIn: parent
                text: dialContainer.currentValue.toFixed(1)
                color: "white"
                font.pixelSize: 22
                font.bold: true
            }
            Text {
                anchors.top: freqText.bottom
                anchors.horizontalCenter: freqText.horizontalCenter
                anchors.topMargin: 2
                text: "VOLUME"
                color: "#888"
                font.pixelSize: 8
            }
        }

        // Nhận diện lăn chuột (scroll wheel)
        MouseArea {
            anchors.fill: parent
            onWheel: (wheel) => {
                let step = 2.0 // Âm lượng thường thay đổi 2% mỗi nấc
                let direction = wheel.angleDelta.y > 0 ? 1 : -1
                let newVal = dialContainer.currentValue + direction * step
                
                if (newVal < dialContainer.minValue) newVal = dialContainer.minValue
                if (newVal > dialContainer.maxValue) newVal = dialContainer.maxValue
                
                dialContainer.currentValue = newVal
                
                // Sử dụng lệnh wpctl của hệ thống thay vì Pipewire Module để tránh lỗi unbound
                sidebarWindow.internalChange = true
                volumeCommand.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (newVal / 100.0).toFixed(2)]
                volumeCommand.running = true
                
                // Gia hạn thời gian tắt OSD nếu người dùng đang cuộn
                if (sidebarWindow.isOsdOpen) {
                    osdTimer.restart()
                }
                
                // Đặt lại cờ internalChange sau 100ms
                resetTimer.restart()
            }
        }
    }
    
    // Lệnh gọi hệ thống để đổi âm lượng
    Process {
        id: volumeCommand
    }
    
    // Timer đặt lại cờ
    Timer {
        id: resetTimer
        interval: 100
        onTriggered: sidebarWindow.internalChange = false
    }
}
