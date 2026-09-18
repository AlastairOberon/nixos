import QtQuick
import "../../../theme"
import "../launcher/"

Item {
    id: launcherRoot
    implicitWidth: 30
    implicitHeight: 30
    
    // Reactively checks if the Launcher is open AND on the Home tab (0)
    property bool isActive: template_float.visible && template_float.currentTabIndex === 0
    
    // --- THE BRIDGE ---
    // Exposes the entire LauncherWindow so other buttons (like Power, Volume, etc.) can control it
    property alias window: template_float

    // 1. Exposes the tray's muted apps list up to the Bar
    property alias globalMutedApps: template_float.globalMutedApps

    // 2. Passes the incoming notification data down into the window
    function forwardNotificationToTray(appName, summary, body, iconPath) {
        template_float.forwardNotificationToTray(appName, summary, body, iconPath);
    }
    
    LauncherWindow {
        id: template_float
    }

    // The highlight circle/pill background
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        // Active = Secondary, Hover = Urgent, Default = Transparent
        color: launcherRoot.isActive ? Theme.secondary : (launcherMouse.containsMouse ? Theme.urgent : "transparent")
        
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }

    Text {
        anchors.centerIn: parent
        text: ""
        font.pixelSize: 30 
        // Use the dark base color for the icon whenever the background is filled
        color: (launcherRoot.isActive || launcherMouse.containsMouse) ? Theme.base : Theme.text

        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }

    MouseArea {
        id: launcherMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (launcherRoot.isActive) {
                // If it's already open to the Home tab, close it
                template_float.visible = false;
            } else {
                // If it's closed OR on another tab, open and jump to Home
                template_float.currentTabIndex = 0;
                template_float.visible = true;
            }
        }
    }
}
