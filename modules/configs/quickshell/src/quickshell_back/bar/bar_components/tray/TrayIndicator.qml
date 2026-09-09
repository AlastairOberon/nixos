import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io 
import Quickshell.Services.SystemTray 
import "../" 

Item {
    id: indicatorRoot
    
    Layout.preferredWidth: contentRow.implicitWidth + 12
    Layout.fillHeight: true

    property var parentWindow
    
    property int openAppCount: 0
    
    // THE FIX: Combines Hyprland windows + Background Tray apps!
    property int totalCount: openAppCount + SystemTray.items.length

    // --- LIVE WINDOW COUNTER ---
    Process {
        id: appCounter
        command: ["bash", "-c", "hyprctl clients 2>/dev/null | grep -c '^Window' || true"]
        stdout: SplitParser {
            onRead: function(data) {
                let count = parseInt(data.trim());
                if (!isNaN(count)) indicatorRoot.openAppCount = count;
            }
        }
    }

    Timer {
        interval: 1000 
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: appCounter.running = true
    }

    // --- UI DISPLAY ---
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰏖" 
            color: trayMouse.containsMouse ? "#FFFFFF" : Theme.main
            font.pixelSize: 18
            font.bold: true
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: indicatorRoot.totalCount 
            color: "#FFFFFF"
            font.pixelSize: 13
            font.bold: true
            visible: indicatorRoot.totalCount > 0 
        }
    }

    MouseArea {
        id: trayMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: trayPopup.toggle()
    }

    TrayPopup {
        id: trayPopup
        parentWindow: indicatorRoot.parentWindow
        anchorTarget: indicatorRoot
    }
}
