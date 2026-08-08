import Quickshell.Io
import QtQuick

// AppLauncher — hiển thị danh sách kết quả (chỉ có chữ) theo chiều dọc
Item {
    id: launcherRoot

    property var allApps:      []
    property var filteredApps: []
    property int selectedIndex: 0

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int itemH:   36
    readonly property int maxShow: 10

    // Kích thước tự điều chỉnh theo số lượng item
    implicitWidth: 320
    implicitHeight: filteredApps.length > 0 ? (filteredApps.length * itemH + 16) : 0

    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutExpo } }

    // ── Màu sắc ───────────────────────────────────────────────────────────────
    readonly property var palette: [
        "#7aa2f7", "#0db9d7", "#9ece6a", "#e0af68", "#f7768e", "#bb9af7", "#ff9e64"
    ]
    function accentFor(name) {
        return palette[((name.charCodeAt(0)||0)+(name.charCodeAt(1)||0)) % palette.length]
    }

    // ── Signal & API ──────────────────────────────────────────────────────────
    signal closeRequested()

    function filterApps(query) {
        let q = query.toLowerCase().trim()
        filteredApps = (q === "")
            ? []
            : allApps.filter(a => 
                a.name.toLowerCase().includes(q) || 
                (a.generic && a.generic.toLowerCase().includes(q)) || 
                (a.keywords && a.keywords.toLowerCase().includes(q)) ||
                a.exec.toLowerCase().includes(q)
              ).slice(0, maxShow)
        selectedIndex = 0
    }

    function launchSelected() {
        if (filteredApps.length > 0) launchApp(filteredApps[selectedIndex])
    }

    function launchApp(app) {
        if (!app) return
        launchProcess.command = ["sh", "-c", "setsid -f " + app.exec + " &"]
        launchProcess.running = true
        closeRequested()
    }

    // ── App loading ────────────────────────────────────────────────────────────
    Component.onCompleted: loadProcess.running = true

    Process {
        id: loadProcess
        command: ["bash", "-c",
            "IFS=: read -ra dirs <<< \"$XDG_DATA_DIRS\"; " +
            "search_dirs=( \"$HOME/.local/share/applications\" ); " +
            "for d in \"${dirs[@]}\"; do [ -d \"$d/applications\" ] && search_dirs+=( \"$d/applications\" ); done; " +
            "find \"${search_dirs[@]}\" -name '*.desktop' -print0 2>/dev/null | xargs -0 awk -F= '" +
            "BEGIN { OFS=\"\\t\" } " +
            "/^\\[Desktop Entry\\]/ { in_entry = 1; next } " +
            "/^\\[/ { in_entry = 0 } " +
            "in_entry && $1 == \"Name\" && !name { name = substr($0, 6) } " +
            "in_entry && $1 == \"Exec\" && !exec_cmd { exec_cmd = substr($0, 6) } " +
            "in_entry && $1 == \"Type\" && !type { type = $2 } " +
            "in_entry && $1 == \"NoDisplay\" && !nd { nd = tolower($2) } " +
            "in_entry && $1 == \"Hidden\" && !hidden { hidden = tolower($2) } " +
            "in_entry && $1 == \"GenericName\" && !generic { generic = substr($0, 13) } " +
            "in_entry && $1 == \"Keywords\" && !keywords { keywords = substr($0, 10) } " +
            "ENDFILE { " +
            "  if (type == \"Application\" && nd != \"true\" && hidden != \"true\" && name != \"\" && exec_cmd != \"\") { " +
            "    gsub(/ *%[a-zA-Z]/, \"\", exec_cmd); " +
            "    print name, exec_cmd, generic, keywords " +
            "  } " +
            "  name=\"\"; exec_cmd=\"\"; type=\"\"; nd=\"\"; hidden=\"\"; generic=\"\"; keywords=\"\" " +
            "}' | sort -u"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let apps = []
                let lines = this.text.trim().split("\n")
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i]; if (!line) continue
                    let parts = line.split("\t")
                    if (parts.length >= 2) {
                        let name = parts[0].trim()
                        let exec = parts[1].trim()
                        let generic = parts[2] ? parts[2].trim() : ""
                        let keywords = parts[3] ? parts[3].trim() : ""
                        if (name && exec) apps.push({ name: name, exec: exec, generic: generic, keywords: keywords })
                    }
                }
                launcherRoot.allApps = apps
            }
        }
    }

    Process { id: launchProcess; command: [] }

    // ── Danh sách kết quả (List) ──────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.04, 0.04, 0.08, 0.8)
        radius: 12
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        opacity: launcherRoot.implicitHeight > 0 ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Column {
            id: resultsColumn
            anchors.fill: parent
            anchors.margins: 8
            spacing: 0

            Repeater {
                model: launcherRoot.filteredApps

                delegate: Rectangle {
                    id: listItem
                    width: resultsColumn.width
                    height: launcherRoot.itemH
                    radius: 6
                    color: isSelected ? Qt.rgba(0.48, 0.63, 0.97, 0.15) : (isHovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent")

                    property bool isSelected: index === launcherRoot.selectedIndex
                    property bool isHovered:  false
                    
                    Behavior on color { ColorAnimation { duration: 100 } }

                    // ── Animation xuất hiện (từ phải sang) ──
                    opacity: 0
                    transform: Translate { id: slideT }

                    SequentialAnimation {
                        running: true
                        PauseAnimation { duration: index * 25 } // Chờ một chút theo index
                        ParallelAnimation {
                            NumberAnimation {
                                target: listItem; property: "opacity"
                                from: 0; to: 1
                                duration: 180; easing.type: Easing.OutQuad
                            }
                            NumberAnimation {
                                target: slideT; property: "x"
                                from: 30; to: 0 // Trượt 30px từ phải sang
                                duration: 250; easing.type: Easing.OutExpo
                            }
                        }
                    }

                    // ── Nội dung dòng chữ ─────────────────────────────────────
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12
                        
                        // ── Nội dung dòng chữ ─────────────────────────────────────
                        Text {
                            text: modelData.name
                            color: listItem.isSelected ? "#ffffff" : "#c0caf5"
                            font.family: launcherRoot.fontFamily
                            font.pixelSize: 13
                            font.bold: listItem.isSelected
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }

                    // Vạch chọn (Accent bar) bên trái
                    Rectangle {
                        width: 3; height: 16; radius: 1.5
                        color: "#7aa2f7"
                        anchors.left: parent.left
                        anchors.leftMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: listItem.isSelected ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onEntered: { listItem.isHovered = true;  launcherRoot.selectedIndex = index }
                        onExited:  { listItem.isHovered = false }
                        onClicked: launcherRoot.launchApp(modelData)
                    }
                }
            }
        }
    }
}
