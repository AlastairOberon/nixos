import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtCore // Needed for StandardPaths image parsing
import Quickshell

import "../../../../theme" 
import "../../../../theme/components"

Item {
    id: notifRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    property var notificationGroups: []
    property var mutedApps: [] 

    TextEdit {
        id: clipboardHelper
        width: 1; height: 1; opacity: 0; z: -100; readOnly: true
        function copyToClipboard(str) { text = str; selectAll(); copy(); }
    }

    function pushNotification(appName, summary, body, iconPath) {
        let d = new Date();
        let timeStr = d.toLocaleTimeString(Qt.locale(), "hh:mm AP");
        let newNotif = { "summary": summary, "body": body, "iconStr": iconPath || "", "time": timeStr, "isNew": true };

        let tempGroups = JSON.parse(JSON.stringify(notifRoot.notificationGroups));
        let foundIndex = -1;
        let isMuted = false;
        
        for (let i = 0; i < tempGroups.length; i++) {
            if (tempGroups[i].appName === appName) {
                foundIndex = i; 
                isMuted = tempGroups[i].isMuted;
                break;
            }
        }

        if (foundIndex !== -1) {
            let g = tempGroups[foundIndex];
            g.notifs.unshift(newNotif); 
            if (!g.isExpanded && !isMuted) g.hasUnread = true;
            tempGroups.splice(foundIndex, 1);
            tempGroups.unshift(g); 
        } else {
            tempGroups.unshift({
                "appName": appName, "isExpanded": false, "isMuted": false, "hasUnread": true, "notifs": [newNotif]
            });
        }
        notifRoot.notificationGroups = tempGroups;
    }

    function removeNotification(gIndex, nIndex) {
        let temp = JSON.parse(JSON.stringify(notifRoot.notificationGroups));
        temp[gIndex].notifs.splice(nIndex, 1);
        if (temp[gIndex].notifs.length === 0) temp.splice(gIndex, 1); 
        notifRoot.notificationGroups = temp;
    }

    function clearGroup(gIndex) {
        let temp = JSON.parse(JSON.stringify(notifRoot.notificationGroups));
        temp.splice(gIndex, 1);
        notifRoot.notificationGroups = temp;
    }

    function toggleMute(gIndex) {
        let temp = JSON.parse(JSON.stringify(notifRoot.notificationGroups));
        temp[gIndex].isMuted = !temp[gIndex].isMuted;
        if (temp[gIndex].isMuted) temp[gIndex].hasUnread = false;
        notifRoot.notificationGroups = temp;
        
        let mApps = [];
        for(let i=0; i<temp.length; i++) {
            if(temp[i].isMuted) mApps.push(temp[i].appName);
        }
        notifRoot.mutedApps = mApps;
    }

    function toggleGroup(gIndex) {
        let temp = JSON.parse(JSON.stringify(notifRoot.notificationGroups));
        let g = temp[gIndex];
        
        if (!g.isExpanded) {
            g.isExpanded = true;
            g.hasUnread = false; 
        } else {
            g.isExpanded = false;
            for(let i = 0; i < g.notifs.length; i++) g.notifs[i].isNew = false;
        }
        notifRoot.notificationGroups = temp;
    }

    // --- MAIN TRAY UI ---
    ColumnLayout {
        anchors.fill: parent
        spacing: Metrics.spacingLarge
        anchors.margins: Metrics.spacingLarge

        // Header
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Notification Center"
                color: Theme.main
                font.family: Theme.fontMain
                font.pixelSize: 18
                font.weight: Font.Bold
            }
            Item { Layout.fillWidth: true } 
            
            Button {
                implicitWidth: 32; implicitHeight: 32
                visible: notifRoot.notificationGroups.length > 0
                background: Rectangle {
                    color: clearAllHover.containsMouse ? Theme.urgent : Qt.darker(Theme.base, 1.4)
                    radius: 16; border.width: 1
                    border.color: clearAllHover.containsMouse ? Theme.urgent : Theme.bridge
                }
                contentItem: Text {
                    text: "\uf014" 
                    color: clearAllHover.containsMouse ? Theme.base : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                    font.family: Theme.fontIcon; font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                MouseArea {
                    id: clearAllHover
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                    onClicked: notifRoot.notificationGroups = []
                }
            }
        }

        // Empty State
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: notifRoot.notificationGroups.length === 0
            ColumnLayout {
                anchors.centerIn: parent; spacing: 12
                Text {
                    text: "\uf0a2" 
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.2)
                    font.family: Theme.fontIcon; font.pixelSize: 48
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "You're all caught up!"
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                    font.family: Theme.fontMain; font.pixelSize: 15; font.weight: Font.Medium
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // Grouped Notifications
        Flickable {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: notifRoot.notificationGroups.length > 0
            contentHeight: historyColumn.implicitHeight
            clip: true; boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: historyColumn
                width: parent.width; spacing: 16

                Repeater {
                    model: notifRoot.notificationGroups
                    delegate: ColumnLayout {
                        width: parent.width; spacing: 8
                        property int gIndex: index
                        property var groupData: modelData

                        // Group Banner
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 40; color: "transparent"
                            RowLayout {
                                anchors.fill: parent; spacing: 8
                                Text {
                                    text: groupData.isExpanded ? "\uf107" : "\uf105" 
                                    color: Theme.main; font.family: Theme.fontIcon; font.pixelSize: 16
                                    MouseArea {
                                        anchors.fill: parent; anchors.margins: -10
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: notifRoot.toggleGroup(gIndex)
                                    }
                                }
                                Text {
                                    text: groupData.appName
                                    color: Theme.main; font.family: Theme.fontMain; font.pixelSize: 15; font.weight: Font.Bold
                                }
                                Text {
                                    text: "\uf0f3"; color: Theme.secondary; font.family: Theme.fontIcon; font.pixelSize: 13
                                    visible: groupData.hasUnread; transformOrigin: Item.Top
                                    SequentialAnimation on rotation {
                                        loops: Animation.Infinite; running: parent.visible
                                        NumberAnimation { to: 15; duration: 100 }
                                        NumberAnimation { to: -15; duration: 100 }
                                        NumberAnimation { to: 10; duration: 100 }
                                        NumberAnimation { to: -10; duration: 100 }
                                        NumberAnimation { to: 0; duration: 100 }
                                        PauseAnimation { duration: 1200 }
                                    }
                                }
                                Rectangle {
                                    width: 22; height: 22; radius: 11
                                    color: Qt.darker(Theme.base, 1.4); border.color: Theme.bridge; border.width: 1
                                    Text {
                                        anchors.centerIn: parent; text: groupData.notifs.length
                                        color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 11; font.weight: Font.Bold
                                    }
                                }
                                Item { Layout.fillWidth: true } 
                                Text {
                                    text: groupData.isMuted ? "\uf1f6" : "\uf0a2" 
                                    color: groupData.isMuted ? Theme.urgent : (groupMuteHover.containsMouse ? Theme.secondary : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4))
                                    font.family: Theme.fontIcon; font.pixelSize: 14
                                    MouseArea {
                                        id: groupMuteHover
                                        anchors.fill: parent; anchors.margins: -5
                                        cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                        onClicked: notifRoot.toggleMute(gIndex)
                                    }
                                }
                                Text {
                                    text: "\uf014" 
                                    color: groupClearHover.containsMouse ? Theme.urgent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                                    font.family: Theme.fontIcon; font.pixelSize: 14; Layout.leftMargin: 4
                                    MouseArea {
                                        id: groupClearHover
                                        anchors.fill: parent; anchors.margins: -5
                                        cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                        onClicked: notifRoot.clearGroup(gIndex)
                                    }
                                }
                            }
                        }

                        // Individual Cards
                        ColumnLayout {
                            Layout.fillWidth: true; Layout.leftMargin: 16; spacing: 8
                            visible: groupData.isExpanded

                            Repeater {
                                model: groupData.notifs
                                delegate: Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: notifCol.implicitHeight + 24
                                    color: Qt.darker(Theme.base, 1.4); radius: Metrics.radiusBase
                                    border.color: modelData.isNew ? Theme.secondary : Theme.bridge
                                    border.width: modelData.isNew ? 2 : 1
                                    property int nIndex: index

                                    ColumnLayout {
                                        id: notifCol
                                        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                        anchors.margins: 12; spacing: 8
                                        
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text {
                                                text: modelData.time; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                                                font.family: Theme.fontMain; font.pixelSize: 11; Layout.fillWidth: true
                                            }
                                            Item {
                                                width: 14; height: 14; property bool copied: false
                                                Text {
                                                    anchors.centerIn: parent; text: parent.copied ? "\uf00c" : "\uf0c5" 
                                                    color: parent.copied ? Theme.main : (copyHover.containsMouse ? Theme.secondary : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4))
                                                    font.family: Theme.fontIcon; font.pixelSize: 13
                                                }
                                                Timer { id: copyTimer; interval: 1500; onTriggered: parent.copied = false }
                                                MouseArea {
                                                    id: copyHover
                                                    anchors.fill: parent; anchors.margins: -5
                                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        clipboardHelper.copyToClipboard(modelData.summary + "\n" + modelData.body);
                                                        parent.copied = true; copyTimer.restart();
                                                    }
                                                }
                                            }
                                            Text {
                                                text: "\uf00d" 
                                                color: closeHover.containsMouse ? Theme.urgent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                                                font.family: Theme.fontIcon; font.pixelSize: 14; Layout.leftMargin: 8
                                                MouseArea {
                                                    id: closeHover
                                                    anchors.fill: parent; anchors.margins: -5
                                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: notifRoot.removeNotification(gIndex, nIndex)
                                                }
                                            }
                                        }

                                        // --- NEW CONTENT ROW WITH IMAGE ---
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 12
                                            Layout.alignment: Qt.AlignTop

                                            Rectangle {
                                                Layout.preferredWidth: img.status === Image.Ready ? 48 : 0
                                                Layout.preferredHeight: img.status === Image.Ready ? 48 : 0
                                                visible: img.status === Image.Ready 
                                                radius: Metrics.radiusBase
                                                color: "transparent"
                                                clip: true

                                                Image {
                                                    id: img
                                                    anchors.fill: parent
                                                    fillMode: Image.PreserveAspectCrop
                                                    cache: false
                                                    smooth: true
                                                    source: {
                                                        let path = modelData.iconStr;
                                                        if (!path || path === "") return "";
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
                                                            if (resolved && (resolved.includes("checkerboard") || resolved.includes("missing"))) return "";
                                                            return resolved;
                                                        } catch (e) { return ""; }
                                                    }
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignTop
                                                spacing: 4
                                                Text {
                                                    text: modelData.summary; color: Theme.text
                                                    font.family: Theme.fontMain; font.pixelSize: 14; font.weight: Font.Bold
                                                    Layout.fillWidth: true; wrapMode: Text.Wrap
                                                }
                                                Text {
                                                    text: modelData.body; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                                                    font.family: Theme.fontMain; font.pixelSize: 13
                                                    Layout.fillWidth: true; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight
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
        }
    }
}
