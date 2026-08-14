import QtQuick
import QtQuick.Layouts

Item {
    id: rootTask
    property string text: "Task"
    property bool isDone: false
    property color colorText: "#a9b1d6"
    property color colorDone: "#444b6a"
    property color colorAccent: "#0db9d7"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    Layout.fillWidth: true
    Layout.preferredHeight: 32
    
    implicitWidth: 200
    implicitHeight: 32

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Rectangle {
            implicitWidth: 20
            implicitHeight: 20
            radius: 6
            color: rootTask.isDone ? rootTask.colorAccent : "transparent"
            border.color: rootTask.isDone ? rootTask.colorAccent : rootTask.colorDone
            border.width: 2
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "" // check icon
                color: "#1a1b26"
                visible: rootTask.isDone
                font { family: rootTask.fontFamily; pixelSize: 12; bold: true }
            }
        }

        Text {
            text: rootTask.text
            color: rootTask.isDone ? rootTask.colorDone : rootTask.colorText
            font { family: rootTask.fontFamily; pixelSize: rootTask.fontSize; strikeout: rootTask.isDone }
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: rootTask.isDone = !rootTask.isDone
    }
}
