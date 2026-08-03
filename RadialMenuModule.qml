import QtQuick
import QtQuick.Layouts

Item {
    id: rootRadial
    implicitWidth: 260
    implicitHeight: 260
    Layout.alignment: Qt.AlignCenter

    property var model: [
        { label: "Anticipation", value: "5", bg: "#505050", color: "#a9b1d6" },
        { label: "Happiness", value: "12", bg: "#d0d0d0", color: "#1a1b26" },
        { label: "Awe", value: "10", bg: "#e0e0e0", color: "#1a1b26" },
        { label: "Admiration", value: "5", bg: "#707070", color: "#a9b1d6" },
        { label: "Surprise", value: "12", bg: "#d0d0d0", color: "#1a1b26" },
        { label: "Sadness", value: "6", bg: "#606060", color: "#a9b1d6" },
        { label: "Fear", value: "4", bg: "#404040", color: "#a9b1d6" },
        { label: "Anger", value: "2", bg: "#505050", color: "#a9b1d6" }
    ]

    property int activeIndex: -1
    property color colorHover: "#0db9d7"


    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: rootRadial.activeIndex !== -1 ? Qt.PointingHandCursor : Qt.ArrowCursor
        
        function updateHover(mouse) {
            var dx = mouse.x - width / 2;
            var dy = mouse.y - height / 2;
            var r = Math.sqrt(dx*dx + dy*dy);
            
            if (r >= 20 && r <= 110) {
                var angle = Math.atan2(dy, dx) * 180 / Math.PI;
                angle = (angle + 90 + 360) % 360; 
                var index = Math.floor((angle + 22.5) / 45) % 8;
                
                if (rootRadial.activeIndex !== index) {
                    rootRadial.activeIndex = index;
                }
            } else {
                if (rootRadial.activeIndex !== -1) {
                    rootRadial.activeIndex = -1;
                }
            }
        }

        onPositionChanged: (mouse) => updateHover(mouse)
        onExited: {
            if (rootRadial.activeIndex !== -1) {
                rootRadial.activeIndex = -1;
            }
        }
        onClicked: {
            if (rootRadial.activeIndex !== -1) {
                console.log("Clicked petal: " + rootRadial.model[rootRadial.activeIndex].label);
            }
        }
    }

    Repeater {
        model: rootRadial.model
        RadialPetal {
            petalIndex: index
            isActive: rootRadial.activeIndex === index
            labelText: modelData.label
            valueText: modelData.value
            colorBg: modelData.bg
            colorText: modelData.color
            colorHover: rootRadial.colorHover
            // Bạn có thể truyền rOut, W, G xuống nếu muốn tùy biến từng cánh!
        }
    }
}
