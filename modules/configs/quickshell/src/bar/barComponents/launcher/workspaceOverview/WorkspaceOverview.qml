import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

import "../../../../theme" 
import "../../../../theme/components" 

Item {
    id: workspaceRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    property var workspacesData: []

    // ==========================================
    // INTELLIGENT APP MAPPING ENGINE
    // ==========================================
    function getAppInfo(appClass, appTitle) {
        let cls = appClass.toLowerCase();
        let title = appTitle.toLowerCase();

        if (title.includes("yazi")) return { name: "Yazi File Manager", icon: "\uf07b" };
        if (title.includes("nvim") || title.includes("neovim")) return { name: "Neovim", icon: "\uf121" }; 
        if (title.includes("btop")) return { name: "Btop", icon: "\uf080" }; 
        if (title.includes("nano") || title.includes("vim")) return { name: "Text Editor", icon: "\uf044" }; 
        if (cls.includes("ghostty") || cls.includes("kitty") || cls.includes("alacritty") || cls.includes("wezterm") || cls.includes("konsole")) 
            return { name: "Terminal", icon: "\uf120" }; 
        if (cls.includes("steam")) 
            return { name: "Steam", icon: "\uf1b6" }; 
        if (cls.includes("vesktop") || cls.includes("discord") || cls.includes("webcord")) 
            return { name: "Discord", icon: "\uf392" }; 
        if (cls.includes("spotify")) 
            return { name: "Spotify", icon: "\uf1bc" }; 
        if (cls.includes("zen") || cls.includes("firefox") || cls.includes("chrome") || cls.includes("brave") || cls.includes("chromium")) 
            return { name: "Web Browser", icon: "\uf0ac" }; 
        if (cls.includes("code") || cls.includes("vscode") || cls.includes("vscodium")) 
            return { name: "VS Code", icon: "\uf121" }; 
        if (cls.includes("obsidian")) 
            return { name: "Obsidian", icon: "\uf044" }; 
        if (cls.includes("dolphin") || cls.includes("thunar") || cls.includes("nautilus")) 
            return { name: "File Manager", icon: "\uf07b" }; 
        if (cls.includes("vlc") || cls.includes("mpv")) 
            return { name: "Media Player", icon: "\uf03d" }; 

        let fallbackName = appClass;
        if (fallbackName.includes(".")) {
            let parts = fallbackName.split(".");
            fallbackName = parts[parts.length - 1];
        }
        fallbackName = fallbackName.charAt(0).toUpperCase() + fallbackName.slice(1);
        if (fallbackName === "" || fallbackName === "Unknown") fallbackName = "Application";

        return { name: fallbackName, icon: "\uf2d0" }; 
    }

    // ==========================================
    // BACKEND: HYPRLAND DATA & ACTIONS
    // ==========================================
    Process { 
        id: actionProcess 
        onExited: running = false 
    }

    function focusWindow(workspaceName, clientAddress) {
        actionProcess.running = false; 
        let addr = clientAddress.toString().startsWith("0x") ? clientAddress : "0x" + clientAddress;
        let cmd = "hyprctl eval 'hl.dispatch(hl.dsp.focus({ workspace = \"" + workspaceName + "\" })); hl.dispatch(hl.dsp.focus({ window = \"address:" + addr + "\" }))'";
        actionProcess.command = ["bash", "-c", cmd];
        actionProcess.running = true;
    }

    function closeWindow(clientAddress) {
        actionProcess.running = false;
        let addr = clientAddress.toString().startsWith("0x") ? clientAddress : "0x" + clientAddress;
        let cmd = "hyprctl eval 'hl.dispatch(hl.dsp.window.close({ window = \"address:" + addr + "\" }))'";
        actionProcess.command = ["bash", "-c", cmd];
        actionProcess.running = true;
    }

    Process {
        id: fetchHyprland
        command: [
            "bash", "-c", 
            "echo \"{\\\"monitors\\\": $(hyprctl monitors -j), \\\"workspaces\\\": $(hyprctl workspaces -j), \\\"clients\\\": $(hyprctl clients -j)}\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text);
                    
                    let monMap = {};
                    for (let i = 0; i < data.monitors.length; i++) {
                        monMap[data.monitors[i].name] = data.monitors[i];
                    }

                    let wsMonMap = {};
                    for (let i = 0; i < data.workspaces.length; i++) {
                        wsMonMap[data.workspaces[i].id] = data.workspaces[i].monitor;
                    }

                    let wsGroups = {};
                    for (let i = 0; i < data.clients.length; i++) {
                        let c = data.clients[i];
                        if (!c.mapped || c.workspace.id < 0) continue; 
                        
                        let wId = c.workspace.id;
                        
                        if (!wsGroups[wId]) {
                            let mName = wsMonMap[wId] || (data.monitors[0] ? data.monitors[0].name : "Unknown");
                            let mInfo = monMap[mName];
                            
                            wsGroups[wId] = {
                                id: wId,
                                name: c.workspace.name,
                                monitorName: mName,
                                screenW: mInfo ? mInfo.width : 1920,
                                screenH: mInfo ? mInfo.height : 1080,
                                screenX: mInfo ? mInfo.x : 0,
                                screenY: mInfo ? mInfo.y : 0,
                                clients: []
                            };
                        }
                        
                        wsGroups[wId].clients.push({
                            clientAddress: c.address,
                            appClass: c.class || "Unknown",
                            appTitle: c.title || "No Title",
                            appX: c.at[0],
                            appY: c.at[1],
                            appW: c.size[0],
                            appH: c.size[1],
                            isFloating: c.floating
                        });
                    }

                    let wsArray = Object.values(wsGroups).sort((a, b) => a.id - b.id);
                    workspaceRoot.workspacesData = wsArray;

                } catch (e) {
                    console.log("Hyprland JSON Parse Error: " + e.message);
                }
            }
        }
    }

    Timer {
        interval: 500 
        running: workspaceRoot.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: fetchHyprland.running = true
    }

    // ==========================================
    // UI LAYOUT
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Metrics.spacingLarge
        spacing: Metrics.spacingBase

        // --- HEADER ---
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Workspace Overview"
                color: Theme.main
                font.family: Theme.fontMain
                font.pixelSize: 16 
                font.weight: Font.Bold
            }
            Item { Layout.fillWidth: true }
            Text {
                text: workspaceRoot.workspacesData.length + " Active Workspaces"
                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                font.family: Theme.fontMain
                font.pixelSize: 12 
                font.weight: Font.Bold
            }
        }

        // --- HORIZONTAL SCROLLING WORKSPACE GRID ---
        ListView {
            id: wsListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            orientation: ListView.Horizontal
            spacing: Metrics.spacingLarge
            
            model: workspaceRoot.workspacesData
            ScrollBar.horizontal: ScrollBar { active: true; policy: ScrollBar.AsNeeded }
            boundsBehavior: Flickable.StopAtBounds

            Item {
                width: parent.width
                height: 100
                visible: workspaceRoot.workspacesData.length === 0
                Text {
                    anchors.centerIn: parent
                    text: "No active applications found."
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                    font.family: Theme.fontMain
                    font.pixelSize: 13
                }
            }

            delegate: Item {
                id: wsDelegate
                width: Math.max(100, (ListView.view.width - (Metrics.spacingLarge * 3)) / 4)
                height: ListView.view.height

                property var wsData: modelData
                property real scaleFactor: wsData.screenW > 0 ? (width / wsData.screenW) : 1.0

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Metrics.spacingBase

                    Text {
                        text: "Workspace " + wsDelegate.wsData.name
                        color: Theme.secondary
                        font.family: Theme.fontMain
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        Layout.bottomMargin: -2
                    }

                    // ------------------------------------------
                    // TOP: MINIMAP
                    // ------------------------------------------
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: wsDelegate.wsData.screenH * wsDelegate.scaleFactor
                        color: "transparent"
                        radius: Metrics.radiusBase
                        border.width: mapHover.hovered ? 1 : 0
                        border.color: mapHover.hovered ? Theme.main : "transparent"
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        HoverHandler { id: mapHover }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: mapHover.hovered ? 1 : 0
                            color: Qt.rgba(0, 0, 0, 0.2) 
                            radius: Metrics.radiusBase
                            border.width: 1
                            border.color: Theme.bridge
                            clip: true

                            Repeater {
                                model: wsDelegate.wsData.clients
                                
                                Rectangle {
                                    id: minimapWindow
                                    property var clientData: modelData
                                    property var mappedInfo: workspaceRoot.getAppInfo(clientData.appClass, clientData.appTitle)
                                    
                                    x: (clientData.appX - wsDelegate.wsData.screenX) * wsDelegate.scaleFactor
                                    y: (clientData.appY - wsDelegate.wsData.screenY) * wsDelegate.scaleFactor
                                    width: clientData.appW * wsDelegate.scaleFactor
                                    height: clientData.appH * wsDelegate.scaleFactor
                                    
                                    radius: 3 
                                    color: winMouse.containsMouse ? Theme.main : Qt.rgba(Theme.main.r, Theme.main.g, Theme.main.b, 0.15)
                                    border.width: 2
                                    border.color: winMouse.containsMouse ? Theme.base : Theme.main
                                    
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Behavior on border.color { ColorAnimation { duration: 100 } }
                                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                    Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                                    MouseArea {
                                        id: winMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: workspaceRoot.focusWindow(wsDelegate.wsData.name, clientData.clientAddress)
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: minimapWindow.mappedInfo.icon
                                        color: winMouse.containsMouse ? Theme.base : Theme.text
                                        font.family: Theme.fontIcon
                                        font.pixelSize: Math.min(parent.width * 0.5, parent.height * 0.5, 20) 
                                        opacity: parent.width > 16 && parent.height > 16 ? 1 : 0
                                    }
                                }
                            }
                        }
                    }

                    // ------------------------------------------
                    // BOTTOM: VERTICAL APP LIST
                    // ------------------------------------------
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        // Hide the vertical scrollbar entirely to prevent visual overlap
                        ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                        ColumnLayout {
                            // Expand the width to the very edge since the scrollbar is gone
                            width: parent.width
                            spacing: 4 

                            Repeater {
                                model: wsDelegate.wsData.clients
                                
                                delegate: Rectangle {
                                    property var clientData: modelData
                                    property var mappedInfo: workspaceRoot.getAppInfo(clientData.appClass, clientData.appTitle)
                                    
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38 
                                    radius: Metrics.radiusBase
                                    color: "transparent"
                                    border.width: appHover.hovered ? 1 : 0
                                    border.color: appHover.hovered ? Theme.main : "transparent"
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    HoverHandler { id: appHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 10

                                        Text {
                                            text: mappedInfo.icon
                                            color: Theme.main
                                            font.family: Theme.fontIcon
                                            font.pixelSize: 14 
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0 
                                            
                                            Text {
                                                text: mappedInfo.name
                                                color: Theme.text
                                                font.family: Theme.fontMain
                                                font.pixelSize: 13 
                                                font.weight: Font.Bold
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                            
                                            Text {
                                                text: clientData.appTitle
                                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                                                font.family: Theme.fontMain
                                                font.pixelSize: 11 
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Text {
                                            text: "\uf00d" 
                                            color: closeHover.containsMouse ? Theme.urgent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
                                            font.family: Theme.fontIcon
                                            font.pixelSize: 14
                                            
                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            MouseArea {
                                                id: closeHover
                                                anchors.fill: parent
                                                anchors.margins: -8 
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    workspaceRoot.closeWindow(clientData.clientAddress)
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        z: -1 
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: workspaceRoot.focusWindow(wsDelegate.wsData.name, clientData.clientAddress)
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
