import QtQuick

Item {
    id: root

    property string text: ""
    property color color: "#ffffff"
    property real pixelSize: 14
    property int weight: Font.Normal
    property string fontFamily: ""
    property bool bold: false
    property int horizontalAlignment: Text.AlignLeft

    property real scrollX: 0

    implicitHeight: label.implicitHeight
    clip: true

    readonly property bool overflowing: label.implicitWidth > root.width

    Row {
        id: container
        anchors.verticalCenter: parent.verticalCenter
        x: root.overflowing ? Math.round(root.scrollX) : (root.horizontalAlignment === Text.AlignHCenter ? (root.width - label.implicitWidth) / 2 : (root.horizontalAlignment === Text.AlignRight ? root.width - label.implicitWidth : 0))
        spacing: 30

        Text {
            id: label
            text: root.text
            color: root.color
            font.family: root.fontFamily
            font.pixelSize: root.pixelSize
            font.weight: root.weight
            font.bold: root.bold
            elide: Text.ElideNone
            onTextChanged: root.sync()
        }

        Text {
            id: label2
            text: root.text
            color: root.color
            font.family: root.fontFamily
            font.pixelSize: root.pixelSize
            font.weight: root.weight
            font.bold: root.bold
            elide: Text.ElideNone
            visible: root.overflowing
        }
    }

    SequentialAnimation {
        id: anim
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "scrollX"
            from: 0
            to: -(label.implicitWidth + 30)
            duration: (label.implicitWidth + 30) * 35
            easing.type: Easing.Linear
        }
    }

    onOverflowingChanged: sync()
    Component.onCompleted: sync()
    onWidthChanged: sync()

    function sync() {
        anim.stop();
        root.scrollX = 0;
        if (overflowing)
            anim.start();
    }
}
