import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Row {
    spacing: 8
    Layout.columnSpan: 2
    Layout.alignment: Qt.AlignHCenter

    property color colCyan: "#0db9d7"
    property color colBlue: "#7aa2f7"
    property color colMuted: "#444b6a"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    Repeater {
        model: 9
        Text {
            property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
            property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
            text: index + 1
            color: isActive ? colCyan : (ws ? colBlue : colMuted)
            font { family: fontFamily; pixelSize: fontSize; bold: true }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + (index + 1))
            }
        }
    }
}
