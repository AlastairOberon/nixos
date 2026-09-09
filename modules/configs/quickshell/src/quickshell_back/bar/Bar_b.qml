import QtQuick
import QtQuick.Layouts
import Quickshell
import "./bar_components"
import "./bar_components/tray"
import "./bar_components/audio"
import "./bar_components/power"
import "./bar_components/shortcuts"

Item {
    id: bottomBarLayout
    property var parentWindow
    
    anchors.fill: parent
    
    property real bgOpacity: 0.5 

    // ==========================================
    // 1. THE BACKGROUND LAYER
    // ==========================================
    Rectangle {
        anchors.fill: parent
        color: Theme.base
        opacity: bottomBarLayout.bgOpacity
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
        anchors.leftMargin: 15
        
//        Visualizer {
//            parentWindow: bottomBarLayout.parentWindow
//        }
    }

    // --- RIGHT SECTION ---
    RowLayout {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: 15
        spacing: 15 

        TrayIndicator {
            parentWindow: bottomBarLayout.parentWindow
        }

        ShortcutsIndicator {
            parentWindow: bottomBarLayout.parentWindow
        }

        PowerIndicator {
            parentWindow: bottomBarLayout.parentWindow
        }
    }
}
