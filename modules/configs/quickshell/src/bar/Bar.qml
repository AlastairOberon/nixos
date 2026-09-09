import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "./barComponents/workspaces/"
import "./barComponents/power/"
import "./barComponents/time/"
import "./barComponents/audio/"
import "./barComponents/weather/"
import "./barComponents/launcher/"
import "./barComponents/network/"
//import "./barComponents/clipboard/"
//import "./barComponents/emoji/"
import "./barComponents/notifications/"

PanelWindow {
    id              : barWindow
    property var dashboardWindow: null
    
    // Fetch the scale dynamically based on which monitor this specific bar is rendering on
    property real activeScale: screen ? Theme.getMonitorScale(screen.name) : 1.0
    
    // Window Setup
    anchors {
        top         : true
        left        : true
        right       : true
    }
    
    // Scale the actual Wayland window reservation space
    implicitHeight  : 40 * barWindow.activeScale
    exclusiveZone   : height
    color           : "transparent"

    property real bgOpacity: 0.8 

    // Background Layer (Fills the entire window)
    Rectangle {
        anchors.fill: parent
        color: Theme.base
        opacity: barWindow.bgOpacity
        border.color: Theme.base
        border.width: 1
    }

    // SCALED UI WRAPPER
    Item {
        // Divide width and height by the scale so that when it gets multiplied 
        // by the scale transform below, it perfectly fits the parent window without overflowing
        width: parent.width / barWindow.activeScale
        height: parent.height / barWindow.activeScale
        
        scale: barWindow.activeScale
        transformOrigin: Item.TopLeft

        // Left Aligned
        RowLayout {
            anchors.left        : parent.left
            anchors.top         : parent.top
            anchors.bottom      : parent.bottom
            anchors.leftMargin  : 10

            Launcher {
                id: myLauncher
            } 
            Workspaces {}
        }
        
        // Center Aligned
        RowLayout {
            anchors.centerIn    : parent
            spacing             : 20
            Climate {}
            Visualizer {}
            Clock {}
            Connection {}
            Volume {}
            Brightness {}
        }

        // Right Aligned
        RowLayout {
            anchors.right           : parent.right
            anchors.top             : parent.top
            anchors.bottom          : parent.bottom
            anchors.rightMargin     : 15
            spacing                 : 15 

            //Stats {}
            //Disks {}
            //Emoji {}
            //Clipboard {}
            Power {}
        }
    }

    // --- TOP LEVEL WINDOWS & DAEMONS ---
    NotificationToast {
        mutedApps: myLauncher.globalMutedApps

        // Catches the 4 arguments and sends them to the Launcher
        onIncomingNotification: (appName, summary, body, iconPath) => {
            myLauncher.forwardNotificationToTray(appName, summary, body, iconPath);
        }
    }
}

