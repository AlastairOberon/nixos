import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io 

import "../../../theme" 

Item {
    id: netRoot
    
    // Allows the Bar's RowLayout to size this component correctly
    Layout.preferredWidth: contentLayout.implicitWidth
    Layout.fillHeight: true

    // Internal state properties
    property bool isAirplane: false
    property bool isWifiOff: false
    property bool isEthernet: false
    property int signal: 0
    property bool isDisconnected: true
    property string downSpeed: "0 KB/s"
    property string upSpeed: "0 KB/s"
    property real lastRx: 0
    property real lastTx: 0

    // Logic to determine if the network is unreachable or struggling (throttled/weak)
    property bool isConnectionWarning: isDisconnected || isAirplane || isWifiOff || (!isEthernet && signal <= 25)

    function formatSpeed(kbps) {
        if (kbps >= 1048576) {
            return (kbps / 1048576).toFixed(2) + " GB/s";
        } else if (kbps >= 1024) {
            return (kbps / 1024).toFixed(1) + " MB/s";
        } else {
            return Math.round(kbps) + " KB/s";
        }
    }

    Process {
        id: netStats
        command: ["bash", "-c", "
            AIR=$(rfkill list all | grep -c 'Soft blocked: yes'); [ \"$AIR\" -ge 2 ] && echo 1 || echo 0;
            WIFI_OFF=$(rfkill list wifi | grep -qi 'soft blocked: yes' && echo 1 || echo 0);
            ETH=$(cat /sys/class/net/e*/operstate 2>/dev/null | grep -qi 'up' && echo 1 || echo 0);
            SIG=$(nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | awk -F: '/^\\*/ {print $2}'); [ -z \"$SIG\" ] && SIG=0;
            RX=$(cat /sys/class/net/[ew]*/statistics/rx_bytes 2>/dev/null | awk '{s+=$1} END {print s}');
            TX=$(cat /sys/class/net/[ew]*/statistics/tx_bytes 2>/dev/null | awk '{s+=$1} END {print s}');
            echo \"$AIR|$WIFI_OFF|$ETH|$SIG|$RX|$TX\"
        "]
        
        stdout: SplitParser {
            onRead: function(data) {
                let parts = data.trim().split('|');
                if (parts.length < 6) return;
                
                netRoot.isAirplane = (parts[0] === "1");
                netRoot.isWifiOff = (parts[1] === "1");
                netRoot.isEthernet = (parts[2] === "1"); 
                netRoot.signal = parseInt(parts[3]);
                let nowRx = parseInt(parts[4]);
                let nowTx = parseInt(parts[5]);
                
                netRoot.isDisconnected = (!netRoot.isEthernet && netRoot.signal === 0);

                if (netRoot.isDisconnected) {
                    netRoot.downSpeed = "0 KB/s";
                    netRoot.upSpeed = "0 KB/s";
                    netRoot.lastRx = 0;
                    netRoot.lastTx = 0;
                } else {
                    if (netRoot.lastRx > 0) {
                        if (nowRx >= netRoot.lastRx && nowTx >= netRoot.lastTx) {
                            let rxDiff = (nowRx - netRoot.lastRx) / 2048; 
                            let txDiff = (nowTx - netRoot.lastTx) / 2048;
                            
                            netRoot.downSpeed = netRoot.formatSpeed(rxDiff);
                            netRoot.upSpeed = netRoot.formatSpeed(txDiff);
                        } else {
                            netRoot.downSpeed = "0 KB/s";
                            netRoot.upSpeed = "0 KB/s";
                        }
                    }
                    netRoot.lastRx = nowRx;
                    netRoot.lastTx = nowTx;
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: netStats.running = true
    }

    Component.onCompleted: netStats.running = true

    // ==========================================
    // THE UI EXPORT
    // ==========================================
    
    RowLayout {
        id: contentLayout
        anchors.right: parent.right 
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        // 1. The Dynamic Icon
        Text {
            id: netIcon
            text: {
                if (netRoot.isAirplane && netRoot.isWifiOff) return "󰀝"; 
                if (netRoot.isEthernet) return "󰈀";              
                if (netRoot.isWifiOff) return "󰤮";                
                if (netRoot.isDisconnected) return "󰤯";          
                
                return netRoot.signal > 75 ? "󰤨" : (netRoot.signal > 50 ? "󰤥" : (netRoot.signal > 25 ? "󰤢" : "󰤟"));
            }
            
            font.family: Theme.fontIcon    
            font.pixelSize: 18
            
            // Icon stays Theme.text by default
            color: netRoot.isConnectionWarning ? Theme.urgent : (netMouseArea.containsMouse ? Theme.main : Theme.text)
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // 2. The Speed Counters
        ColumnLayout {
            spacing: 0
            
            // Down Speed
            Text { 
                text: "▼ " + netRoot.downSpeed
                
                font.family: Theme.fontMain    
                font.pixelSize: 10
                font.bold: true
                
                // <--- CHANGED: Theme.text replaced with Theme.secondary
                color: netRoot.isConnectionWarning ? Theme.urgent : (netMouseArea.containsMouse ? Theme.main : Theme.secondary)
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            
            // Up Speed
            Text { 
                text: "▲ " + netRoot.upSpeed
                
                font.family: Theme.fontMain    
                font.pixelSize: 10
                font.bold: true
                
                // <--- CHANGED: Theme.text replaced with Theme.secondary
                color: netRoot.isConnectionWarning ? Theme.urgent : (netMouseArea.containsMouse ? Theme.main : Theme.secondary)
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
    }

    // 3. Hover Effect
    MouseArea {
        id: netMouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
