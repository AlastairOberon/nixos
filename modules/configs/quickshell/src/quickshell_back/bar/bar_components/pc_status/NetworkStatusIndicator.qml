import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io 
import "../" 

Row {
    id: netContainer
    spacing: 8

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

    // NEW: Logic to determine if the network is unreachable or struggling (throttled/weak)
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
                let parts = data.split('|');
                if (parts.length < 6) return;
                
                netContainer.isAirplane = (parts[0] === "1");
                netContainer.isWifiOff = (parts[1] === "1");
                netContainer.isEthernet = (parts[2] === "1"); 
                netContainer.signal = parseInt(parts[3]);
                let nowRx = parseInt(parts[4]);
                let nowTx = parseInt(parts[5]);
                
                netContainer.isDisconnected = (!netContainer.isEthernet && netContainer.signal === 0);

                if (netContainer.isDisconnected) {
                    netContainer.downSpeed = "0 KB/s";
                    netContainer.upSpeed = "0 KB/s";
                    netContainer.lastRx = 0;
                    netContainer.lastTx = 0;
                } else {
                    if (netContainer.lastRx > 0) {
                        if (nowRx >= netContainer.lastRx && nowTx >= netContainer.lastTx) {
                            let rxDiff = (nowRx - netContainer.lastRx) / 2048; 
                            let txDiff = (nowTx - netContainer.lastTx) / 2048;
                            
                            netContainer.downSpeed = netContainer.formatSpeed(rxDiff);
                            netContainer.upSpeed = netContainer.formatSpeed(txDiff);
                        } else {
                            netContainer.downSpeed = "0 KB/s";
                            netContainer.upSpeed = "0 KB/s";
                        }
                    }
                    netContainer.lastRx = nowRx;
                    netContainer.lastTx = nowTx;
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
    
    // 1. The Dynamic Icon
    Text {
        anchors.verticalCenter: parent.verticalCenter
        
        text: {
            if (isAirplane && isWifiOff) return "󰀝"; 
            if (isEthernet) return "󰈀";              
            if (isWifiOff) return "󰤮";                
            if (isDisconnected) return "󰤯";          
            
            return signal > 75 ? "󰤨" : (signal > 50 ? "󰤥" : (signal > 25 ? "󰤢" : "󰤟"));
        }
        
        // Turns red if the connection is failing, otherwise stays the main theme color
        color: netContainer.isConnectionWarning ? Theme.urgent : Theme.main 
        font.pixelSize: 16
        Behavior on color { ColorAnimation { duration: 300 } }
    }

    // 2. The Speed Counters
    Column {
        anchors.verticalCenter: parent.verticalCenter
        
        // Down Speed
        Text { 
            text: "▼ " + netContainer.downSpeed; 
            color: netContainer.isConnectionWarning ? Theme.urgent : "#FFFFFF"; 
            font.pixelSize: 9 
            Behavior on color { ColorAnimation { duration: 300 } }
        }
        
        // Up Speed
        Text { 
            text: "▲ " + netContainer.upSpeed; 
            color: netContainer.isConnectionWarning ? Theme.urgent : "#FFFFFF"; 
            font.pixelSize: 9 
            Behavior on color { ColorAnimation { duration: 300 } }
        }
    }
}
