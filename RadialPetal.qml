import QtQuick

Item {
    id: rootPetal
    anchors.fill: parent

    property int petalIndex: 0
    property bool isActive: false
    
    property string labelText: ""
    property string valueText: ""
    property color colorBg: "#393939"
    property color colorText: "#a9b1d6"
    property color colorHover: "#0db9d7"
    
    property real maxValue: 12
    property real petalValue: parseFloat(valueText) || 0
    
    property real rOut: 110
    property real petalW: 10
    property real petalG: 8

    Canvas {
        id: bgCanvas
        anchors.fill: parent
        opacity: 0.2 // Độ trong suốt áp dụng cho toàn bộ hình vẽ, không bị lỗi đè viền
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            var cx = width / 2;
            var cy = height / 2;
            
            var shift = (rootPetal.petalW + rootPetal.petalG) / 2;
            var A = Math.PI / 8;
            var sliceAngle = 45 * Math.PI / 180;
            var R = rootPetal.rOut - rootPetal.petalW / 2;
            var d = shift / Math.sin(A);
            var angleOffset = Math.asin(shift / R);

            ctx.lineWidth = rootPetal.petalW;
            ctx.lineJoin = "round";
            
            var centerAngle = rootPetal.petalIndex * sliceAngle - Math.PI/2;
            
            ctx.translate(cx, cy);
            ctx.rotate(centerAngle);
            
            // Vẽ nền (Track) bằng màu gốc của cánh hoa
            ctx.beginPath();
            ctx.moveTo(d, 0);
            ctx.arc(0, 0, R, -A + angleOffset, A - angleOffset);
            ctx.closePath();
            
            ctx.fillStyle = rootPetal.colorBg;
            ctx.strokeStyle = rootPetal.colorBg;
            ctx.stroke();
            ctx.fill();
        }
    }

    Canvas {
        id: fgCanvas
        anchors.fill: parent
        
        Connections {
            target: rootPetal
            function onIsActiveChanged() { fgCanvas.requestPaint(); }
        }
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            var cx = width / 2;
            var cy = height / 2;
            
            var shift = (rootPetal.petalW + rootPetal.petalG) / 2;
            var A = Math.PI / 8;
            var sliceAngle = 45 * Math.PI / 180;
            var R = rootPetal.rOut - rootPetal.petalW / 2;
            var d = shift / Math.sin(A);
            
            var percentage = Math.max(0.01, Math.min(1.0, rootPetal.petalValue / rootPetal.maxValue));
            var R_val = d + (R - d) * percentage;
            var angleOffset_val = Math.asin(shift / R_val);

            ctx.lineWidth = rootPetal.petalW;
            ctx.lineJoin = "round";
            
            var centerAngle = rootPetal.petalIndex * sliceAngle - Math.PI/2;
            
            ctx.translate(cx, cy);
            ctx.rotate(centerAngle);
            
            // Vẽ cánh hoa nhỏ hơn bên trong theo % giá trị
            ctx.beginPath();
            ctx.moveTo(d, 0);
            ctx.arc(0, 0, R_val, -A + angleOffset_val, A - angleOffset_val);
            ctx.closePath();
            
            if (rootPetal.isActive) {
                ctx.fillStyle = rootPetal.colorHover;
                ctx.strokeStyle = rootPetal.colorHover;
            } else {
                ctx.fillStyle = rootPetal.colorBg;
                ctx.strokeStyle = rootPetal.colorBg;
            }
            
            ctx.stroke();
            ctx.fill();
        }
    }

    // Phần hiển thị nội dung Text của từng cánh
    Item {
        property real rMid: (rootPetal.rOut + 20) / 2
        property real angle: (rootPetal.petalIndex * 45 - 90) * Math.PI / 180
        
        x: rootPetal.width / 2 + Math.cos(angle) * rMid
        y: rootPetal.height / 2 + Math.sin(angle) * rMid
        width: 1; height: 1 // anchor point để căn giữa
        
        Column {
            anchors.centerIn: parent
            spacing: 2
            
            Text {
                text: rootPetal.valueText
                color: rootPetal.colorText
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 20; bold: true }
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: rootPetal.labelText
                color: rootPetal.colorText
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 10 }
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
