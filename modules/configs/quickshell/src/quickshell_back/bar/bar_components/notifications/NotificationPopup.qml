import QtQuick
import QtQuick.Layouts
import QtQml 
import QtCore 
import Quickshell
import Quickshell.Io 
import Quickshell.Services.Notifications
import ".." 
import "SharedState.js" as GlobalState

BlueprintPopup {
    id: root

    // --- 1. CONFIGURE THE BLUEPRINT ---
    popupWidth: 600 
    popupHeight: 600 
    isTopBar: true 
    //barOverlap: 0

    property bool isMuted: GlobalState.isMuted
    property var groupedModel: []
    property var expandedGroups: ({})
    readonly property int notifCount: actionInstantiator.count

    onNotifCountChanged: {
        if (notifCount === 0 && root.visible) {
            root.closeSilently();
        }
    }

    // --- ICON RESOLVER FUNCTION ---
    function resolveIcon(notif) {
        let img = notif.image ? notif.image.toString() : "";
        let icon = notif.appIcon ? notif.appIcon.toString() : "";
        let path = img !== "" ? img : icon;
        
        if (path === "") return "";

        try {
            let homeUri = StandardPaths.standardLocations(StandardPaths.HomeLocation)[0];
            if (path.startsWith("image://icon/")) path = path.substring(13); 
            if (path.includes("/") && (path.endsWith(".png") || path.endsWith(".jpg"))) {
                if (!path.startsWith("/") && !path.startsWith("file://") && !path.startsWith("~/")) {
                    return homeUri + "/" + path;
                }
            }
            if (path.startsWith("~/")) return homeUri + "/" + path.substring(2);
            if (path.startsWith("/")) return "file://" + path;
            if (path.includes("://")) return path;

            let resolved = Quickshell.iconPath(path);
            if (resolved && (resolved.includes("checkerboard") || resolved.includes("missing"))) {
                return "";
            }
            return resolved;
        } catch (e) {
            return "";
        }
    }

    // --- GROUPING LOGIC ---
    function rebuildGroups() {
        let groups = {};
        
        for (let i = 0; i < actionInstantiator.count; i++) {
            let child = actionInstantiator.objectAt(i);
            if (!child || !child.notifData) continue;
            
            let n = child.notifData;
            let key = n.appName || "System";

            if (!groups[key]) {
                groups[key] = {
                    appName: key,
                    iconPath: resolveIcon(n),
                    notifications: []
                };
            }
            groups[key].notifications.unshift(n);
        }

        let newModel = [];
        for (let k in groups) {
            newModel.push(groups[k]);
        }
        
        root.groupedModel = newModel;
    }

    function toggleGroup(appName) {
        let temp = root.expandedGroups;
        temp[appName] = !temp[appName];
        root.expandedGroups = Object.assign({}, temp); 
    }

    // --- THE DATA BRIDGE ---
    Instantiator {
        id: actionInstantiator
        model: NotificationDaemon.trackedNotifications
        delegate: QtObject { 
            property var notifData: modelData 
        }
        onObjectAdded: root.rebuildGroups()
        onObjectRemoved: root.rebuildGroups()
    }

    // --- 2. UI CONTENT ---

    MouseArea {
        anchors.fill: parent
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15 
        spacing: 12

        // --- Header Section ---
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 20

            Text {
                anchors.centerIn: parent
                text: "Notification Tray"
                color: Theme.text
                font.pixelSize: 15
                font.bold: true
            }

            // Controls on the Right
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                spacing: 16

                // --- Mute Toggle Button ---
                MouseArea {
                    id: muteBtn
                    anchors.verticalCenter: parent.verticalCenter
                    width: muteRow.implicitWidth
                    height: parent.height
                    hoverEnabled: true

                    Row {
                        id: muteRow
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: root.isMuted ? "󰂛" : "󰂚" 
                            color: (root.isMuted || muteBtn.containsMouse) ? Theme.secondary : Theme.main
                            font.pixelSize: 14
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            text: root.isMuted ? "Muted" : "Mute"
                            color: (root.isMuted || muteBtn.containsMouse) ? Theme.secondary : Theme.main
                            font.pixelSize: 12
                            font.bold: true
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    onClicked: {
                        GlobalState.isMuted = !GlobalState.isMuted;
                        root.isMuted = GlobalState.isMuted;
                    }
                }

                // --- Clear All Button ---
                MouseArea {
                    id: clearAllBtn
                    anchors.verticalCenter: parent.verticalCenter
                    width: clearRow.implicitWidth
                    height: parent.height
                    hoverEnabled: true
                    
                    visible: root.notifCount > 0

                    Row {
                        id: clearRow
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "󰆴" 
                            color: clearAllBtn.containsMouse ? Theme.secondary : Theme.main
                            font.pixelSize: 13
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            text: "Clear All"
                            color: clearAllBtn.containsMouse ? Theme.secondary : Theme.main
                            font.pixelSize: 12
                            font.bold: true
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    onClicked: {
                        for (let i = actionInstantiator.count - 1; i >= 0; i--) {
                            let child = actionInstantiator.objectAt(i);
                            if (child && child.notifData) {
                                child.notifData.tracked = false; 
                                child.notifData.dismiss();      
                            }
                        }
                        root.expandedGroups = {}; 
                        root.closeSilently();
                    }
                }
            }
        }

        // --- Wrapper Item for Fade Overlays ---
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: notifList
                anchors.fill: parent
                clip: true
                spacing: 12
                
                model: root.groupedModel

                footer: Item {
                    width: notifList.width
                    height: notifList.count === 0 ? 100 : 40 
                    
                    Text {
                        anchors.centerIn: parent
                        text: "No new notifications"
                        color: Theme.inactive
                        font.pixelSize: 13
                        visible: notifList.count === 0
                    }
                }

                // --- THE GROUP DELEGATE ---
                delegate: Column {
                    width: ListView.view.width
                    spacing: 8

                    property string groupName: modelData.appName
                    property bool isExpanded: !!root.expandedGroups[groupName]
                    property int childCount: modelData.notifications.length

                    // 1. Group Header
                    Rectangle {
                        width: parent.width
                        height: 40
                        color: groupMouse.containsMouse ? Theme.secondaryBase : "transparent"
                        radius: 6
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Image {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                source: modelData.iconPath
                                visible: modelData.iconPath !== ""
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: groupName
                                color: Theme.text
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Rectangle {
                                width: badgeText.implicitWidth + 12
                                height: 20
                                radius: 10
                                color: Theme.main
                                visible: childCount > 1
                                
                                Text {
                                    id: badgeText
                                    anchors.centerIn: parent
                                    text: childCount.toString()
                                    color: Theme.base
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            Text {
                                text: isExpanded ? "󰅀" : "󰅁"
                                color: Theme.inactive
                                font.pixelSize: 16
                            }
                        }

                        MouseArea {
                            id: groupMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.toggleGroup(groupName)
                        }
                    }

                    // 2. Expanded Individual Notifications
                    Item {
                        width: parent.width
                        height: (isExpanded || childCount === 1) ? expandedCol.implicitHeight : 0
                        visible: height > 0
                        clip: true
                        
                        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        
                        Column {
                            id: expandedCol
                            width: parent.width
                            spacing: 8
                            anchors.bottom: parent.bottom 
                            
                            anchors.left: parent.left
                            anchors.leftMargin: 15 
                            
                            Repeater {
                                model: modelData.notifications
                                
                                // THE FIX: Individual Notification Cards
                                delegate: Rectangle {
                                    width: expandedCol.width - 15
                                    height: content.implicitHeight + 20
                                    
                                    // Transparent by default, Theme.secondaryBase when hovered!
                                    color: cardHover.hovered ? Theme.secondaryBase : "transparent"
                                    radius: 6
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    // Passive hover detection that won't block the buttons
                                    HoverHandler {
                                        id: cardHover
                                    }

                                    ColumnLayout {
                                        id: content
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.margins: 10
                                        spacing: 8

                                        // Top Row (Summary + Actions)
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8
                                            
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.summary
                                                color: Theme.secondary
                                                font.pixelSize: 13
                                                font.bold: true
                                                wrapMode: Text.Wrap 
                                            }

                                            // Copy Button
                                            MouseArea {
                                                id: copyBtn
                                                Layout.preferredWidth: 16
                                                Layout.preferredHeight: 16
                                                hoverEnabled: true

                                                Process {
                                                    id: clipboardProcess
                                                    command: ["wl-copy", modelData.summary + (modelData.body !== "" ? "\n" + modelData.body : "")]
                                                }

                                                onClicked: clipboardProcess.running = true
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "󰆏" 
                                                    color: copyBtn.containsMouse ? Theme.main : Theme.inactive
                                                    font.pixelSize: 13
                                                    Behavior on color { ColorAnimation { duration: 150 } }
                                                }
                                            }

                                            // Close "✕" Button
                                            MouseArea {
                                                id: closeBtn
                                                Layout.preferredWidth: 16
                                                Layout.preferredHeight: 16
                                                hoverEnabled: true
                                                
                                                onClicked: {
                                                    modelData.tracked = false;
                                                    modelData.dismiss();
                                                }
                                                
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "✕"
                                                    color: closeBtn.containsMouse ? Theme.urgent : Theme.inactive
                                                    font.pixelSize: 14
                                                    Behavior on color { ColorAnimation { duration: 150 } }
                                                }
                                            }
                                        }

                                        // Body Text
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.body
                                            visible: modelData.body !== ""
                                            color: Theme.text
                                            font.pixelSize: 12
                                            wrapMode: Text.Wrap
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Separator Line
                    Rectangle {
                        width: parent.width - 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 1
                        color: Theme.secondaryBase
                        visible: index !== notifList.count - 1 
                    }
                }
            }

            // Top Fade
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 20
                
                opacity: notifList.atYBeginning ? 0.0 : 1.0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
                
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.base }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Bottom Fade
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 30 
                
                opacity: notifList.atYEnd ? 0.0 : 1.0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
                
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Theme.base }
                }
            }
        }
    }
}

