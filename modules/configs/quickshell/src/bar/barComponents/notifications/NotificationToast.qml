import QtQuick
import QtQuick.Layouts
import QtCore 
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

import "../../../theme" 
import "../../../theme/components" 

PanelWindow {
    id: toastOverlay

    anchors { top: true }
    margins { top: 20 }
    color: "transparent"
    
    implicitWidth: 550
    implicitHeight: toastList.contentHeight
    visible: toastModel.count > 0
    
    WlrLayershell.layer: WlrLayer.Overlay 
    exclusiveZone: 0 

    property var mutedApps: []
    signal incomingNotification(string appName, string summary, string body, string iconPath)

    // --- EMBEDDED D-BUS SERVER ---
    NotificationServer {
        bodySupported: true
        onNotification: (notification) => {
            let app = notification.appName || "System";
            let sum = notification.summary;
            let bod = notification.body;
            
            // Extract image or icon using your robust method
            let img = notification.image ? notification.image.toString() : "";
            let icon = notification.appIcon ? notification.appIcon.toString() : "";
            let iconPath = img !== "" ? img : icon;

            // Fire signal to Tray
            toastOverlay.incomingNotification(app, sum, bod, iconPath);

            if (!toastOverlay.mutedApps.includes(app)) {
                let d = new Date();
                let timeStr = d.toLocaleTimeString(Qt.locale(), "hh:mm AP");

                toastModel.insert(0, {
                    "notifId": Math.random().toString(), 
                    "appName": app,
                    "summary": sum,
                    "body": bod,
                    "iconStr": iconPath,
                    "time": timeStr
                });
            }
        }
    }

    ListModel { id: toastModel }

    ListView {
        id: toastList
        width: parent.width
        implicitHeight: contentHeight 
        model: toastModel
        spacing: 12
        interactive: false 

        add: Transition { 
            NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutQuad }
            NumberAnimation { properties: "y"; from: -50; to: 0; duration: 250; easing.type: Easing.OutBack }
        }
        remove: Transition { NumberAnimation { properties: "opacity,scale"; to: 0; duration: 200; easing.type: Easing.InQuad } }
        displaced: Transition { NumberAnimation { properties: "y"; duration: 250; easing.type: Easing.OutQuad } }

        delegate: Item {
            width: ListView.view.width
            implicitHeight: toastCard.implicitHeight
            property int myIndex: index

            Timer {
                running: true
                interval: 5000 
                onTriggered: {
                    for(let i = 0; i < toastModel.count; i++) {
                        if (toastModel.get(i).notifId === model.notifId) {
                            toastModel.remove(i);
                            break;
                        }
                    }
                }
            }

            Rectangle {
                id: toastCard
                width: parent.width
                implicitHeight: toastCol.implicitHeight + 24
                color: Theme.base; radius: Metrics.radiusBase; border.color: Theme.main; border.width: 2

                Rectangle { anchors.fill: parent; radius: parent.radius; color: "black"; opacity: 0.3; z: -1; anchors.margins: -4 }

                ColumnLayout {
                    id: toastCol
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 12; spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "\uf0f3"; color: Theme.main; font.family: Theme.fontIcon; font.pixelSize: 12 }
                        Text {
                            text: model.appName; color: Theme.main; font.family: Theme.fontMain
                            font.pixelSize: 12; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight
                        }
                        Text { text: model.time; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5); font.family: Theme.fontMain; font.pixelSize: 11 }
                        Text {
                            text: "\uf00d"; color: toastCloseHover.containsMouse ? Theme.urgent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                            font.family: Theme.fontIcon; font.pixelSize: 14; Layout.leftMargin: 8
                            MouseArea {
                                id: toastCloseHover
                                anchors.fill: parent; anchors.margins: -10; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: toastModel.remove(myIndex)
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // --- IMAGE BLOCK USING YOUR PROVEN LOGIC ---
                        Rectangle {
                            Layout.preferredWidth: img.status === Image.Ready ? 64 : 0
                            Layout.preferredHeight: img.status === Image.Ready ? 64 : 0
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
                                    let path = model.iconStr;
                                    if (!path || path === "") return "";

                                    try {
                                        // This already contains "file://"
                                        let homeUri = StandardPaths.standardLocations(StandardPaths.HomeLocation)[0];

                                        if (path.startsWith("image://icon/")) {
                                            path = path.substring(13); 
                                        }

                                        if (path.includes("/") && (path.endsWith(".png") || path.endsWith(".jpg"))) {
                                            if (!path.startsWith("/") && !path.startsWith("file://") && !path.startsWith("~/")) {
                                                // Removed the extra "file://" prefix here
                                                return homeUri + "/" + path;
                                            }
                                        }

                                        if (path.startsWith("~/")) {
                                            // Removed the extra "file://" prefix here
                                            return homeUri + "/" + path.substring(2);
                                        }

                                        if (path.startsWith("/")) {
                                            return "file://" + path;
                                        }

                                        if (path.includes("://")) {
                                            return path;
                                        }

                                        let resolved = Quickshell.iconPath(path);
                                        if (resolved && (resolved.includes("checkerboard") || resolved.includes("missing"))) {
                                            return "";
                                        }
                                        
                                        return resolved;
                                        
                                    } catch (e) {
                                        return "";
                                    }
                                }
                            }

                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: 4

                            Text { 
                                text: model.summary; color: Theme.text; 
                                font.family: Theme.fontMain; font.pixelSize: 15; font.weight: Font.Bold; 
                                Layout.fillWidth: true; wrapMode: Text.Wrap 
                            }
                            Text { 
                                text: model.body; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7); 
                                font.family: Theme.fontMain; font.pixelSize: 13; 
                                Layout.fillWidth: true; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight 
                            }
                        }
                    }
                }
            }
        }
    }
}
