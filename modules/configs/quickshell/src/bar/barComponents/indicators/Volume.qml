import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io 
import Quickshell.Services.Pipewire

import "../../../theme" 

Item {
    id: audioRoot
    
    Layout.preferredWidth: contentLayout.implicitWidth + 16
    Layout.preferredHeight: 30
    Layout.fillHeight: true

    property bool isActive: typeof myLauncher !== "undefined" && 
                            myLauncher.window && 
                            myLauncher.window.visible && 
                            myLauncher.window.currentTabIndex === 5

    property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [ audioRoot.sink ] }

    property int volume: sink?.audio ? Math.round(sink.audio.volume * 100) : 0
    property bool isMuted: sink?.audio ? sink.audio.muted : false
    property bool isBluetooth: false
    property bool isHeadset: false
    property int btBattery: 0

    function toggleMute() {
        if (sink?.audio) {
            sink.audio.muted = !sink.audio.muted;
        } else {
            toggleMuteProc.running = true;
        }
    }

    Process { 
        id: toggleMuteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"] 
    }

    Process {
        id: adjustVolProc
    }

    // Bluetooth and device profile inspector
    Process {
        id: audioStats
        command: ["bash", "-c", "
            INSPECT=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null)
            INSPECT_LOWER=$(echo \"$INSPECT\" | tr '[:upper:]' '[:lower:]')
            
            IS_BT=$(echo \"$INSPECT_LOWER\" | grep -qE 'bluez|bluetooth' && echo 1 || echo 0)
            IS_HS=$(echo \"$INSPECT_LOWER\" | grep -qE 'headset|headphone|earbud|airpod|buds|a2dp' && echo 1 || echo 0)
            
            BT_BAT=0
            if [ \"$IS_BT\" = \"1\" ]; then
                MAC=$(echo \"$INSPECT\" | grep -oE 'bluez_(card|output)\\.[A-Za-z0-9_]+' | head -n 1 | cut -d'.' -f2 | tr '_' ':')
                if [ -n \"$MAC\" ]; then
                    BAT=$(bluetoothctl info \"$MAC\" 2>/dev/null | awk '/Battery Percentage:/ {gsub(/[^0-9]/, \"\", $NF); print $NF}')
                    [ -n \"$BAT\" ] && BT_BAT=$BAT
                fi
                if [ -z \"$BT_BAT\" ] || [ \"$BT_BAT\" = \"0\" ]; then
                    BAT=$(upower -e 2>/dev/null | grep -iE 'headset|headphone|bluez|dev_' | head -n 1 | xargs -I {} upower -i {} 2>/dev/null | awk '/percentage:/ {print $2}' | tr -d '%')
                    [ -n \"$BAT\" ] && BT_BAT=$BAT
                fi
            fi
            
            echo \"$IS_BT|$IS_HS|$BT_BAT\"
        "]
        
        stdout: SplitParser {
            onRead: function(data) {
                let parts = data.trim().split('|');
                if (parts.length < 3) return;
                
                audioRoot.isBluetooth = (parts[0] === "1");
                audioRoot.isHeadset = (parts[1] === "1");
                audioRoot.btBattery = parseInt(parts[2]) || 0;
            }
        }
    }

    Timer {
        interval: 5000 
        running: true
        repeat: true
        onTriggered: audioStats.running = true
    }

    Component.onCompleted: audioStats.running = true

    // The Highlight Pill Background
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: audioRoot.isActive ? Theme.secondary : (volMouseArea.containsMouse ? Theme.urgent : "transparent")
        
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }

    // ==========================================
    // THE UI EXPORT
    // ==========================================
    
    RowLayout {
        id: contentLayout
        anchors.centerIn: parent
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
            
            color: (audioRoot.isActive || volMouseArea.containsMouse) ? Theme.base : (audioRoot.isMuted ? Theme.urgent : Theme.text)
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
                
                color: (audioRoot.isActive || volMouseArea.containsMouse) ? Theme.base : (audioRoot.isMuted ? Theme.urgent : Theme.text)
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
                    color: (audioRoot.isActive || volMouseArea.containsMouse) ? Theme.base : Theme.secondary
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
                    color: (audioRoot.isActive || volMouseArea.containsMouse) ? Theme.base : Theme.secondary
                }
                
                // Battery Percentage Text
                Text {
                    text: audioRoot.btBattery > 0 ? audioRoot.btBattery + "%" : "--%"
                    font.family: Theme.fontMain
                    font.pixelSize: 10
                    font.bold: true
                    color: (audioRoot.isActive || volMouseArea.containsMouse) ? Theme.base : Theme.secondary
                }
            }
        }
    }

    MouseArea {
        id: volMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                audioRoot.toggleMute();
                audioStats.running = true;
            } else {
                if (typeof myLauncher !== "undefined" && myLauncher.window) {
                    if (audioRoot.isActive) {
                        myLauncher.window.visible = false;
                    } else {
                        myLauncher.window.visible = true;
                        myLauncher.window.currentTabIndex = 5;
                    }
                }
            }
        }

        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                adjustVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"];
            } else {
                adjustVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"];
            }
            adjustVolProc.running = true;
        }
    }
}
