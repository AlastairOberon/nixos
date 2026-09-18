import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "../../../theme"

Item {
    id: batteryRoot
    
    Layout.preferredWidth: contentLayout.implicitWidth + 16
    Layout.preferredHeight: 30
    Layout.fillHeight: true

    property bool isActive: typeof myLauncher !== "undefined" && 
                            myLauncher.window && 
                            myLauncher.window.visible && 
                            myLauncher.window.currentTabIndex === 15

    property int capacity: 100
    property string status: "Unknown"
    property bool isCharging: status === "Charging"
    property bool isAcOnline: false

    function getBatteryIcon() {
        if (batteryRoot.isCharging) {
            if (batteryRoot.capacity >= 90) return "󰂅";
            if (batteryRoot.capacity >= 80) return "󰂊";
            if (batteryRoot.capacity >= 60) return "󰂉";
            if (batteryRoot.capacity >= 40) return "󰂈";
            if (batteryRoot.capacity >= 20) return "󰂇";
            return "󰂆";
        }
        if (batteryRoot.capacity >= 90) return "󰁹";
        if (batteryRoot.capacity >= 80) return "󰂂";
        if (batteryRoot.capacity >= 70) return "󰂁";
        if (batteryRoot.capacity >= 60) return "󰂀";
        if (batteryRoot.capacity >= 50) return "󰁾";
        if (batteryRoot.capacity >= 40) return "󰁽";
        if (batteryRoot.capacity >= 30) return "󰁼";
        if (batteryRoot.capacity >= 20) return "󰁻";
        return "󰁺";
    }

    Process {
        id: batProcess
        command: [
            "bash", "-c",
            "BAT='/sys/class/power_supply/BAT0'; " +
            "AC='/sys/class/power_supply/ADP0'; " +
            "CAP=$(cat $BAT/capacity 2>/dev/null || echo 100); " +
            "STAT=$(cat $BAT/status 2>/dev/null || echo 'Unknown'); " +
            "ACO=$(cat $AC/online 2>/dev/null || echo 0); " +
            "echo \"$CAP|$STAT|$ACO\""
        ]

        stdout: SplitParser {
            onRead: function(data) {
                let parts = data.trim().split('|');
                if (parts.length < 3) return;
                let c = parseInt(parts[0]);
                if (!isNaN(c)) batteryRoot.capacity = c;
                batteryRoot.status = parts[1].trim();
                batteryRoot.isAcOnline = (parts[2].trim() === "1");
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: batProcess.running = true
    }

    Component.onCompleted: batProcess.running = true

    // The Highlight Pill Background
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: batteryRoot.isActive ? Theme.secondary : (batteryMouseArea.containsMouse ? Theme.urgent : "transparent")
        
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }

    // The UI Layout
    RowLayout {
        id: contentLayout
        anchors.centerIn: parent
        spacing: 6

        Text {
            id: batIcon
            text: batteryRoot.getBatteryIcon()
            
            font.family: Theme.fontIcon
            font.pixelSize: 18
            Layout.alignment: Qt.AlignVCenter
            
            color: (batteryRoot.isActive || batteryMouseArea.containsMouse) 
                   ? Theme.base 
                   : (batteryRoot.capacity <= 20 && !batteryRoot.isCharging ? Theme.urgent : Theme.text)
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            text: batteryRoot.capacity + "%"
            
            font.family: Theme.fontMain
            font.pixelSize: 12
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
            
            color: (batteryRoot.isActive || batteryMouseArea.containsMouse) 
                   ? Theme.base 
                   : (batteryRoot.capacity <= 20 && !batteryRoot.isCharging ? Theme.urgent : Theme.text)
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: batteryMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            if (typeof myLauncher !== "undefined" && myLauncher.window) {
                if (batteryRoot.isActive) {
                    myLauncher.window.visible = false;
                } else {
                    myLauncher.window.visible = true;
                    myLauncher.window.currentTabIndex = 15;
                }
            }
        }
    }
}
