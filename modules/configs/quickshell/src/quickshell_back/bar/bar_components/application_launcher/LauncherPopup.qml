import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../" 

BlueprintPopup {
    id: root

    popupWidth: 750
    popupHeight: 520
    isTopBar: false 

    // --- 2. LOGIC & DATA ---
    property int activeTab: 0 
    property var fullAppList: []
    property var recentAppList: []
    property var filteredModel: []

    // Instantly fetches your Linux desktop apps via a single Python line
    property string pythonFetcher: "import os,json; apps=[]; dirs=['/usr/share/applications', os.path.expanduser('~/.local/share/applications')]; [apps.append({'name': n, 'icon': i, 'exec': e}) for d in dirs if os.path.exists(d) for f in os.listdir(d) if f.endswith('.desktop') for l in [open(os.path.join(d,f),'r',encoding='utf-8',errors='ignore').read()] if 'NoDisplay=true' not in l for n in [next((x[5:].strip() for x in l.split('\\n') if x.startswith('Name=')), f)] for i in [next((x[5:].strip() for x in l.split('\\n') if x.startswith('Icon=')), '')] for e in [next((x[5:].strip().split(' %')[0] for x in l.split('\\n') if x.startswith('Exec=')), '')] if n and e]; seen=set(); res=[a for a in apps if not (a['name'] in seen or seen.add(a['name']))]; res.sort(key=lambda x: x['name'].lower()); print(json.dumps(res))"

    Process {
        id: appFetcher
        command: ["python3", "-c", root.pythonFetcher]
        property string rawData: ""
        stdout: SplitParser { onRead: function(data) { appFetcher.rawData += data + "\n" } }
        
        onExited: {
            try {
                root.fullAppList = JSON.parse(appFetcher.rawData);
                root.updateModel();
            } catch(e) { console.log("Failed to parse apps") }
            appFetcher.rawData = "";
        }
    }

    Process { id: actionProc }

    Component.onCompleted: appFetcher.running = true
    
    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            root.updateModel();
            searchInput.forceActiveFocus();
        }
    }

    function updateModel() {
        let sourceList = (root.activeTab === 0) ? root.fullAppList : root.recentAppList;
        if (searchInput.text.trim() === "") {
            root.filteredModel = sourceList;
        } else {
            let filter = searchInput.text.toLowerCase();
            root.filteredModel = sourceList.filter(app => (app.name || "").toLowerCase().includes(filter));
        }
    }

    function launchApp(appData) {
        actionProc.command = ["hyprctl", "dispatch", "exec", "--", appData.exec];
        actionProc.running = true;

        let recents = root.recentAppList.filter(a => a.name !== appData.name);
        recents.unshift(appData); 
        if (recents.length > 20) recents.pop(); 
        root.recentAppList = recents;

        root.toggle();
    }

    // --- 3. UI CONTENT ---
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 25
        spacing: 20

        // ==========================================
        // --- SEARCH BAR ---
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            height: 50
            radius: 8
            color: Theme.secondaryBase
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12
                
                Text { text: "󰍉"; color: Theme.inactive; font.pixelSize: 20 }
                
                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: Theme.text
                    font.pixelSize: 16
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    onTextChanged: root.updateModel()
                    
                    Text {
                        text: "Search applications..."
                        color: Theme.inactive
                        font.pixelSize: 16
                        visible: parent.text.length === 0
                    }
                }
            }
        }

        // ==========================================
        // --- TABS (ALL / RECENTS) ---
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 30

            Text {
                text: "All Applications"
                font.pixelSize: 15
                font.bold: true
                color: root.activeTab === 0 ? Theme.main : Theme.inactive
                Behavior on color { ColorAnimation { duration: 150 } }
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -6
                    width: parent.width; height: 2; radius: 1
                    color: Theme.main
                    opacity: root.activeTab === 0 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.activeTab = 0; root.updateModel(); } }
            }

            Text {
                text: "Recent Apps"
                font.pixelSize: 15
                font.bold: true
                color: root.activeTab === 1 ? Theme.main : Theme.inactive
                Behavior on color { ColorAnimation { duration: 150 } }
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -6
                    width: parent.width; height: 2; radius: 1
                    color: Theme.main
                    opacity: root.activeTab === 1 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.activeTab = 1; root.updateModel(); } }
            }
            
            Item { Layout.fillWidth: true } 
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.secondaryBase; opacity: 0.5 }

        // ==========================================
        // --- APPLICATION GRID ---
        // ==========================================
        GridView {
            id: appGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            // Hardcoded to prevent Wayland layout crashes
            cellWidth: 135
            cellHeight: 110
            
            model: root.filteredModel
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

            Text {
                anchors.centerIn: parent
                text: root.activeTab === 1 && root.recentAppList.length === 0 ? "No recent apps yet" : "No applications found"
                color: Theme.inactive
                font.pixelSize: 15
                visible: appGrid.count === 0
            }

            delegate: Item {
                width: appGrid.cellWidth
                height: appGrid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 12
                    color: appMouse.containsMouse ? Theme.secondaryBase : "transparent"
                    border.color: Theme.bridge
                    border.width: appMouse.containsMouse ? 1 : 0
                    Behavior on color { ColorAnimation { duration: 150 } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        Image {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            
                            property string safeIcon: modelData.icon || "application-x-executable"
                            source: safeIcon.startsWith("/") ? ("file://" + safeIcon) : ("image://icon/" + safeIcon)
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 110
                            text: modelData.name || "Unknown"
                            color: Theme.text
                            font.pixelSize: 12
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight 
                        }
                    }

                    MouseArea {
                        id: appMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launchApp(modelData)
                    }
                }
            }
        }
    }
}
