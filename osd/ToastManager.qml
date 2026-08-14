import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications

PanelWindow {
    id: toastWindow
    
    // Properties passed from root
    property color colBg: "#1a1819"
    property color colFg: "#a9b1d6"
    property color colCyan: "#0db9d7"
    property color colYellow: "#e0af68"
    property string fontFamily: "sans-serif"
    property int fontSize: 14
    
    anchors.top: true
    anchors.right: true
    anchors.bottom: true
    
    margins.right: 0
    margins.top: 0
    
    implicitWidth: 350
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    
    // Sử dụng mask để chỉ nhận click ở khu vực có thông báo thực sự
    // Các phần trong suốt bên dưới sẽ không chặn click của người dùng
    mask: Region {
        width: 350
        height: toastListView.contentHeight + 20
    }
    
    ListModel {
        id: toastModel
    }
    
    function show(msg, type) {
        let tTitle = "Info";
        if (type === "success") tTitle = "Success";
        else if (type === "warning") tTitle = "Warning";
        else if (type === "critical") tTitle = "Critical";
        
        showCustom(tTitle, msg, type);
    }
    
    // Hàm mới hỗ trợ truyền cả Title tùy ý (dành cho thông báo hệ thống)
    function showCustom(title, msg, type) {
        let tColor = "#ffffff"; // Mặc định màu trắng (normal)
        let tDuration = 10000;          // Mặc định 10s
        
        if (type === "low") {
            tColor = "#565f89";         // Màu xám
            tDuration = 3000;           // 3s
        } else if (type === "critical") {
            tColor = "#f7768e";         // Màu đỏ
            tDuration = 30000;          // 30s
        }
        
        toastModel.insert(0, {
            "title": title,
            "message": msg,
            "colorHex": tColor,
            "durationMs": tDuration
        });
    }
    
    // Server lắng nghe thông báo thực tế từ máy tính qua D-Bus
    NotificationServer {
        imageSupported: true 
        onNotification: function(notification) {
            // Urgency trong Linux: 0 = Low, 1 = Normal, 2 = Critical (enum NotificationUrgency)
            let type = "normal";
            if (notification.urgency === NotificationUrgency.Low || notification.urgency === 0) {
                type = "low";
            } else if (notification.urgency === NotificationUrgency.Critical || notification.urgency === 2) {
                type = "critical";
            }
            
            toastWindow.showCustom(
                notification.summary, 
                notification.body || "", 
                type
            );
        }
    }
    
    ListView {
        id: toastListView
        width: parent.width
        height: parent.height
        model: toastModel
        spacing: 12
        interactive: false
        
        topMargin: 20
        
        add: Transition {
            NumberAnimation { property: "y"; from: -200; duration: 400; easing.type: Easing.OutQuint }
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 300 }
        }
        
        remove: Transition {
            // Trượt sang phải màn hình (x = 400) để biến mất
            NumberAnimation { property: "x"; to: 400; duration: 400; easing.type: Easing.InQuint }
            NumberAnimation { property: "opacity"; to: 0; duration: 400 }
        }
        
        displaced: Transition {
            NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutQuint }
        }
        
        delegate: ToastModule {
            titleText: model.title
            messageText: model.message
            colorHex: model.colorHex
            colorHexStr: String(model.colorHex) // Ép kiểu thành chuỗi 6 ký tự hoặc mã màu chuẩn
            colorBg: toastWindow.colBg
            colorFg: toastWindow.colFg
            fontFamily: toastWindow.fontFamily
            fontSize: toastWindow.fontSize
            durationMs: model.durationMs || 10000
            
            onTimeout: {
                toastModel.remove(index)
            }
        }
    }
}
