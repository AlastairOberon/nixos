import QtQuick
import Quickshell
import Quickshell.Io
import "../../" 
import "../"

Row {
    id: btIndicatorRoot
    spacing: 6
    
    property string btState: "OFF"
    property int connectedCount: 0
    
    Process {
        id: btPoller
        command: ["bash", "-c", "
            # 1. Check if completely disabled via Airplane Mode / rfkill
            if command -v rfkill >/dev/null 2>&1; then
                blocked=$(rfkill list bluetooth 2>/dev/null | grep -iE 'soft blocked: yes|hard blocked: yes' | wc -l)
                if [ \"$blocked\" -gt 0 ]; then
                    echo \"BLOCKED\"
                    exit 0
                fi
            fi
            
            # 2. Check if manually powered off via bluetoothctl
            power_state=$(bluetoothctl show 2>/dev/null | grep 'Powered: yes' >/dev/null && echo 'ON' || echo 'OFF')
            if [ \"$power_state\" = \"OFF\" ]; then
                echo \"OFF\"
                exit 0
            fi
            
            # 3. Count currently connected devices
            dev_count=$(bluetoothctl devices Connected 2>/dev/null | grep -c '^Device')
            echo \"ON|$dev_count\"
        "]
        
        stdout: SplitParser {
            onRead: function(data) {
                let parts = data.trim().split('|');
                btIndicatorRoot.btState = parts[0];
                
                if (parts.length > 1) {
                    btIndicatorRoot.connectedCount = parseInt(parts[1]) || 0;
                } else {
                    btIndicatorRoot.connectedCount = 0;
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: btPoller.running = true
        triggeredOnStart: true
    }

    Text {
        id: iconText
        anchors.verticalCenter: parent.verticalCenter
        text: {
            if (btIndicatorRoot.btState === "BLOCKED") return "󰀜"; // Airplane Mode Icon
            if (btIndicatorRoot.btState === "OFF") return "󰂲";     // Bluetooth Off Icon
            if (btIndicatorRoot.connectedCount > 0) return "󰂱";    // Bluetooth Connected Icon
            return "󰂯";                                          // Bluetooth On (Idle)
        }
        color: {
            if (btIndicatorRoot.btState === "BLOCKED" || btIndicatorRoot.btState === "OFF") return Theme.inactive;
            if (btIndicatorRoot.connectedCount > 0) return Theme.main; // Highlights green when devices are active!
            return Theme.text;
        }
        font.pixelSize: 16
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Text {
        id: valText
        anchors.verticalCenter: parent.verticalCenter
        text: {
            if (btIndicatorRoot.btState === "BLOCKED") return "Disabled";
            if (btIndicatorRoot.btState === "OFF") return "Off";
            return btIndicatorRoot.connectedCount.toString();
        }
        color: {
            if (btIndicatorRoot.btState === "BLOCKED" || btIndicatorRoot.btState === "OFF") return Theme.inactive;
            return Theme.text;
        }
        font.pixelSize: 13
        font.bold: true
        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
