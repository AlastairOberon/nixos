import QtQuick
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

    // --- ESCAPE KEY SHORTCUT ---
    Shortcut {
        sequence: "Esc"
        onActivated: launcherWindow.visible = false
    }

    // --- THE UPDATED BRIDGE FUNCTION ---
    function forwardNotificationToTray(appName, summary, body, iconPath) {
        if (theNotificationTray && typeof theNotificationTray.pushNotification === "function") {
            theNotificationTray.pushNotification(appName, summary, body, iconPath);
        }
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
            anchors.margins: Metrics.spacingLarge
            spacing: 0

            // ==========================================
            // SIDEBAR NAVIGATION (ICON ONLY)
            // ==========================================
            Item {
                Layout.preferredWidth: 80
                Layout.fillHeight: true

                Flickable {
                    anchors.fill: parent
                    contentHeight: sidebarColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: contentHeight > height 

                    ColumnLayout {
                        id: sidebarColumn
                        width: parent.width
                        spacing: Metrics.spacingBase

                        component SidebarButton: Rectangle {
                            property int tabIndex
                            property string iconText
                            
                            Layout.preferredWidth: 50
                            Layout.preferredHeight: 50
                            Layout.alignment: Qt.AlignHCenter
                            radius: Metrics.radiusBase
                            
                            property bool isActive: launcherWindow.currentTabIndex === tabIndex
                            
                            color: isActive ? Theme.secondary : (btnMouse.containsMouse ? Theme.bridge : "transparent")
                            Behavior on color { ColorAnimation { duration: Metrics.animFast } }

                            Text {
                                anchors.centerIn: parent
                                text: parent.iconText
                                color: parent.isActive ? Theme.base : (btnMouse.containsMouse ? Theme.text : Theme.secondary)
                                font.family: Theme.fontIcon
                                font.pixelSize: 22
                                Behavior on color { ColorAnimation { duration: Metrics.animBase } }
                            }

                            MouseArea {
                                id: btnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: launcherWindow.currentTabIndex = parent.tabIndex
                            }
                        }

                        // --- NAVIGATION TABS ---
                        SidebarButton { tabIndex: 0; iconText: "\uf015" }  // Home
                        SidebarButton { tabIndex: 1; iconText: "\uf135" }  // Apps
                        SidebarButton { tabIndex: 2; iconText: "\uf2d0" }  // Workspace
                        SidebarButton { tabIndex: 3; iconText: "\uf0f3" }  // Notifications
                        SidebarButton { tabIndex: 4; iconText: "\uf001" }  // Media Player (NEW)
                        SidebarButton { tabIndex: 5; iconText: "\uf028" }  // Audio
                        SidebarButton { tabIndex: 6; iconText: "\uf0ea" }  // Clipboard
                        SidebarButton { tabIndex: 7; iconText: "\uf118" }  // Emoji
                        SidebarButton { tabIndex: 8; iconText: "\uf017" }  // Time/Date
                        SidebarButton { tabIndex: 9; iconText: "\ue30f" }  // Weather
                        SidebarButton { tabIndex: 10; iconText: "\uf1eb" } // Network
                        SidebarButton { tabIndex: 11; iconText: "\uf108" } // Monitor Settings
                        SidebarButton { tabIndex: 12; iconText: "\uf1c0" } // Storage
                        SidebarButton { tabIndex: 13; iconText: "\uf2db" } // Computer Stats
                        SidebarButton { tabIndex: 14; iconText: "\uf011" } // Power Session
                        
                        Item { Layout.fillHeight: true } 
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

                // INDEX 0: Home
                Dashboard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                // INDEX 1: Apps
                AppLauncher {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                // INDEX 2: Workspace Overview
                WorkspaceOverview {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                // INDEX 3: Notifications
                NotificationTray {
                    id: theNotificationTray
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onMutedAppsChanged: { launcherWindow.globalMutedApps = mutedApps; }
                }
                
                // INDEX 4: Media Player (NEW)
                MediaPlayer {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                // INDEX 5: Audio
                Audio {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                // INDEX 6: Clipboard
                ClipboardHistory {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                // INDEX 7: Emoji
                EmojiPicker {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                // INDEX 8: Time & Date
                TimeDate {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                
                // INDEX 9: Weather
                WeatherReport {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                // INDEX 10: Network
                NetworkConnectivity {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                
                // INDEX 11: Monitor Settings
                MonitorSettings {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                // INDEX 12: Storage
                StorageStats {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                // INDEX 13: Computer Stats
                SystemStats {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                
                // INDEX 14: Power Menu 
                PowerMenu {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
