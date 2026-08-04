import QtQuick
import QtQuick.Layouts

Rectangle {
    id: rootCal
    color: "transparent"
    implicitWidth: 260
    implicitHeight: rootCal.activeTab === 0 ? 280 : 330 // Tự động kéo dài ra một chút khi xem full tháng
    
    Behavior on implicitHeight { NumberAnimation { duration: 200 } }
    
    // Properties for easy theming
    property color colorBg: "#1a1819"
    property color colorFg: "#ffffff"
    property color colorMuted: "#a9b1d6"
    property color colorAccent: "#0db9d7"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int activeTab: 0 // 0: Weekly, 1: Monthly
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 16
        
        // 1. Header: Weekly / Monthly + Settings
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            
            // Segmented Button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 12
                color: Qt.alpha(rootCal.colorBg, 0.3)
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4
                    
                    // Tab: Weekly
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: rootCal.activeTab === 0 ? rootCal.colorFg : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Weekly"
                            color: rootCal.activeTab === 0 ? "#1a1b26" : rootCal.colorMuted
                            font.family: rootCal.fontFamily
                            font.pixelSize: 13
                            font.bold: rootCal.activeTab === 0
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rootCal.activeTab = 0
                        }
                        
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    
                    // Tab: Monthly
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: rootCal.activeTab === 1 ? rootCal.colorFg : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Monthly"
                            color: rootCal.activeTab === 1 ? "#1a1b26" : rootCal.colorMuted
                            font.family: rootCal.fontFamily
                            font.pixelSize: 13
                            font.bold: rootCal.activeTab === 1
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rootCal.activeTab = 1
                        }
                        
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }
            
            // Settings Button
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 12
                color: Qt.alpha(rootCal.colorBg, 0.3)
                
                Text {
                    anchors.centerIn: parent
                    text: "" // Gear icon
                    color: rootCal.colorMuted
                    font.family: rootCal.fontFamily
                    font.pixelSize: 16
                }
            }
        }
        
        Item { Layout.preferredHeight: 4 } // Spacer
        
        // 2. Month and Date
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: rootCal.activeTab === 0 ? 0 : -10 // Kéo ngược lên trên một chút khi ở Monthly
            
            Text {
                text: "April"
                color: rootCal.colorFg
                font.family: rootCal.fontFamily
                font.pixelSize: rootCal.activeTab === 0 ? 42 : 20
                font.weight: rootCal.activeTab === 0 ? Font.Light : Font.Bold
                Layout.fillWidth: true
                
                // Hiệu ứng mượt mà khi thay đổi kích thước chữ
                Behavior on font.pixelSize { NumberAnimation { duration: 200 } }
            }
            
            Text {
                text: "21"
                color: rootCal.colorFg
                font.family: rootCal.fontFamily
                font.pixelSize: 42
                font.weight: Font.Light
                visible: rootCal.activeTab === 0
            }
        }
        
        Item { 
            Layout.preferredHeight: rootCal.activeTab === 0 ? 4 : 0 
            visible: rootCal.activeTab === 0
        } // Spacer
        
        // 3. Days of the week row
        GridLayout {
            columns: 7
            columnSpacing: 0
            rowSpacing: rootCal.activeTab === 0 ? 10 : 2 // Thu hẹp khoảng cách giữa các hàng ngày trong tháng
            Layout.fillWidth: true
            
            // Headers
            Repeater {
                model: ["S", "M", "T", "W", "T", "F", "S"]
                Text {
                    text: modelData
                    color: rootCal.colorMuted
                    font.family: rootCal.fontFamily
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
            }
            
            // Dates
            Repeater {
                model: rootCal.activeTab === 0 
                       ? [18, 19, 20, 21, 22, 23, 24] 
                       : [ 31,  1,  2,  3,  4,  5,  6,
                            7,  8,  9, 10, 11, 12, 13,
                           14, 15, 16, 17, 18, 19, 20,
                           21, 22, 23, 24, 25, 26, 27,
                           28, 29, 30,  1,  2,  3,  4]
                           
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    
                    Rectangle {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        radius: 8
                        color: (modelData === 21 && (rootCal.activeTab === 0 || index === 21)) ? rootCal.colorFg : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: modelData.toString()
                            color: {
                                if (modelData === 21 && (rootCal.activeTab === 0 || index === 21)) return "#1a1b26";
                                if (rootCal.activeTab === 1 && (index < 1 || index > 30)) return Qt.alpha(rootCal.colorFg, 0.3);
                                return rootCal.colorFg;
                            }
                            font.family: rootCal.fontFamily
                            font.pixelSize: 15
                        }
                    }
                    
                    // Event dots under the date
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -6
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 4
                        height: 4
                        radius: 2
                        color: rootCal.colorMuted
                        visible: modelData === 18 || modelData === 19 || modelData === 22 || modelData === 24 || 
                                 (rootCal.activeTab === 1 && (modelData === 5 || modelData === 12 || modelData === 28))
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
                font.pixelSize: 13
                Layout.fillWidth: true
                Layout.leftMargin: 4
            }
            
            Rectangle {
                Layout.preferredWidth: 100
                Layout.preferredHeight: 32
                radius: 16
                color: Qt.alpha(rootCal.colorBg, 0.4)
                
                Text {
                    anchors.centerIn: parent
                    text: "+ New Event"
                    color: rootCal.colorFg
                    font.family: rootCal.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }
    }
}
