pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

import "../../../../theme"
import "../../../../theme/components"

Item {
    id: trayRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    // ==========================================
    // BACKEND DATA & STATE
    // ==========================================
    property var rawItems: []
    property string currentWorkspaceName: "1"
    property int totalRunningCount: 0
    property int openCount: 0
    property int bgCount: 0
    property string searchQuery: ""
    property var expandedAddresses: ({})

    ListModel { id: trayItemsModel }

    // ==========================================
    // HYPRLAND & PROCESS ACTIONS
    // ==========================================
    Process {
        id: actionProc
        onExited: {
            running = false;
            fetchClientsProc.running = true;
        }
    }

    // 1. Focus App (if open)
    function focusApp(wsName, clientAddress) {
        if (!clientAddress || clientAddress.length < 3) return;
        let addr = clientAddress.toString().startsWith("0x") ? clientAddress : "0x" + clientAddress;
        let luaCmd = "hl.dispatch(hl.dsp.focus({ workspace = \"" + wsName + "\" })); hl.dispatch(hl.dsp.focus({ window = \"address:" + addr + "\" }))";
        actionProc.running = false;
        actionProc.command = ["bash", "-c", "hyprctl eval '" + luaCmd + "'"];
        actionProc.running = true;

        if (typeof launcherWindow !== "undefined" && launcherWindow) {
            launcherWindow.visible = false;
        }
    }

    // 2. Open App (if closed or background)
    function openApp(cmd) {
        if (!cmd || cmd.trim() === "") return;
        actionProc.running = false;
        actionProc.command = ["bash", "-c", "nohup " + cmd + " >/dev/null 2>&1 &"];
        actionProc.running = true;
    }

    // 3. Forcibly Close App
    function forceCloseApp(pid, cmd, appClass, address) {
        actionProc.running = false;
        let bashCmd = "";
        if (pid && pid > 0) {
            bashCmd += "kill -9 " + pid + " 2>/dev/null; ";
        }
        if (cmd && cmd.length > 0) {
            bashCmd += "pkill -9 -f '" + cmd + "' 2>/dev/null; ";
        }
        if (appClass && appClass.length > 0 && appClass !== cmd) {
            bashCmd += "pkill -9 -f '" + appClass + "' 2>/dev/null; ";
        }
        if (address && address.length > 3) {
            let addr = address.toString().startsWith("0x") ? address : "0x" + address;
            bashCmd += "hyprctl eval 'hl.dispatch(hl.dsp.window.close({ window = \"address:" + addr + "\" }))' 2>/dev/null; ";
        }
        actionProc.command = ["bash", "-c", bashCmd];
        actionProc.running = true;
    }

    function toggleExpand(appId) {
        let current = trayRoot.expandedAddresses[appId] === true;
        let copy = Object.assign({}, trayRoot.expandedAddresses);
        copy[appId] = !current;
        trayRoot.expandedAddresses = copy;
    }

    // ==========================================
    // DATA POLLING
    // ==========================================
    Process {
        id: fetchClientsProc
        command: [
            "python3",
            "/etc/nixos/modules/configs/quickshell/src/bar/barComponents/launcher/systemTray/tray_scanner.py"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text.trim() === "") return;
                    let res = JSON.parse(this.text);
                    trayRoot.currentWorkspaceName = res.currentWs || "1";
                    trayRoot.totalRunningCount = res.totalRunning || 0;
                    trayRoot.openCount = res.openCount || 0;
                    trayRoot.bgCount = res.bgCount || 0;
                    trayRoot.rawItems = res.items || [];
                    trayRoot.updateModel();
                } catch(e) {
                    console.log("SystemTray scanner parse error: " + e.message);
                }
            }
        }
    }

    function updateModel() {
        let q = trayRoot.searchQuery.trim().toLowerCase();
        let filtered = [];

        for (let i = 0; i < trayRoot.rawItems.length; i++) {
            let item = trayRoot.rawItems[i];
            let name = (item.name || "").toLowerCase();
            let title = (item.title || "").toLowerCase();
            let cmd = (item.cmd || "").toLowerCase();
            let cls = (item.appClass || "").toLowerCase();

            if (q !== "") {
                let match = name.includes(q) || title.includes(q) || cmd.includes(q) || cls.includes(q) || item.status.toLowerCase().includes(q);
                if (!match) continue;
            }

            filtered.push(item);
        }

        // Synchronize ListModel
        for (let i = 0; i < filtered.length; i++) {
            let item = filtered[i];
            if (trayItemsModel.count <= i) {
                trayItemsModel.append(item);
            } else {
                for (let k in item) {
                    if (trayItemsModel.get(i)[k] !== item[k]) {
                        trayItemsModel.setProperty(i, k, item[k]);
                    }
                }
            }
        }
        while (trayItemsModel.count > filtered.length) {
            trayItemsModel.remove(trayItemsModel.count - 1);
        }
    }

    onSearchQueryChanged: updateModel()

    Timer {
        id: autoPollTimer
        interval: 2000
        running: trayRoot.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: fetchClientsProc.running = true
    }

    onVisibleChanged: {
        if (visible) fetchClientsProc.running = true;
    }

    // ==========================================
    // UI LAYOUT
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Metrics.spacingLarge
        spacing: Metrics.spacingLarge

        // --- 1. HEADER & SUMMARY ---
        RowLayout {
            Layout.fillWidth: true
            spacing: Metrics.spacingLarge

            Text {
                text: "\uf2d2"
                color: Theme.main
                font.family: Theme.fontIcon
                font.pixelSize: 26
            }

            ColumnLayout {
                spacing: 2
                Text {
                    text: "System Tray & Application Manager"
                    color: Theme.main
                    font.family: Theme.fontMain
                    font.pixelSize: 18
                    font.weight: Font.Bold
                }
                Text {
                    text: "Monitor active windows and background applications with direct controls"
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                    font.family: Theme.fontMain
                    font.pixelSize: 13
                }
            }

            Item { Layout.fillWidth: true }

            // Refresh Button
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: refreshHover.containsMouse ? Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.2) : "transparent"
                border.width: 1
                border.color: refreshHover.containsMouse ? Theme.secondary : Theme.bridge
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf021"
                    color: refreshHover.containsMouse ? Theme.secondary : Theme.text
                    font.family: Theme.fontIcon
                    font.pixelSize: 14
                }

                MouseArea {
                    id: refreshHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: fetchClientsProc.running = true
                }
            }

            // Summary Badges
            Rectangle {
                Layout.preferredHeight: 32
                Layout.preferredWidth: countRow.implicitWidth + 16
                radius: 16
                color: Qt.rgba(Theme.main.r, Theme.main.g, Theme.main.b, 0.15)
                border.width: 1
                border.color: Theme.main

                RowLayout {
                    id: countRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "\uf2d0"
                        color: Theme.main
                        font.family: Theme.fontIcon
                        font.pixelSize: 13
                    }

                    Text {
                        text: trayRoot.openCount + " Open • " + trayRoot.bgCount + " Background"
                        color: Theme.text
                        font.family: Theme.fontMain
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
                }
            }
        }

        // --- 2. SEARCH & FILTER BAR ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: Metrics.radiusBase
            color: "transparent"
            border.width: 1
            border.color: searchInput.activeFocus ? Theme.main : Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.4)
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Text {
                    text: "\uf002"
                    color: searchInput.activeFocus ? Theme.main : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                    font.family: Theme.fontIcon
                    font.pixelSize: 15
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    text: trayRoot.searchQuery
                    onTextChanged: trayRoot.searchQuery = text
                    color: Theme.text
                    font.family: Theme.fontMain
                    font.pixelSize: 14
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true

                    Text {
                        anchors.fill: parent
                        text: "Filter applications by name, class, title, or status..."
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                        font.family: Theme.fontMain
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                        visible: !searchInput.text && !searchInput.activeFocus
                    }
                }

                Text {
                    text: "\uf00d"
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                    font.family: Theme.fontIcon
                    font.pixelSize: 13
                    visible: searchInput.text.length > 0
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = "";
                            trayRoot.searchQuery = "";
                        }
                    }
                }
            }
        }

        // --- 3. APPLICATION LIST VIEW ---
        ListView {
            id: appListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: trayItemsModel
            spacing: 12
            clip: true

            delegate: Rectangle {
                id: delegateRoot
                required property int index
                required property string id
                required property string name
                required property string icon
                required property string color
                required property string cmd
                required property string appClass
                required property string status
                required property string statusType
                required property bool hasWindow
                required property string address
                required property string workspace
                required property string title
                required property int pid

                readonly property bool isExpanded: trayRoot.expandedAddresses[id + "_" + index] === true

                width: appListView.width
                height: isExpanded ? 140 : 70
                radius: Metrics.radiusBase
                color: "transparent"
                border.width: 1
                border.color: isExpanded ? Theme.main : (cardHover.containsMouse ? Theme.secondary : Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.3))
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                clip: true

                MouseArea {
                    id: cardHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    // --- COMPACT HEADER ROW ---
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // App Icon Badge
                        Rectangle {
                            width: 44
                            height: 44
                            radius: 10
                            color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.6)
                            border.width: 1
                            border.color: delegateRoot.color

                            Text {
                                anchors.centerIn: parent
                                text: delegateRoot.icon
                                color: delegateRoot.color
                                font.family: Theme.fontIcon
                                font.pixelSize: 20
                            }
                        }

                        // App Name & Details
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: delegateRoot.name
                                    color: Theme.text
                                    font.family: Theme.fontMain
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                }

                                // Status Badge
                                Rectangle {
                                    Layout.preferredHeight: 18
                                    Layout.preferredWidth: statusText.implicitWidth + 12
                                    radius: 9
                                    color: delegateRoot.statusType === "open" ? Qt.rgba(Theme.main.r, Theme.main.g, Theme.main.b, 0.2) : (delegateRoot.statusType === "background" ? Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.2) : Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.2))
                                    border.width: 1
                                    border.color: delegateRoot.statusType === "open" ? Theme.main : (delegateRoot.statusType === "background" ? Theme.secondary : Theme.bridge)

                                    Text {
                                        id: statusText
                                        anchors.centerIn: parent
                                        text: delegateRoot.statusType === "open" ? ("Open • WS " + delegateRoot.workspace) : (delegateRoot.statusType === "background" ? "Background" : "Closed")
                                        color: delegateRoot.statusType === "open" ? Theme.main : (delegateRoot.statusType === "background" ? Theme.secondary : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5))
                                        font.family: Theme.fontMain
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }
                                }
                            }

                            Text {
                                text: delegateRoot.title
                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                                font.family: Theme.fontMain
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Quick Primary Action Button (Header right)
                        Rectangle {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            radius: 17
                            color: qfHover.containsMouse ? (delegateRoot.hasWindow ? Qt.rgba(Theme.main.r, Theme.main.g, Theme.main.b, 0.3) : Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.3)) : (delegateRoot.hasWindow ? Qt.rgba(Theme.main.r, Theme.main.g, Theme.main.b, 0.15) : Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.15))
                            border.width: 1
                            border.color: delegateRoot.hasWindow ? Theme.main : Theme.secondary

                            Text {
                                anchors.centerIn: parent
                                text: delegateRoot.hasWindow ? "\uf06e" : "\uf067"
                                color: delegateRoot.hasWindow ? Theme.main : Theme.secondary
                                font.family: Theme.fontIcon
                                font.pixelSize: 13
                            }

                            MouseArea {
                                id: qfHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (delegateRoot.hasWindow) {
                                        trayRoot.focusApp(delegateRoot.workspace, delegateRoot.address);
                                    } else {
                                        trayRoot.openApp(delegateRoot.cmd);
                                    }
                                }
                            }
                        }

                        // Expand / Collapse Chevron
                        Rectangle {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            radius: 17
                            color: expHover.containsMouse ? Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.3) : "transparent"
                            border.width: 1
                            border.color: Theme.bridge

                            Text {
                                anchors.centerIn: parent
                                text: delegateRoot.isExpanded ? "\uf077" : "\uf078"
                                color: Theme.text
                                font.family: Theme.fontIcon
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: expHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: trayRoot.toggleExpand(delegateRoot.id + "_" + delegateRoot.index)
                            }
                        }
                    }

                    // --- EXPANDED DETAILS: ONLY THE 2 REQUESTED BUTTONS ---
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: delegateRoot.isExpanded
                        opacity: delegateRoot.isExpanded ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 180 } }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.3)
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            // Process Metadata Information
                            Text {
                                text: (delegateRoot.pid > 0 ? ("PID: " + delegateRoot.pid + " | ") : "") + "Command: " + delegateRoot.cmd
                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                                font.family: Theme.fontMain
                                font.pixelSize: 11
                            }

                            Item { Layout.fillWidth: true }

                            // OPTION 1: Open (if closed/background) OR Focus (if already open)
                            Rectangle {
                                Layout.preferredHeight: 34
                                Layout.preferredWidth: opt1Text.implicitWidth + 28
                                radius: Metrics.radiusBase
                                color: opt1Hover.containsMouse ? (delegateRoot.hasWindow ? Qt.rgba(Theme.main.r, Theme.main.g, Theme.main.b, 0.3) : Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.3)) : (delegateRoot.hasWindow ? Qt.rgba(Theme.main.r, Theme.main.g, Theme.main.b, 0.15) : Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.15))
                                border.width: 1
                                border.color: delegateRoot.hasWindow ? Theme.main : Theme.secondary

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text {
                                        text: delegateRoot.hasWindow ? "\uf06e" : "\uf067"
                                        color: delegateRoot.hasWindow ? Theme.main : Theme.secondary
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 12
                                    }
                                    Text {
                                        id: opt1Text
                                        text: delegateRoot.hasWindow ? "Focus App" : "Open App"
                                        color: delegateRoot.hasWindow ? Theme.main : Theme.secondary
                                        font.family: Theme.fontMain
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                    }
                                }

                                MouseArea {
                                    id: opt1Hover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (delegateRoot.hasWindow) {
                                            trayRoot.focusApp(delegateRoot.workspace, delegateRoot.address);
                                        } else {
                                            trayRoot.openApp(delegateRoot.cmd);
                                        }
                                    }
                                }
                            }

                            // OPTION 2: Forcibly Close App
                            Rectangle {
                                Layout.preferredHeight: 34
                                Layout.preferredWidth: opt2Text.implicitWidth + 28
                                radius: Metrics.radiusBase
                                color: opt2Hover.containsMouse ? Qt.rgba(Theme.urgent.r, Theme.urgent.g, Theme.urgent.b, 0.3) : Qt.rgba(Theme.urgent.r, Theme.urgent.g, Theme.urgent.b, 0.15)
                                border.width: 1
                                border.color: Theme.urgent
                                opacity: (delegateRoot.statusType !== "closed" || delegateRoot.pid > 0 || delegateRoot.hasWindow) ? 1.0 : 0.4

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text {
                                        text: "\uf00d"
                                        color: Theme.urgent
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 12
                                    }
                                    Text {
                                        id: opt2Text
                                        text: "Force Close"
                                        color: Theme.urgent
                                        font.family: Theme.fontMain
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                    }
                                }

                                MouseArea {
                                    id: opt2Hover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        trayRoot.forceCloseApp(delegateRoot.pid, delegateRoot.cmd, delegateRoot.appClass, delegateRoot.address);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- EMPTY STATE CARD ---
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: trayItemsModel.count === 0
            color: "transparent"
            radius: Metrics.radiusBase
            border.width: 1
            border.color: Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.2)

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    text: "\uf2d2"
                    color: Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.6)
                    font.family: Theme.fontIcon
                    font.pixelSize: 48
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: searchInput.text.length > 0 ? "No applications match your filter" : "No applications found"
                    color: Theme.text
                    font.family: Theme.fontMain
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
