import QtQuick
import Quickshell
import Quickshell.Io
import "../../" 
import "../"

Row {
    id: pwrIndicatorRoot
    spacing: 6
    
    property string pwrType: "BATTERY"
    property int pwrCapacity: 0
    property string pwrStatus: "Unknown"
    property bool isPluggedIn: false
    
    // Failsafe: Snap the icon back to 100% visibility immediately when unplugged
    onIsPluggedInChanged: {
        if (!isPluggedIn) {
            iconText.opacity = 1.0; 
        }
    }
    
    Process {
        id: pwrPoller
        command: ["bash", "-c", "
            # 1. Check if the physical AC adapter is providing power
            ac_online=0
            for ac in /sys/class/power_supply/AC* /sys/class/power_supply/ADP* /sys/class/power_supply/macsmc-ac*; do
                if [ -f \"$ac/online\" ] && [ \"$(cat $ac/online 2>/dev/null)\" = \"1\" ]; then
                    ac_online=1
                    break
                fi
            done
            
            # 2. Check the Battery Capacity
            bat_path=$(ls -1d /sys/class/power_supply/BAT* 2>/dev/null | head -n 1)
            
            if [ -z \"$bat_path\" ]; then
                echo \"DESKTOP|100|AC|1\"
            else
                capacity=$(cat \"$bat_path/capacity\" 2>/dev/null || echo \"0\")
                status=$(cat \"$bat_path/status\" 2>/dev/null || echo \"Unknown\")
                
                echo \"BATTERY|$capacity|$status|$ac_online\"
            fi
        "]
        
        stdout: SplitParser {
            onRead: function(data) {
                let parts = data.trim().split('|');
                if (parts.length >= 4) {
                    pwrIndicatorRoot.pwrType = parts[0];
                    pwrIndicatorRoot.pwrCapacity = parseInt(parts[1]) || 0;
                    pwrIndicatorRoot.pwrStatus = parts[2].trim();
                    pwrIndicatorRoot.isPluggedIn = (parts[3] === "1");
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: pwrPoller.running = true
        triggeredOnStart: true
    }

    function getIcon() {
        if (pwrType === "DESKTOP") return "󱐋"; 
        if (isPluggedIn) return "󰂄"; 
        
        let c = pwrCapacity;
        if (c > 90) return "󰁹";
        if (c > 80) return "󰂂";
        if (c > 70) return "󰂁";
        if (c > 60) return "󰂀";
        if (c > 50) return "󰁿";
        if (c > 40) return "󰁾";
        if (c > 30) return "󰁽";
        if (c > 20) return "󰁼";
        if (c > 10) return "󰁻";
        return "󰂎"; 
    }

    // --- 1. THE PULSING ICON ---
    Text {
        id: iconText
        anchors.verticalCenter: parent.verticalCenter
        text: pwrIndicatorRoot.getIcon()
        color: Theme.main 
        font.pixelSize: 18
        opacity: 1.0
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // The gentle breathing animation
    SequentialAnimation {
        running: pwrIndicatorRoot.isPluggedIn
        loops: Animation.Infinite
        NumberAnimation { target: iconText; property: "opacity"; to: 0.4; duration: 1200; easing.type: Easing.InOutQuad }
        NumberAnimation { target: iconText; property: "opacity"; to: 1.0; duration: 1200; easing.type: Easing.InOutQuad }
    }

    // --- 2. THE TEXT ---
    Text {
        id: valText
        anchors.verticalCenter: parent.verticalCenter
        visible: pwrIndicatorRoot.pwrType === "BATTERY" 
        
        text: pwrIndicatorRoot.pwrCapacity + "%"
        
        color: {
            // Uses your secondary color when unplugged and dropping below 20%
            if (pwrIndicatorRoot.pwrType === "BATTERY" && pwrIndicatorRoot.pwrCapacity <= 20 && !pwrIndicatorRoot.isPluggedIn) {
                return Theme.secondaryBase; 
            }
            return Theme.text;
        }
        
        font.pixelSize: 13
        font.bold: true
        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
