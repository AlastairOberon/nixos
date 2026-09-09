import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray 
import "../" 

BlueprintPopup {
    id: root

    popupWidth: 320 
    popupHeight: 450 
    isTopBar: false 

    property var windowModel: []

    // --- SMART ICON MATCHER ---
    function getWindowIcon(cls) {
        let c = (cls || "").toLowerCase()
        if (c.includes("discord") || c.includes("vesktop") || c.includes("webcord")) return "󰙯"
        if (c.includes("blender")) return "󰂫"
        if (c.includes("pureref")) return "󰋩"
        if (c.includes("firefox") || c.includes("librewolf")) return "󰈹"
        if (c.includes("chrome") || c.includes("chromium") || c.includes("brave")) return "󰊯"
        if (c.includes("code") || c.includes("vscode") || c.includes("vscodium")) return "󰨞"
        if (c.includes("terminal") || c.includes("kitty") || c.includes("alacritty")) return "󰆍"
        if (c.includes("spotify")) return "󰓇"
        if (c.includes("slack")) return "󰒱"
        if (c.includes("thunar") || c.includes("dolphin") || c.includes("nemo")) return "󰉋"
        if (c.includes("obs")) return "󰑋"
        return "󰖯" 
    }

    Process {
        id: windowFetcher
        command: ["hyprctl", "clients", "-j"]
        property string rawData: ""
        stdout: SplitParser { onRead: function(data) { windowFetcher.rawData += data + "\n" } }
        
        onExited: {
            try {
                let clients = JSON.parse(windowFetcher.rawData);
                let activeWindows = [];
                for (let i = 0; i < clients.length; i++) {
                    if (clients[i].mapped && clients[i].title !== "") {
                        activeWindows.push(clients[i]);
                    }
                }
                root.windowModel = activeWindows;
            } catch(e) {}
            windowFetcher.rawData = "";
        }
    }

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: windowFetcher.running = true
    }

    Process { id: actionProc }

    // --- 3. UI CONTENT ---
    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        ScrollView {
            id: trayListScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            
            property string expandedId: ""

            ColumnLayout {
                width: parent.width
                spacing: 5

                // ==========================================
                // SECTION 1: HYPRLAND OPEN WINDOWS
                // ==========================================
                Repeater {
                    model: root.windowModel
                    
                    delegate: Column {
                        id: winDelegateRect
                        width: trayListScroll.width
                        
                        property string appId: "win_" + modelData.address
                        property bool isExpanded: trayListScroll.expandedId === appId

                        clip: true
                        spacing: 5
                        height: isExpanded ? 75 : 40
                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        Item {
                            width: parent.width; height: 40
                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                color: Theme.secondaryBase
                                opacity: (winDelegateRect.isExpanded || winMouse.containsMouse) ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            RowLayout {
                                anchors.fill: parent; anchors.margins: 8; spacing: 12
                                
                                Text {
                                    text: root.getWindowIcon(modelData.class)
                                    color: Theme.main
                                    font.pixelSize: 18
                                }
                                
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.title || modelData.class || "Unknown Window"
                                    color: Theme.text; font.pixelSize: 13; elide: Text.ElideRight
                                }
                                
                                Text {
                                    text: winDelegateRect.isExpanded ? "󰅀" : "󰅁"
                                    color: Theme.inactive; font.pixelSize: 16
                                }
                            }
                            MouseArea {
                                id: winMouse
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: trayListScroll.expandedId = winDelegateRect.isExpanded ? "" : winDelegateRect.appId
                            }
                        }

                        RowLayout {
                            width: parent.width; height: 30; spacing: 10
                            opacity: winDelegateRect.isExpanded ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 4
                                color: focusMouse.containsMouse ? Qt.lighter(Theme.secondary, 1.1) : Theme.secondary
                                Text { anchors.centerIn: parent; text: "Focus"; color: Theme.base; font.bold: true; font.pixelSize: 12 }
                                MouseArea { 
                                    id: focusMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { actionProc.command = ["hyprctl", "dispatch", "focuswindow", "address:" + modelData.address]; actionProc.running = true; root.toggle() } 
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 4
                                color: closeWinMouse.containsMouse ? Qt.lighter(Theme.urgent, 1.1) : Theme.urgent
                                Text { anchors.centerIn: parent; text: "Close"; color: Theme.base; font.bold: true; font.pixelSize: 12 }
                                MouseArea { 
                                    id: closeWinMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { actionProc.command = ["hyprctl", "dispatch", "closewindow", "address:" + modelData.address]; actionProc.running = true; trayListScroll.expandedId = ""; windowFetcher.running = true }
                                }
                            }
                        }
                    }
                }

                // --- DIVIDER ---
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.secondaryBase
                    visible: root.windowModel.length > 0 && SystemTray.items.length > 0
                }

                // ==========================================
                // SECTION 2: SYSTEM TRAY BACKGROUND APPS
                // ==========================================
                Repeater {
                    model: SystemTray.items
                    
                    delegate: Column {
                        id: trayDelegateRect
                        width: trayListScroll.width
                        
                        property string appId: "tray_" + (modelData.id || index.toString())
                        property bool isExpanded: trayListScroll.expandedId === appId

                        clip: true
                        spacing: 5
                        height: isExpanded ? 75 : 40
                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        Item {
                            width: parent.width; height: 40
                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                color: Theme.secondaryBase
                                opacity: (trayDelegateRect.isExpanded || trayMouse.containsMouse) ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            RowLayout {
                                anchors.fill: parent; anchors.margins: 8; spacing: 12
                                
                                Image {
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    source: modelData.icon || (modelData.iconName ? "image://icon/" + modelData.iconName : "")
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }
                                
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.title || modelData.id || "Background App"
                                    color: Theme.text; font.pixelSize: 13; elide: Text.ElideRight
                                }
                                
                                Text {
                                    text: trayDelegateRect.isExpanded ? "󰅀" : "󰅁"
                                    color: Theme.inactive; font.pixelSize: 16
                                }
                            }
                            MouseArea {
                                id: trayMouse
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: trayListScroll.expandedId = trayDelegateRect.isExpanded ? "" : trayDelegateRect.appId
                            }
                        }

                        RowLayout {
                            width: parent.width; height: 30; spacing: 10
                            opacity: trayDelegateRect.isExpanded ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 4
                                color: openTrayMouse.containsMouse ? Qt.lighter(Theme.secondary, 1.1) : Theme.secondary
                                Text { anchors.centerIn: parent; text: "Open"; color: Theme.base; font.bold: true; font.pixelSize: 12 }
                                MouseArea { 
                                    id: openTrayMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { modelData.activate(); root.toggle() } 
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 4
                                color: killTrayMouse.containsMouse ? Qt.lighter(Theme.urgent, 1.1) : Theme.urgent
                                Text { anchors.centerIn: parent; text: "Kill"; color: Theme.base; font.bold: true; font.pixelSize: 12 }
                                MouseArea { 
                                    id: killTrayMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { 
                                        let killTarget = (modelData.id || modelData.title || "").split(" ")[0].toLowerCase();
                                        actionProc.command = ["bash", "-c", 'pkill -i -f "' + killTarget + '"'];
                                        actionProc.running = true;
                                        trayListScroll.expandedId = "";
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
