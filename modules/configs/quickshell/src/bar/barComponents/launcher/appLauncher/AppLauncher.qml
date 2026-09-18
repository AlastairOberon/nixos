import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

import "../../../../theme" 
import "../../../../theme/components" 

Item {
    id: appLauncherRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    property string searchQuery: ""

    function closeWindow() {
        let p = appLauncherRoot;
        while (p && !p.focusable) p = p.parent;
        if (p) p.visible = false;
    }

    onVisibleChanged: {
        if (visible) {
            searchQuery = "";
            searchInput.text = "";
            searchInput.forceActiveFocus();
            appList.currentIndex = -1;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Metrics.spacingLarge
        anchors.topMargin: Metrics.spacingLarge
        anchors.bottomMargin: Metrics.spacingLarge

        // --- SEARCH HEADER ---
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Metrics.spacingLarge
            Layout.rightMargin: Metrics.spacingLarge
            spacing: Metrics.spacingLarge

            // Search Icon Box
            Rectangle {
                Layout.preferredWidth: 60
                Layout.preferredHeight: 60
                radius: Metrics.radiusBase
                color: Theme.main

                Text {
                    anchors.centerIn: parent
                    text: "\uf002" // Search icon
                    color: Theme.base
                    font.family: Theme.fontIcon
                    font.pixelSize: 26
                }
            }

            // Search Text Field
            TextField {
                id: searchInput
                Layout.fillWidth: true
                Layout.preferredHeight: 60   
                placeholderText: "Search applications..."
                placeholderTextColor: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                color: Theme.text
                
                font.family: Theme.fontMain   
                font.pixelSize: 22   
                verticalAlignment: TextInput.AlignVCenter
                
                background: Rectangle {
                    color: Qt.darker(Theme.base, 1.2)
                    radius: Metrics.radiusBase
                    border.width: searchInput.activeFocus ? 2 : 1
                    border.color: searchInput.activeFocus ? Theme.main : Theme.bridge
                    
                    Behavior on border.color { 
                        ColorAnimation { duration: Metrics.animFast }
                    }
                }
                
                onTextChanged: {
                    appLauncherRoot.searchQuery = text.toLowerCase();
                    appList.currentIndex = -1;
                }
                
                Keys.onDownPressed: {
                    if (appList.currentIndex < 0) {
                        appList.currentIndex = 0;
                    } else {
                        appList.currentIndex = Math.min(appList.currentIndex + 1, appList.count - 1);
                    }
                }
                Keys.onUpPressed: {
                    if (appList.currentIndex <= 0) {
                        appList.currentIndex = appList.count - 1;
                    } else {
                        appList.currentIndex = Math.max(appList.currentIndex - 1, 0);
                    }
                }
                Keys.onReturnPressed: {
                    const targetIndex = appList.currentIndex >= 0 ? appList.currentIndex : 0;
                    const currentApp = appList.model ? appList.model[targetIndex] : null;
                    if (currentApp) {
                        currentApp.execute();
                        appLauncherRoot.closeWindow();
                    }
                }
                Keys.onEscapePressed: {
                    appLauncherRoot.closeWindow();
                }
            }
        }

        // --- APPLICATION LIST ---
        FadedList {
            id: appList
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Metrics.spacingSmall
            Layout.leftMargin: Metrics.spacingLarge
            Layout.rightMargin: Metrics.spacingLarge
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            
            model: {
                const allApps = (DesktopEntries && DesktopEntries.applications) ? DesktopEntries.applications.values : [];
                const query = appLauncherRoot.searchQuery.trim();
                
                if (query === "") return allApps;
                
                return allApps.filter(app => {
                    const inName = app.name && app.name.toLowerCase().includes(query);
                    const inGeneric = app.genericName && app.genericName.toLowerCase().includes(query);
                    const inComment = app.comment && app.comment.toLowerCase().includes(query);
                    return inName || inGeneric || inComment;
                });
            }
            
            delegate: ThemeButton {
                id: delegateRoot 
                required property int index
                required property var modelData

                width: appList.width - (Metrics.spacingBase * 2)
                height: 70 
                selected: appList.currentIndex === index
                
                color: delegateRoot.isActive ? Theme.main : "transparent"
                border.width: 0
                border.color: "transparent"
                
                HoverHandler {
                    onHoveredChanged: {
                        if (hovered) appList.currentIndex = index;
                    }
                }
                
                onClicked: {
                    modelData.execute();
                    appLauncherRoot.closeWindow();
                }

                RowLayout {
                    id: contentRow 
                    anchors.fill: parent
                    anchors.margins: Metrics.spacingBase
                    spacing: Metrics.spacingBase
                    
                    IconImage {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        Layout.alignment: Qt.AlignVCenter 
                        
                        source: {
                            if (!modelData.icon) return "";
                            if (modelData.icon.startsWith("/")) return "file://" + modelData.icon;
                            return "image://icon/" + modelData.icon;
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter 
                        spacing: 2
                        clip: true 
                        
                        Text {
                            Layout.fillWidth: true
                            text: modelData.name || "Unknown App"
                            color: delegateRoot.isActive ? Theme.base : Theme.text
                            
                            font.family: Theme.fontMain   
                            font.pixelSize: 18   
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            
                            Behavior on color { ColorAnimation { duration: Metrics.animBase } }
                        }
                        
                        Text {
                            Layout.fillWidth: true
                            text: modelData.comment || modelData.genericName || ""
                            color: delegateRoot.isActive ? Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.7) : Qt.lighter(Theme.text, 1.4)
                            
                            font.family: Theme.fontMain   
                            font.pixelSize: 13   
                            elide: Text.ElideRight
                            visible: text !== "" 
                            
                            Behavior on color { ColorAnimation { duration: Metrics.animBase } }
                        }
                    }
                }
            }
        }
    }
}
