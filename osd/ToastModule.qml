import QtQuick
import QtQuick.Layouts

Item {
    id: rootItem
    width: ListView.view ? ListView.view.width : 350
    
    // Chiều cao tự động dựa trên độ dài của chữ
    implicitHeight: Math.max(60, textContent.implicitHeight + 32)
    
    property string titleText: ""
    property string messageText: ""
    property color colorHex: "#ffffff"
    property color colorBg: "#1a1819"
    property color colorFg: "#a9b1d6"
    property string fontFamily: "sans-serif"
    property int fontSize: 14
    property int durationMs: 10000 // Mặc định 10 giây
    property string colorHexStr: "#ffffff" // Chuỗi hex dùng cho thẻ HTML
    
    signal timeout()
    
    Rectangle {
        anchors.fill: parent
        radius: 12 // Bo góc vuông vức hơn một chút giống ảnh
        
        // Nền tối với độ trong suốt cực thấp
        color: Qt.alpha("#050505", 0.8)
        
        // Viền nhạt màu mờ
        border.color: Qt.alpha(rootItem.colorHex, 0.2)
        border.width: 1
        
        // Thanh dọc màu bên trái
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 14
            width: 3
            radius: 1.5
            color: rootItem.colorHex
            
            // Tùy chọn: Thêm hiệu ứng phát sáng nhẹ nếu Quickshell hỗ trợ DropShadow
            // (Hiện tại giữ nguyên bản màu sáng để tạo tương phản)
        }
        
        Text {
            id: textContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 28 // Nhường chỗ cho thanh dọc
            anchors.rightMargin: 44 // Nhường chỗ cho nút tắt (X)
            verticalAlignment: Text.AlignVCenter
            
            // Format HTML để in đậm Title và để thường Message, với màu Tiêu đề trùng với màu cảnh báo
            textFormat: Text.RichText
            text: "<span style='color:" + rootItem.colorHexStr + "'><b>" + rootItem.titleText + "</b></span><span style='color:" + rootItem.colorFg + "'>: " + rootItem.messageText + "</span>"
            
            font.family: rootItem.fontFamily
            font.pixelSize: rootItem.fontSize - 1 // Chữ nhỏ lại một chút
            wrapMode: Text.Wrap
            lineHeight: 1.3 // Dãn dòng cho dễ nhìn
        }
        
        // Nút tắt (Close Button)
        Rectangle {
            id: closeButton
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            width: 24
            height: 24
            color: closeMouseArea.containsMouse ? Qt.alpha(rootItem.colorFg, 0.1) : "transparent"
            radius: 12
            
            Text {
                anchors.centerIn: parent
                text: "✕"
                color: Qt.alpha(rootItem.colorFg, 0.6)
                font.pixelSize: 12
            }
            
            MouseArea {
                id: closeMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: rootItem.timeout() // Kích hoạt sự kiện tắt ngay lập tức
            }
        }
    }
    
    Timer {
        running: true
        interval: rootItem.durationMs
        onTriggered: {
            rootItem.timeout()
        }
    }
}
