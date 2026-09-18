import QtQuick
import QtQuick.Effects
import Quickshell.Wayland
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import "../../../theme" 
import "../../../theme/components" 

Template_Floating {
    id: launcherWindow
    
    // 1. Set a default scale, updated when the window becomes visible
    property real activeScale: 1.0

    // 2. Multiply base dimensions by the active scale
    windowWidth: 1080 * activeScale
    windowHeight: 720 * activeScale
    
    visible: false
    focusable: true
    WlrLayershell.namespace: "quickshell"

    property int currentTabIndex: 0
    property var globalMutedApps: []

    // --- KEYBOARD SHORTCUTS ---
    Shortcut {
        sequence: "Esc"
        onActivated: launcherWindow.visible = false
    }

    Shortcut {
        sequence: "Super+Space"
        onActivated: {
            if (launcherWindow.currentTabIndex === 1) {
                launcherWindow.visible = false;
            } else {
                launcherWindow.currentTabIndex = 1;
            }
        }
    }

    Shortcut {
        sequence: "Super+V"
        onActivated: {
            if (launcherWindow.currentTabIndex === 6) {
                launcherWindow.visible = false;
            } else {
                launcherWindow.currentTabIndex = 6;
            }
        }
    }

    property var pendingNotifications: []
    property int unreadNotificationCount: 0

    function updateUnreadCount() {
        let count = (launcherWindow.pendingNotifications ? launcherWindow.pendingNotifications.length : 0);
        if (theNotificationTray.status === Loader.Ready && theNotificationTray.item && theNotificationTray.item.notificationGroups) {
            let groups = theNotificationTray.item.notificationGroups;
            for (let i = 0; i < groups.length; i++) {
                if (groups[i].notifs) {
                    for (let j = 0; j < groups[i].notifs.length; j++) {
                        if (groups[i].notifs[j].isNew) count++;
                    }
                }
            }
        }
        launcherWindow.unreadNotificationCount = count;
    }

    // --- THE UPDATED BRIDGE FUNCTION ---
    function forwardNotificationToTray(appName, summary, body, iconPath) {
        if (theNotificationTray.status === Loader.Ready && theNotificationTray.item && typeof theNotificationTray.item.pushNotification === "function") {
            theNotificationTray.item.pushNotification(appName, summary, body, iconPath);
        } else {
            launcherWindow.pendingNotifications.push({ appName: appName, summary: summary, body: body, iconPath: iconPath });
            theNotificationTray.active = true;
        }
        launcherWindow.updateUnreadCount();
    }

    // 3. Dynamically fetch the correct screen scale EXACTLY when the popup opens
    onVisibleChanged: {
        if (visible) {
            activeScale = screen ? Theme.getMonitorScale(screen.name) : 1.0;
        }
    }

    // 4. The Scaled Wrapper to prevent clipping
    Item {
        // Divide by the scale so it perfectly fills the window when multiplied below
        width: parent.width / launcherWindow.activeScale
        height: parent.height / launcherWindow.activeScale
        
        scale: launcherWindow.activeScale
        transformOrigin: Item.TopLeft

        RowLayout {
            anchors.fill: parent
            anchors.topMargin: Metrics.spacingLarge
            anchors.bottomMargin: Metrics.spacingLarge
            anchors.rightMargin: Metrics.spacingLarge
            anchors.leftMargin: 0
            spacing: 0

            // ==========================================
            // SIDEBAR NAVIGATION (CAROUSEL WITH SLIDING WINDOW)
            // ==========================================
            Item {
                id: sidebarArea
                Layout.preferredWidth: 80
                Layout.fillHeight: true

                // Carousel Configuration & Sliding Window Logic
                property var tabList: [
                    // --- 1. CORE NAVIGATION & APPS ---
                    { tabIndex: 0,  iconText: "\uf015" }, // Home (Dashboard)
                    { tabIndex: 1,  iconText: "\uf135" }, // Apps (App Launcher)
                    { tabIndex: 16, iconText: "\uf2d2" }, // System Tray / Open Applications
                    { tabIndex: 2,  iconText: "\uf2d0" }, // Workspace Overview
                    { tabIndex: 3,  iconText: "\uf0f3" }, // Notifications Tray

                    // --- 2. PRODUCTIVITY TOOLS ---
                    { tabIndex: 6,  iconText: "\uf0ea" }, // Clipboard History
                    { tabIndex: 7,  iconText: "\uf118" }, // Emoji Picker

                    // --- 3. MEDIA & HARDWARE CONTROLS ---
                    { tabIndex: 4,  iconText: "\uf001" }, // Media Player
                    { tabIndex: 5,  iconText: "\uf028" }, // Audio (Volume & Sinks)

                    // --- 4. ENVIRONMENT & INFO ---
                    { tabIndex: 8,  iconText: "\uf017" }, // Time & Date
                    { tabIndex: 9,  iconText: "\ue30f" }, // Weather
                    { tabIndex: 10, iconText: "\uf1eb" }, // Network

                    // --- 5. SYSTEM HEALTH & TELEMETRY ---
                    { tabIndex: 13, iconText: "\uf2db" }, // Computer Stats (CPU/RAM)
                    { tabIndex: 15, iconText: "\uf240" }, // Power & Battery Usage
                    { tabIndex: 12, iconText: "\uf1c0" }, // Storage
                    { tabIndex: 11, iconText: "\uf108" }, // Monitor Settings

                    // --- 6. SESSION ---
                    { tabIndex: 14, iconText: "\uf011" }  // Power Session
                ]

                property int windowSize: 7
                property int scrollIndex: 0

                function updateScrollFromTab() {
                    for (let i = 0; i < tabList.length; i++) {
                        if (tabList[i].tabIndex === launcherWindow.currentTabIndex) {
                            scrollIndex = i;
                            break;
                        }
                    }
                }

                Connections {
                    target: launcherWindow
                    function onCurrentTabIndexChanged() {
                        sidebarArea.updateScrollFromTab();
                    }
                    function onVisibleChanged() {
                        if (launcherWindow.visible) {
                            sidebarArea.updateScrollFromTab();
                        }
                    }
                }

                property int windowStart: Math.min(
                    Math.max(0, scrollIndex - Math.floor(windowSize / 2)),
                    Math.max(0, tabList.length - windowSize)
                )

                // Mouse wheel handler for smooth scrolling through the carousel
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: false
                    acceptedButtons: Qt.NoButton
                    onWheel: (wheel) => {
                        if (wheel.angleDelta.y < 0) {
                            sidebarArea.scrollIndex = Math.min(sidebarArea.tabList.length - 1, sidebarArea.scrollIndex + 1);
                        } else if (wheel.angleDelta.y > 0) {
                            sidebarArea.scrollIndex = Math.max(0, sidebarArea.scrollIndex - 1);
                        }
                    }
                }

                // Masked Carousel Track
                Item {
                    id: sidebarTrackContainer
                    anchors.fill: parent
                    anchors.leftMargin: 0
                    anchors.rightMargin: 1
                    clip: true

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: sidebarFadeMask
                    }

                    ColumnLayout {
                        id: sidebarTrack
                        anchors.centerIn: parent
                        spacing: 0

                        Repeater {
                            model: sidebarArea.tabList

                            Item {
                                id: itemWrapper
                                required property int index
                                required property var modelData

                                property int tabIndex: modelData.tabIndex
                                property string iconText: modelData.iconText

                                property bool inWindow: index >= sidebarArea.windowStart && index < (sidebarArea.windowStart + sidebarArea.windowSize)
                                property bool isTopEdge: index === sidebarArea.windowStart && sidebarArea.windowStart > 0
                                property bool isBottomEdge: index === (sidebarArea.windowStart + sidebarArea.windowSize - 1) && (sidebarArea.windowStart + sidebarArea.windowSize) < sidebarArea.tabList.length
                                property bool isEdge: isTopEdge || isBottomEdge
                                property bool isTopPeek: index === (sidebarArea.windowStart - 1)
                                property bool isBottomPeek: index === (sidebarArea.windowStart + sidebarArea.windowSize)
                                property bool isPeek: isTopPeek || isBottomPeek

                                property real targetHeight: {
                                    if (inWindow) return 50 + (index === sidebarArea.tabList.length - 1 ? 0 : Metrics.spacingBase);
                                    if (isPeek) return 18 + (index === sidebarArea.tabList.length - 1 ? 0 : Metrics.spacingBase);
                                    return 0;
                                }

                                Layout.preferredWidth: 50
                                Layout.preferredHeight: targetHeight
                                Layout.alignment: Qt.AlignHCenter
                                clip: true

                                Behavior on Layout.preferredHeight {
                                    NumberAnimation {
                                        duration: 350
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Rectangle {
                                    id: btnContainer
                                    width: 50
                                    height: 50
                                    anchors.centerIn: parent
                                    radius: Metrics.radiusBase

                                    property bool isActive: launcherWindow.currentTabIndex === itemWrapper.tabIndex

                                    opacity: {
                                        if (itemWrapper.inWindow) return itemWrapper.isEdge ? 0.45 : 1.0;
                                        if (itemWrapper.isPeek) return 0.18;
                                        return 0.0;
                                    }

                                    scale: {
                                        if (itemWrapper.inWindow) return itemWrapper.isEdge ? 0.75 : 1.0;
                                        if (itemWrapper.isPeek) return 0.35;
                                        return 0.0;
                                    }

                                    Behavior on opacity {
                                        NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on scale {
                                        NumberAnimation { duration: 350; easing.type: Easing.OutBack }
                                    }

                                    color: isActive ? Theme.secondary : (btnMouse.containsMouse ? Theme.bridge : "transparent")
                                    Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: itemWrapper.iconText
                                        color: btnContainer.isActive ? Theme.base : (btnMouse.containsMouse ? Theme.text : Theme.secondary)
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 22
                                        Behavior on color { ColorAnimation { duration: Metrics.animBase } }
                                    }

                                    MouseArea {
                                        id: btnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            launcherWindow.currentTabIndex = itemWrapper.tabIndex;
                                            sidebarArea.scrollIndex = itemWrapper.index;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    id: sidebarFadeMask
                    anchors.fill: sidebarTrackContainer
                    visible: false
                    layer.enabled: true

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.05; color: "white" }
                            GradientStop { position: 0.95; color: "white" }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }
                }

                // Subtle Vertical Divider
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: Theme.bridge
                }
            }

            // ==========================================
            // MAIN CONTENT AREA (STACK LAYOUT)
            // ==========================================
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: Metrics.spacingLarge
                currentIndex: launcherWindow.currentTabIndex

                // Reusable lazy loader component: only loads when viewed
                component LazyTab: Loader {
                    property int tabIndex
                    property string tabSource
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    property bool hasLoaded: false
                    active: (launcherWindow.currentTabIndex === tabIndex && launcherWindow.visible) || hasLoaded
                    source: active ? tabSource : ""
                    onLoaded: hasLoaded = true
                }

                // INDEX 0: Home
                LazyTab { tabIndex: 0; tabSource: "dashboard/Dashboard.qml" }

                // INDEX 1: Apps
                LazyTab { tabIndex: 1; tabSource: "appLauncher/AppLauncher.qml" }

                // INDEX 2: Workspace Overview
                LazyTab { tabIndex: 2; tabSource: "workspaceOverview/WorkspaceOverview.qml" }

                // INDEX 3: Notifications
                Loader {
                    id: theNotificationTray
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    property bool hasLoaded: false
                    active: (launcherWindow.currentTabIndex === 3 && launcherWindow.visible) || hasLoaded
                    source: active ? "notificationTray/NotificationTray.qml" : ""
                    onLoaded: {
                        hasLoaded = true;
                        if (item) {
                            launcherWindow.globalMutedApps = item.mutedApps;
                            item.mutedAppsChanged.connect(function() {
                                launcherWindow.globalMutedApps = item.mutedApps;
                            });
                            item.notificationGroupsChanged.connect(function() {
                                launcherWindow.updateUnreadCount();
                            });
                            while (launcherWindow.pendingNotifications.length > 0) {
                                let n = launcherWindow.pendingNotifications.shift();
                                item.pushNotification(n.appName, n.summary, n.body, n.iconPath);
                            }
                            launcherWindow.updateUnreadCount();
                        }
                    }
                }
                
                // INDEX 4: Media Player
                LazyTab { tabIndex: 4; tabSource: "mediaPlayer/MediaPlayer.qml" }

                // INDEX 5: Audio
                LazyTab { tabIndex: 5; tabSource: "audio/Audio.qml" }

                // INDEX 6: Clipboard
                LazyTab { tabIndex: 6; tabSource: "clipboardHistory/ClipboardHistory.qml" }

                // INDEX 7: Emoji
                LazyTab { tabIndex: 7; tabSource: "emojiPicker/EmojiPicker.qml" }

                // INDEX 8: Time & Date
                LazyTab { tabIndex: 8; tabSource: "timeDate/TimeDate.qml" }
                
                // INDEX 9: Weather
                LazyTab { tabIndex: 9; tabSource: "weatherReport/WeatherReport.qml" }

                // INDEX 10: Network
                LazyTab { tabIndex: 10; tabSource: "networkConnectivity/NetworkConnectivity.qml" }
                
                // INDEX 11: Monitor Settings
                LazyTab { tabIndex: 11; tabSource: "monitorSettings/MonitorSettings.qml" }

                // INDEX 12: Storage
                LazyTab { tabIndex: 12; tabSource: "storageStats/StorageStats.qml" }

                // INDEX 13: Computer Stats
                LazyTab { tabIndex: 13; tabSource: "systemStats/SystemStats.qml" }
                
                // INDEX 14: Power Menu 
                LazyTab { tabIndex: 14; tabSource: "powerMenu/PowerMenu.qml" }

                // INDEX 15: Power Usage
                LazyTab { tabIndex: 15; tabSource: "powerUsage/PowerUsage.qml" }

                // INDEX 16: System Tray / Open Applications
                LazyTab { tabIndex: 16; tabSource: "systemTray/SystemTray.qml" }
            }
        }
    }
}
