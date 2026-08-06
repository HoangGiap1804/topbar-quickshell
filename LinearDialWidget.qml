import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

Item {
    id: root
    
    // Tương tự RotaryDialWidget
    property real minValue: 0
    property real maxValue: 100
    property real stepSize: 5
    property real currentValue: 50
    property color accentColor: "#0db9d7"
    property string titleText: "VOLUME"
    property bool isOpen: false
    
    signal valueChanged(real newValue)
    
    // Kích thước chuẩn dạng pill ngang
    implicitWidth: 320
    implicitHeight: 40
    
    // Thuộc tính cuộn nội bộ
    property real pixelPerUnit: 6 // 1% = 6px
    
    // Slide animation (Bám trần màn hình)
    y: isOpen ? 0 : -height
    Behavior on y {
        NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
    }
    // Vị trí X sẽ được quyết định bởi parent
    
    Shape {
        id: bg
        anchors.fill: parent
        // Bỏ clip: true ở đây để không bị cắt xén phần cong (flare) của Notch
        
        property real slant: 4
        property real flare: 18
        
        ShapePath {
            fillGradient: LinearGradient {
                x1: 0; y1: 0
                x2: 0; y2: bg.height
                GradientStop { position: 0.0; color: "#000000" }
                GradientStop { position: 1.0; color: Qt.alpha("#000000", 0.8) }
            }
            strokeColor: Qt.alpha(root.accentColor, 0.4)
            strokeWidth: 1
            
            startX: -bg.flare; startY: 0
            
            PathCubic { 
                x: bg.slant + bg.flare; y: bg.height
                control1X: 0; control1Y: 0
                control2X: bg.slant; control2Y: bg.height
            }
            
            PathLine { x: bg.width - bg.slant - bg.flare; y: bg.height }
            
            PathCubic {
                x: bg.width + bg.flare; y: 0
                control1X: bg.width - bg.slant; control1Y: bg.height
                control2X: bg.width; control2Y: 0
            }
            
            PathLine { x: -bg.flare; y: 0 }
        }
        
        // Khu vực chứa nội dung (bị cắt xén gọn gàng bên trong Notch)
        Item {
            anchors.fill: parent
            anchors.leftMargin: bg.slant + bg.flare
            anchors.rightMargin: bg.slant + bg.flare
            clip: true
            
            // Container chứa thước kẻ
            Item {
                id: scrollContainer
                height: parent.height
                // Khi giá trị tăng, thước trượt sang trái
                x: (parent.width / 2) - (root.currentValue * root.pixelPerUnit)
                
                Behavior on x {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }
                
                // Vẽ các vạch chính (0, 10, 20...)
            Repeater {
                model: Math.floor((root.maxValue - root.minValue) / 10) + 1
                Item {
                    property int val: root.minValue + index * 10
                    x: val * root.pixelPerUnit
                    y: 0
                    height: bg.height
                    
                    // Tính toán tọa độ x tuyệt đối của vạch trên màn hình để làm mờ
                    property real globalX: scrollContainer.x + x
                    opacity: {
                        if (globalX < 30) return Math.max(0, globalX / 30);
                        if (globalX > bg.width - 120) return Math.max(0, (bg.width - 90 - globalX) / 30);
                        return 1.0;
                    }
                    
                    // Vạch dài
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        width: 2
                        height: 12
                        color: root.accentColor
                    }
                    
                    // Vẽ các vạch phụ nhỏ li ti giữa các vạch chính (cách nhau 2 đơn vị)
                    Repeater {
                        model: index < Math.floor((root.maxValue - root.minValue) / 10) ? 4 : 0
                        Rectangle {
                            x: (index + 1) * 2 * root.pixelPerUnit
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 8
                            width: 1
                            height: 6
                            color: Qt.alpha(root.accentColor, 0.4)
                        }
                    }
                    
                    // Số hiển thị phía trên vạch chính
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 24
                        text: parent.val
                        color: "#a9b1d6"
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                    }
                }
            }
        }
        
        }
        
        // Kim chỉ báo trung tâm
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: 4
            height: bg.height / 2
            color: "#ffffff"
            radius: 2
            
            // Phát sáng nhẹ
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 4
                height: parent.height + 4
                color: Qt.alpha("#ffffff", 0.3)
                radius: 4
                z: -1
            }
        }
        // Hào quang bao quanh chữ
        Shape {
            anchors.centerIn: titleLabel
            width: 80
            height: 40
            opacity: 0.4
            ShapePath {
                fillGradient: RadialGradient {
                    centerX: 40; centerY: 20
                    centerRadius: 40
                    focalX: 40; focalY: 20
                    GradientStop { position: 0.0; color: root.accentColor }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                strokeColor: "transparent"
                startX: 0; startY: 0
                PathLine { x: 80; y: 0 }
                PathLine { x: 80; y: 40 }
                PathLine { x: 0; y: 40 }
                PathLine { x: 0; y: 0 }
            }
        }
        
        // Nhãn hiển thị góc phải
        Text {
            id: titleLabel
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            text: root.titleText
            color: "#a9b1d6"
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            font.bold: true
        }
        
        // Khu vực nhận tương tác cuộn / kéo
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            
            property real startDragX: 0
            property real startValue: 0
            
            onWheel: (wheel) => {
                let delta = wheel.angleDelta.y > 0 ? root.stepSize : -root.stepSize;
                let newVal = root.currentValue + delta;
                if (newVal < root.minValue) newVal = root.minValue;
                if (newVal > root.maxValue) newVal = root.maxValue;
                root.valueChanged(newVal);
            }
            
            onPressed: (mouse) => {
                startDragX = mouse.x;
                startValue = root.currentValue;
            }
            
            onPositionChanged: (mouse) => {
                if (pressed) {
                    let diffX = mouse.x - startDragX;
                    // Kéo sang trái (diffX < 0) -> thanh thước chạy sang trái -> giá trị tăng
                    let deltaVal = -(diffX / root.pixelPerUnit);
                    let newVal = startValue + deltaVal;
                    if (newVal < root.minValue) newVal = root.minValue;
                    if (newVal > root.maxValue) newVal = root.maxValue;
                    root.valueChanged(newVal);
                }
            }
        }
    }
}
