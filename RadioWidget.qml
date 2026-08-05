import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

Rectangle {
    id: root
    width: 450
    height: 300
    color: "#0a0a0c"
    radius: 16
    clip: true

    property real currentValue: 98.8
    property real minValue: 88.0
    property real maxValue: 108.0
    
    property real angleRange: 160 // Dải góc cho các vạch (từ 88 đến 108)
    property real valueRange: maxValue - minValue
    
    // Hàm chuyển đổi từ giá trị sang góc trên đĩa
    function valueToAngle(val) {
        return ((val - minValue) / valueRange - 0.5) * angleRange
    }

    // Các vòng cung tĩnh bên ngoài
    Shape {
        x: root.width * 0.75
        y: root.height * 0.5
        
        // Nửa dưới (Tím nhạt)
        ShapePath {
            fillColor: "transparent"
            strokeColor: "#cba6ff"
            strokeWidth: 40
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: 0; centerY: 0
                radiusX: 180; radiusY: 180
                startAngle: 90; sweepAngle: 90
            }
        }
        
        // Nửa trên (Tím đậm)
        ShapePath {
            fillColor: "transparent"
            strokeColor: "#7a42ff"
            strokeWidth: 40
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: 0; centerY: 0
                radiusX: 180; radiusY: 180
                startAngle: 180; sweepAngle: 90
            }
        }
    }

    // Đĩa quay chứa vạch và số
    Item {
        id: dial
        x: root.width * 0.75
        y: root.height * 0.5
        
        // Quay để giá trị hiện tại nằm ở 180 độ (nằm ngang bên trái)
        rotation: -root.valueToAngle(root.currentValue)
        
        Behavior on rotation {
            SpringAnimation { spring: 3; damping: 0.3 }
        }

        // Các vạch chia (Dashed ticks)
        Repeater {
            model: 100 // 100 vạch nhỏ
            Item {
                property real val: root.minValue + (index / 100) * root.valueRange
                // Góc ban đầu của vạch (cộng 180 để gốc nằm ở bên trái)
                rotation: 180 + root.valueToAngle(val)
                
                Rectangle {
                    x: 130 // Bán kính vòng vạch nhỏ
                    y: -1
                    width: index % 10 === 0 ? 12 : 6
                    height: 2
                    color: index % 10 === 0 ? "#ffffff" : "#444444"
                }
            }
        }

        // Các chấm nhỏ (Dots) ở vòng trong
        Repeater {
            model: 50
            Item {
                property real val: root.minValue + (index / 50) * root.valueRange
                rotation: 180 + root.valueToAngle(val)
                
                Rectangle {
                    x: 110 // Bán kính vòng chấm nhỏ
                    y: -1.5
                    width: 3
                    height: 3
                    radius: 1.5
                    color: "#555"
                }
            }
        }

        // Số (Numbers)
        Repeater {
            model: [88, 92, 96, 98, 100, 104, 107]
            Item {
                property real val: modelData
                rotation: 180 + root.valueToAngle(val)
                
                Text {
                    // Đặt ra ngoài viền tím (bán kính 180 + 40/2 = 200, cho số ra 230)
                    x: 220 
                    y: -height / 2
                    text: modelData
                    color: "#888"
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                    // Chống lật chữ bằng cách xoay ngược lại với góc quay của đĩa
                    rotation: -dial.rotation - parent.rotation
                }
            }
        }
    }

    // Kim chỉ (Indicator) tĩnh ở bên trái
    Item {
        x: root.width * 0.75
        y: root.height * 0.5
        
        // Vạch ngang của kim
        Rectangle {
            x: -230
            y: -1
            width: 25
            height: 2
            color: "#cba6ff"
        }
        
        // Tam giác kim (chỉ vào trong)
        Shape {
            x: -200
            ShapePath {
                fillColor: "#cba6ff"
                startX: 0; startY: -5
                PathLine { x: -8; y: 0 }
                PathLine { x: 0; y: 5 }
                PathLine { x: 0; y: -5 }
            }
        }
    }
    
    // UI hiển thị tần số ở chính giữa
    Rectangle {
        x: root.width * 0.75 - 120
        y: root.height * 0.5 - 30
        width: 130
        height: 60
        color: "#1a1a24"
        radius: 30
        border.color: "#2a2a34"
        border.width: 1
        
        Text {
            anchors.centerIn: parent
            text: root.currentValue.toFixed(1)
            color: "white"
            font.pixelSize: 32
            font.bold: true
        }
    }
    
    Text {
        x: root.width * 0.75 - 110
        y: root.height * 0.5 - 65
        text: root.currentValue.toFixed(1) + " FM"
        color: "#aaa"
        font.pixelSize: 16
    }
    
    // Tương tác kéo thả chuột / vuốt
    MouseArea {
        anchors.fill: parent
        property real startY: 0
        property real startVal: 0
        
        onPressed: {
            startY = mouseY
            startVal = root.currentValue
        }
        onPositionChanged: {
            let dy = mouseY - startY
            // Kéo xuống (dy > 0) -> số nhỏ lên -> tăng giá trị
            let newVal = startVal + dy / 10.0 
            if (newVal < root.minValue) newVal = root.minValue
            if (newVal > root.maxValue) newVal = root.maxValue
            root.currentValue = newVal
        }
    }
}
