import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes

Item {
    id: root

    property real currentValue: 50.0
    property real minValue: 0.0
    property real maxValue: 100.0
    property string labelText: "VOLUME"
    property color accentColor: "#7a42ff"
    
    // Thuộc tính để nhận biết trạng thái mở/đóng và xử lý animation trượt
    property bool isOpen: false
    
    signal scrolled(real newValue)

    property real angleRange: 270
    property real valueRange: maxValue - minValue
    function valueToAngle(val) {
        // Đảo ngược chiều để 0 ở bên trái và 100 ở bên phải
        return (0.5 - (val - minValue) / valueRange) * angleRange
    }

    // Đĩa quay chứa toàn bộ UI
    Item {
        id: dialContainer
        width: 280
        height: 280
        
        // Căn vị trí 3/4 màn hình (lệch sang 1/4 bên phải)
        x: (parent.width * 0.75) - (width / 2)
        
        // Trượt lên xuống dựa vào trạng thái isOpen
        y: root.isOpen ? -140 : -280
        
        Behavior on y {
            NumberAnimation {
                duration: root.isOpen ? 400 : 250
            }
        }
        
        rotation: -90 // Xoay tổng thể -90 độ để các vạch tỏa ra từ dưới lên

        // Nền nguyên khối (Vẽ toàn bộ hình tròn và 2 góc fillet bằng 1 đường liền mạch)
        Shape {
            anchors.fill: parent
            antialiasing: true
            
            ShapePath {
                fillGradient: LinearGradient {
                    // Do Shape bị xoay -90 độ, trục X nội bộ trở thành trục Y trên màn hình
                    // x=140 tương đương với Top (trần màn hình), x=0 tương đương với Bottom (mép dưới vòng cung)
                    x1: 140; y1: 0
                    x2: 0; y2: 0
                    GradientStop { position: 0.0; color: "#ff000000" } // Đen đặc ở sát mép trên
                    GradientStop { position: 1.0; color: "#77000000" } // Trong suốt mờ dần xuống dưới
                }
                strokeColor: Qt.alpha(root.accentColor, 0.5)
                strokeWidth: 1
                
                // Mép trái trần (Physical Left)
                startX: 140; startY: 320
                
                // Điểm chạm vào vòng tròn bên trái
                PathQuad { controlX: 140; controlY: 278.5; x: 120; y: 278.5 }
                
                // Vòng cung đĩa quay
                PathArc {
                    x: 120; y: 1.5
                    radiusX: 140; radiusY: 140
                    direction: PathArc.CounterClockwise
                }
                
                // Bo góc lõm bên phải nối lên trần màn hình
                PathQuad { controlX: 140; controlY: 1.5; x: 140; y: -40 }
                
                // Đường trần nối lại về điểm xuất phát
                PathLine { x: 140; y: 320 }
            }
        }

        // Vòng cung Glow với hiệu ứng Neon Blur
        Shape {
            anchors.fill: parent
            antialiasing: true
            layer.enabled: true
            layer.samples: 4
            
            // === Lớp Glow 1 (Rộng nhất, mờ nhất) ===
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha(root.accentColor, 0.05)
                strokeWidth: 24
                capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: 140; centerY: 140; radiusX: 110; radiusY: 110; startAngle: 45; sweepAngle: 135 }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha(root.accentColor, 0.05)
                strokeWidth: 24
                capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: 140; centerY: 140; radiusX: 110; radiusY: 110; startAngle: 180; sweepAngle: 135 }
            }

            // === Lớp Glow 2 (Trung bình) ===
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha(root.accentColor, 0.15)
                strokeWidth: 12
                capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: 140; centerY: 140; radiusX: 110; radiusY: 110; startAngle: 45; sweepAngle: 135 }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha(root.accentColor, 0.15)
                strokeWidth: 12
                capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: 140; centerY: 140; radiusX: 110; radiusY: 110; startAngle: 180; sweepAngle: 135 }
            }

            // === Lớp Glow 3 (Sáng bao quanh lõi) ===
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha(root.accentColor, 0.4)
                strokeWidth: 6
                capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: 140; centerY: 140; radiusX: 110; radiusY: 110; startAngle: 45; sweepAngle: 135 }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha(root.accentColor, 0.4)
                strokeWidth: 6
                capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: 140; centerY: 140; radiusX: 110; radiusY: 110; startAngle: 180; sweepAngle: 135 }
            }

            // === Lõi viền sắc nét (Viền nhỏ bên trong cùng) ===
            ShapePath {
                fillColor: "transparent"
                strokeColor: root.accentColor
                strokeWidth: 2
                capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: 140; centerY: 140; radiusX: 110; radiusY: 110; startAngle: 45; sweepAngle: 135 }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: root.accentColor
                strokeWidth: 2
                capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: 140; centerY: 140; radiusX: 110; radiusY: 110; startAngle: 180; sweepAngle: 135 }
            }
        }

        // --- Phần đĩa xoay theo giá trị ---
        Item {
            id: dial
            anchors.fill: parent
            
            // Xoay toàn bộ Item này để kim đồng hồ quay
            rotation: -root.valueToAngle(root.currentValue)
            Behavior on rotation {
                NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
            }
            
            // Lõi tròn ở giữa (tuỳ chọn)
            Rectangle {
                anchors.centerIn: parent
                width: 140
                height: 140
                radius: 70
                color: "transparent"
            }

            Repeater {
                model: 100
                Item {
                    anchors.centerIn: parent
                    property real val: root.minValue + (index / 100) * root.valueRange
                    rotation: 180 + root.valueToAngle(val)
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
                    anchors.centerIn: parent
                    property real val: root.minValue + (index / 50) * root.valueRange
                    rotation: 180 + root.valueToAngle(val)
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
                    anchors.centerIn: parent
                    property real val: modelData
                    rotation: 180 + root.valueToAngle(val)
                    Text {
                        x: 120
                        y: -height / 2
                        text: modelData
                        color: "#888"
                        font.pixelSize: 9
                        font.family: "JetBrainsMono Nerd Font"
                        // Chống lật chữ và bù trừ góc xoay
                        rotation: -dial.rotation - parent.rotation + 90
                    }
                }
            }
        }

        // Kim chỉ tĩnh nằm dọc chỉ xuống do xoay -90
        Item {
            anchors.centerIn: parent
            
            // Nhãn chỉ báo (Đổi theo Mode)
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 35
                text: root.labelText
                color: root.accentColor
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 10; bold: true; letterSpacing: 2 }
                transform: Rotation { origin.x: width/2; origin.y: height/2; angle: 90 }
            }
            
            Rectangle {
                x: -120
                y: -1
                width: 12
                height: 2
                color: root.accentColor
            }
            Shape {
                x: -115
                ShapePath {
                    fillColor: root.accentColor
                    startX: 0; startY: -4
                    PathLine { x: -5; y: 0 }
                    PathLine { x: 0; y: 4 }
                    PathLine { x: 0; y: -4 }
                }
            }
        }

        // Text hiển thị giá trị
        Item {
            // Tọa độ tính trong hệ quy chiếu đã bị xoay -90 độ
            x: 80
            y: 115
            width: 60
            height: 50
            rotation: 90
            
            Text {
                id: freqText
                anchors.centerIn: parent
                text: root.currentValue.toFixed(1)
                color: "white"
                font.pixelSize: 22
                font.bold: true
            }
            Text {
                anchors.top: freqText.bottom
                anchors.horizontalCenter: freqText.horizontalCenter
                anchors.topMargin: 2
                text: root.labelText
                color: root.accentColor
                font.pixelSize: 8
            }
        }

        // Nhận diện lăn chuột (scroll wheel)
        MouseArea {
            anchors.fill: parent
            onWheel: (wheel) => {
                let step = 2.0
                let direction = wheel.angleDelta.y > 0 ? 1 : -1
                let newVal = root.currentValue + direction * step
                
                if (newVal < root.minValue) newVal = root.minValue
                if (newVal > root.maxValue) newVal = root.maxValue
                
                // Gửi signal cho parent
                root.scrolled(newVal)
            }
        }
    }
}
