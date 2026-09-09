import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "./bar_components" 
import "./bar_components/audio"
import "./bar_components/clock"
import "./bar_components/system"
import "./bar_components/network"
import "./bar_components/workspaces"
import "./bar_components/notifications"

// Add the import for your new widget
import "./bar_components/pc_status"

Item {
    id: barLayout
    property var parentWindow
    
    // THE FIX: Move the anchor inside the component to avoid the scope bug!
    anchors.fill: parent
    
    property real bgOpacity: 0.5 

    // ==========================================
    // 1. THE BACKGROUND LAYER
    // ==========================================
    Rectangle {
        anchors.fill: parent
        color: Theme.base
        opacity: barLayout.bgOpacity
        border.color: Theme.bridge
        border.width: 1
    }

    // ==========================================
    // 2. THE CONTENT LAYER
    // ==========================================
    
    // --- LEFT SECTION ---
    RowLayout {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        
        Workspaces {} 
    }
    
    // --- CENTER SECTION ---
    NotificationIndicator {
        anchors.centerIn: parent
        parentWindow: barLayout.parentWindow
    }

    // --- RIGHT SECTION ---
    RowLayout {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: 15
        spacing: 15 

        UniversalIndicator { parentWindow: barLayout.parentWindow }
        Clock { parentWindow: barLayout.parentWindow }
    }

    // --- OVERLAYS & TOASTS ---
    NotificationToast {
        parentWindow: barLayout.parentWindow
    }
}
