import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import ".." // Imports Theme

Item {
    id: root
    // Increased the clickable hitbox to comfortably fit the wider bar
    implicitWidth: 410
    implicitHeight: 30

    property var parentWindow

    // --- THE BULLETPROOF FIX ---
    Repeater {
        id: dbusWatcher
        model: NotificationDaemon.trackedNotifications
        delegate: Item {} 
    }

    MouseArea {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        onClicked: notifPopup.toggle()

        // THE MINIMALIST HORIZONTAL BAR
        Rectangle {
            anchors.centerIn: parent
            // Doubled the width from 20 to 40
            width: 400
            height: 6
            radius: 3 
            
            // Bind to our always-awake DBus watcher
            color: dbusWatcher.count > 0 ? Theme.main : Theme.inactive
            
            opacity: button.containsMouse ? 0.7 : 1.0
            
            Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        // The Popup Instance
        NotificationPopup {
            id: notifPopup
            parentWindow: root.parentWindow
            anchorTarget: root 
        }
    }
}
