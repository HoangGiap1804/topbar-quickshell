import QtQuick
import QtQuick.Shapes

Shape {
    id: notchBg
    
    property color colBg: "#1a1819"
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
        strokeColor: Qt.alpha(notchBg.colBg, 0.5)
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
