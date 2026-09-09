import QtQuick
import Quickshell
import Quickshell.Io
import "../../" 
import "../"

Row {
    id: brightIndicatorRoot
    spacing: 6
    
    property int brightnessValue: 100
    
    Process {
        id: brightPoller
        command: ["bash", "-c", "brightnessctl -m | awk -F, '{print $4}' | tr -d '%'"]
        stdout: SplitParser {
            onRead: function(data) {
                let val = parseInt(data.trim());
                if (!isNaN(val)) {
                    brightIndicatorRoot.brightnessValue = val;
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: brightPoller.running = true
        triggeredOnStart: true
    }

    // --- 1. THE DYNAMIC ICON ---
    Text {
        id: iconText
        anchors.verticalCenter: parent.verticalCenter
        text: {
            if (brightIndicatorRoot.brightnessValue > 70) return "󰃠";
            if (brightIndicatorRoot.brightnessValue > 30) return "󰃟";
            if (brightIndicatorRoot.brightnessValue > 0) return "󰃞";
            return "󰃭"; // Off
        }
        
        // THE FIX: Swapped Theme.text to Theme.main!
        color: brightIndicatorRoot.brightnessValue === 0 ? Theme.inactive : Theme.main
        font.pixelSize: 18
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // --- 2. THE PERCENTAGE TEXT ---
    Text {
        id: valText
        anchors.verticalCenter: parent.verticalCenter
        text: brightIndicatorRoot.brightnessValue + "%"
        
        color: brightIndicatorRoot.brightnessValue === 0 ? Theme.inactive : Theme.text
        font.pixelSize: 13
        font.bold: true
        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
