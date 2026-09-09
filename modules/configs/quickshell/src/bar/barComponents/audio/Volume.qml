import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io 

import "../../../theme" 

Item {
    id: audioRoot
    
    Layout.preferredWidth: contentLayout.implicitWidth
    Layout.fillHeight: true

    property int volume: 0
    property bool isMuted: false
    property bool isBluetooth: false
    property bool isHeadset: false
    property int btBattery: 0

    Process { 
        id: toggleMuteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"] 
    }

    // Upgraded script to query BlueZ directly for the battery!
    Process {
        id: audioStats
        command: ["bash", "-c", "
            # 1. Get Volume and Mute state
            VOL_STR=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
            VOL=$(echo \"$VOL_STR\" | awk '{print int($2 * 100)}')
            MUTED=$(echo \"$VOL_STR\" | grep -q 'MUTED' && echo 1 || echo 0)
            
            # 2. Grab device metadata
            INSPECT=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null)
            INSPECT_LOWER=$(echo \"$INSPECT\" | tr '[:upper:]' '[:lower:]')
            
            # 3. Check for bluetooth/headphone profiles
            IS_BT=$(echo \"$INSPECT_LOWER\" | grep -qE 'bluez|bluetooth' && echo 1 || echo 0)
            IS_HS=$(echo \"$INSPECT_LOWER\" | grep -qE 'headset|headphone|earbud|airpod|buds|a2dp' && echo 1 || echo 0)
            
            BT_BAT=0
            if [ \"$IS_BT\" = \"1\" ]; then
                # 4. Extract the exact MAC address of the active audio device
                MAC=$(echo \"$INSPECT\" | grep -oE 'bluez_(card|output)\\.[A-Za-z0-9_]+' | head -n 1 | cut -d'.' -f2 | tr '_' ':')
                
                if [ -n \"$MAC\" ]; then
                    # 5. Query bluetoothctl directly (This is what Overskride uses!)
                    BAT=$(bluetoothctl info \"$MAC\" 2>/dev/null | awk '/Battery Percentage:/ {gsub(/[^0-9]/, \"\", $NF); print $NF}')
                    [ -n \"$BAT\" ] && BT_BAT=$BAT
                fi
                
                # Absolute fallback just in case
                if [ -z \"$BT_BAT\" ] || [ \"$BT_BAT\" = \"0\" ]; then
                    BAT=$(upower -e 2>/dev/null | grep -iE 'headset|headphone|bluez|dev_' | head -n 1 | xargs -I {} upower -i {} 2>/dev/null | awk '/percentage:/ {print $2}' | tr -d '%')
                    [ -n \"$BAT\" ] && BT_BAT=$BAT
                fi
            fi
            
            echo \"$VOL|$MUTED|$IS_BT|$IS_HS|$BT_BAT\"
        "]
        
        stdout: SplitParser {
            onRead: function(data) {
                let parts = data.trim().split('|');
                if (parts.length < 5) return;
                
                audioRoot.volume = parseInt(parts[0]) || 0;
                audioRoot.isMuted = (parts[1] === "1");
                audioRoot.isBluetooth = (parts[2] === "1");
                audioRoot.isHeadset = (parts[3] === "1");
                audioRoot.btBattery = parseInt(parts[4]) || 0;
            }
        }
    }

    Timer {
        interval: 1000 
        running: true
        repeat: true
        onTriggered: audioStats.running = true
    }

    Component.onCompleted: audioStats.running = true

    // ==========================================
    // THE UI EXPORT
    // ==========================================
    
    RowLayout {
        id: contentLayout
        anchors.right: parent.right 
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        // 1. The Main Icon
        Text {
            id: volIcon
            text: {
                if (audioRoot.isMuted) return "󰖁";          
                if (audioRoot.isHeadset) return "󰋋";        
                if (audioRoot.volume === 0) return "󰕿";     
                if (audioRoot.volume < 50) return "󰖀";      
                return "󰕾";                                 
            }
            
            font.family: Theme.fontIcon    
            font.pixelSize: 18
            Layout.alignment: Qt.AlignVCenter
            
            color: audioRoot.isMuted ? Theme.urgent : (volMouseArea.containsMouse ? Theme.main : Theme.text)
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // 2. The Text Stack 
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 0 

            Text {
                text: audioRoot.volume + "%"
                
                font.family: Theme.fontMain    
                font.pixelSize: 10
                font.bold: true
                Layout.alignment: Qt.AlignHCenter 
                
                color: audioRoot.isMuted ? Theme.urgent : (volMouseArea.containsMouse ? Theme.main : Theme.text)
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            // Bluetooth Badge
            RowLayout {
                visible: audioRoot.isBluetooth
                spacing: 0
                Layout.alignment: Qt.AlignHCenter 
                
                // Bluetooth Icon
                Text {
                    text: "󰂯" 
                    font.family: Theme.fontIcon
                    font.pixelSize: 10 
                    color: Theme.secondary
                }
                
                // Dynamic Battery Icon
                Text {
                    text: {
                        if (audioRoot.btBattery <= 0) return "󰂎"; 
                        if (audioRoot.btBattery <= 20) return "󰁻";
                        if (audioRoot.btBattery <= 40) return "󰁽";
                        if (audioRoot.btBattery <= 60) return "󰁿";
                        if (audioRoot.btBattery <= 80) return "󰂁";
                        return "󰁹"; 
                    }
                    font.family: Theme.fontIcon
                    font.pixelSize: 10 
                    color: Theme.secondary
                }
                
                // Battery Percentage Text
                Text {
                    text: audioRoot.btBattery > 0 ? audioRoot.btBattery + "%" : "--%"
                    font.family: Theme.fontMain
                    font.pixelSize: 10
                    font.bold: true
                    color: Theme.secondary
                }
            }
        }
    }

    MouseArea {
        id: volMouseArea
        anchors.fill: parent
        hoverEnabled: true
        
        onClicked: {
            toggleMuteProc.running = true;
            audioStats.running = true; 
        }
    }
}
