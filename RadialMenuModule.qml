import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: rootRadial
    implicitWidth: 260
    implicitHeight: 260
    Layout.alignment: Qt.AlignCenter

    property real prevCpuTotal: 0
    property real prevCpuIdle: 0

    property alias model: menuModel

    ListModel {
        id: menuModel
        ListElement { label: "RAM"; value: "0"; bg: "#505050"; color: "#a9b1d6"; max: 100 }
        ListElement { label: "CPU"; value: "0"; bg: "#d0d0d0"; color: "#1a1b26"; max: 100 }
        ListElement { label: "Disk"; value: "0"; bg: "#e0e0e0"; color: "#1a1b26"; max: 100 }
        ListElement { label: "Admiration"; value: "5"; bg: "#707070"; color: "#a9b1d6"; max: 12 }
        ListElement { label: "Surprise"; value: "12"; bg: "#d0d0d0"; color: "#1a1b26"; max: 12 }
        ListElement { label: "Sadness"; value: "6"; bg: "#606060"; color: "#a9b1d6"; max: 12 }
        ListElement { label: "Fear"; value: "4"; bg: "#404040"; color: "#a9b1d6"; max: 12 }
        ListElement { label: "Anger"; value: "2"; bg: "#505050"; color: "#a9b1d6"; max: 12 }
    }

    function updateData(cpu, ram, disk) {
        menuModel.setProperty(0, "value", ram.toString());
        menuModel.setProperty(1, "value", cpu.toString());
        menuModel.setProperty(2, "value", disk.toString());
    }

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
                console.log("Clicked petal: " + rootRadial.model.get(rootRadial.activeIndex).label);
            }
        }
    }

    Repeater {
        model: rootRadial.model
        RadialPetal {
            petalIndex: index
            isActive: rootRadial.activeIndex === index
            labelText: label
            valueText: value
            colorBg: bg
            colorText: color
            colorHover: rootRadial.colorHover
            maxValue: max !== undefined ? max : 12
            // Bạn có thể truyền rOut, W, G xuống nếu muốn tùy biến từng cánh!
        }
    }

    Process {
        id: sysProc
        command: ["sh", "-c", "read -r _ a b c d e f g h _ < /proc/stat; echo \"CPU $((a+b+c+d+e+f+g+h)) $((d+e))\"; awk '/^MemTotal:/{mt=$2}/^MemAvailable:/{ma=$2}END{print \"MEM\",mt,ma}' /proc/meminfo; df -P / | awk 'NR==2{gsub(\"%\",\"\",$5);print \"DISK \"$5}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                var cpuVal = rootRadial.model.get(1).value;
                var ramVal = rootRadial.model.get(0).value;
                var diskVal = rootRadial.model.get(2).value;
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].trim().split(/\s+/);
                    if (p[0] === "CPU") {
                        var total = parseFloat(p[1]);
                        var idle = parseFloat(p[2]);
                        if (rootRadial.prevCpuTotal > 0) {
                            var dt = total - rootRadial.prevCpuTotal;
                            var di = idle - rootRadial.prevCpuIdle;
                            cpuVal = dt > 0 ? Math.max(0, Math.min(100, Math.round(100 * (dt - di) / dt))) : 0;
                        }
                        rootRadial.prevCpuTotal = total;
                        rootRadial.prevCpuIdle = idle;
                    } else if (p[0] === "MEM") {
                        var mt = parseFloat(p[1]);
                        var ma = parseFloat(p[2]);
                        ramVal = mt > 0 ? Math.round(100 * (mt - ma) / mt) : 0;
                    } else if (p[0] === "DISK") {
                        diskVal = parseInt(p[1], 10) || 0;
                    }
                }
                rootRadial.updateData(cpuVal, ramVal, diskVal);
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: sysProc.running = true
    }

    Component.onCompleted: sysProc.running = true
}
