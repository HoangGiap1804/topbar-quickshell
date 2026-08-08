import QtQuick
import QtQuick.Layouts

Rectangle {
    id: rootCal
    color: "transparent"
    implicitWidth: 260
    implicitHeight: 260
    
    Behavior on implicitHeight { NumberAnimation { duration: 200 } }
    
    // Properties for easy theming
    property color colorBg: "#1a1819"
    property color colorFg: "#ffffff"
    property color colorMuted: "#a9b1d6"
    property color colorAccent: "#0db9d7"
    property string fontFamily: "JetBrainsMono Nerd Font"
    
    property var todayDate: new Date()
    property var currentDate: new Date()
    property string monthName: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][currentDate.getMonth()]
    property int currentDay: currentDate.getDate()
    
    property var monthlyDates: []
    
    function updateCalendar() {
        var tempMonth = [];
        var firstDayOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
        var startOffset = firstDayOfMonth.getDay();
        var startDate = new Date(firstDayOfMonth);
        startDate.setDate(firstDayOfMonth.getDate() - startOffset);
        
        for (var j = 0; j < 42; j++) {
            var md = new Date(startDate);
            md.setDate(startDate.getDate() + j);
            tempMonth.push({ day: md.getDate(), isCurrentMonth: md.getMonth() === currentDate.getMonth(), isToday: md.toDateString() === todayDate.toDateString() });
        }
        monthlyDates = tempMonth;
    }
    
    Component.onCompleted: updateCalendar()
    
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date();
            if (now.getDate() !== todayDate.getDate() || now.getMonth() !== todayDate.getMonth()) {
                todayDate = now;
                updateCalendar();
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 8
        
        
        Item { Layout.fillHeight: true } // Top spacer to vertically center the calendar

        // 2. Month and Date
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: -10
            
            Text {
                text: ""
                color: rootCal.colorMuted
                font.family: rootCal.fontFamily
                font.pixelSize: 14
                
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    onClicked: {
                        var d = new Date(rootCal.currentDate);
                        d.setMonth(d.getMonth() - 1);
                        rootCal.currentDate = d;
                        rootCal.updateCalendar();
                    }
                }
            }
            
            Item { Layout.fillWidth: true }
            
            Text {
                text: rootCal.monthName + " " + rootCal.currentDate.getFullYear()
                color: rootCal.colorFg
                font.family: rootCal.fontFamily
                font.pixelSize: 16
                font.weight: Font.Bold
                
                // Hiệu ứng mượt mà khi thay đổi kích thước chữ
                Behavior on font.pixelSize { NumberAnimation { duration: 200 } }
            }
            
            Item { Layout.fillWidth: true }
            
            Text {
                text: ""
                color: rootCal.colorMuted
                font.family: rootCal.fontFamily
                font.pixelSize: 14
                
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    onClicked: {
                        var d = new Date(rootCal.currentDate);
                        d.setMonth(d.getMonth() + 1);
                        rootCal.currentDate = d;
                        rootCal.updateCalendar();
                    }
                }
            }
        }
        
        // 3. Days of the week row
        GridLayout {
            columns: 7
            columnSpacing: 0
            rowSpacing: 0 // Thu hẹp khoảng cách giữa các hàng ngày trong tháng
            Layout.fillWidth: true
            
            // Headers
            Repeater {
                model: ["S", "M", "T", "W", "T", "F", "S"]
                Text {
                    text: modelData
                    color: rootCal.colorMuted
                    font.family: rootCal.fontFamily
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
            }
            
            // Dates
            Repeater {
                model: rootCal.monthlyDates
                           
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    
                    Rectangle {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        radius: 6
                        color: modelData.isToday ? rootCal.colorFg : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: modelData.day.toString()
                            color: {
                                if (modelData.isToday) return "#1a1b26";
                                if (!modelData.isCurrentMonth) return Qt.alpha(rootCal.colorFg, 0.3);
                                return rootCal.colorFg;
                            }
                            font.family: rootCal.fontFamily
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
        
        Item { Layout.fillHeight: true } // Flexible spacer to push footer to bottom
        
        // 4. Footer Buttons
        RowLayout {
            Layout.fillWidth: true
            
            Text {
                text: "󰂚 Add Reminder" // Bell icon + text
                color: rootCal.colorMuted
                font.family: rootCal.fontFamily
                font.pixelSize: 11
                Layout.fillWidth: true
                Layout.leftMargin: 4
            }
            
            Rectangle {
                Layout.preferredWidth: 86
                Layout.preferredHeight: 26
                radius: 13
                color: Qt.alpha(rootCal.colorBg, 0.4)
                
                Text {
                    anchors.centerIn: parent
                    text: "+ New Event"
                    color: rootCal.colorFg
                    font.family: rootCal.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                }
            }
        }
    }
}
