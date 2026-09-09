import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../" 

BlueprintPopup {
    id: netPopup
    
    // --- 1. CONFIGURE THE BLUEPRINT ---
    popupWidth: 560 
    popupHeight: 440 
    isTopBar: true
    
    isSubMenu: true
    barOverlap: -120 
    
    property var networkData: null 
    property var networkList: []
    
    // Properties for the Bar Indicator Toggle
    property bool showInBar: true
    signal toggleShowInBar()
    
    // Active UI States
    property bool wifiEnabled: true
    property bool airplaneMode: false

    // --- 2. HOOK INTO BLUEPRINT SIGNALS ---
    onAboutToOpen: {
        checkRadioProcess.running = true;
        scanProcess.running = true;
        wifiList.expandedSsid = ""; 
    }

    Timer {
        id: refreshTimer
        interval: 2000 
        repeat: true
        running: netPopup.visible && wifiList.expandedSsid === ""
        onTriggered: {
            checkRadioProcess.running = true;
            scanProcess.running = true;
        }
    }

    // --- LOGIC: Check Radio States ---
    Process {
        id: checkRadioProcess
        command: [
            "bash", 
            "-c", 
            "echo $(nmcli radio wifi); rfkill list | grep -q 'Soft blocked: no' && echo 'disabled' || echo 'enabled'"
        ]
        stdout: SplitParser {
            onRead: function(data) {
                let lines = data.trim().split('\n');
                if (lines.length >= 2) {
                    netPopup.wifiEnabled = (lines[0] === "enabled");
                    netPopup.airplaneMode = (lines[1] === "enabled");
                }
            }
        }
    }

    // --- LOGIC: Toggle Wi-Fi ---
    Process {
        id: toggleWifiProcess
        onExited: checkRadioProcess.running = true 
    }

    // --- LOGIC: Toggle Airplane Mode ---
    Process {
        id: toggleAirplaneProcess
        onExited: checkRadioProcess.running = true
    }

    // --- LOGIC: Disconnect Active Wi-Fi ---
    Process {
        id: disconnectProcess
        property string targetSsid: ""
        command: [
            "bash", 
            "-c", 
            "nmcli connection down id \"" + targetSsid + "\" || nmcli device disconnect $(nmcli -t -f DEVICE,TYPE dev | grep wifi | cut -d: -f1 | head -n1)"
        ]
        onExited: {
            checkRadioProcess.running = true;
            scanProcess.running = true;
        }
    }

    // --- LOGIC: Scan Wi-Fi ---
    Process {
        id: scanProcess
        command: ["bash", "-c", "nmcli -t -f IN-USE,SIGNAL,FREQ,RATE,CHAN,SECURITY,SSID dev wifi list | tr '\n' '|'"]
        stdout: SplitParser {
            onRead: function(data) {
                let lines = data.split('|');
                let tempMap = {};

                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (line.length === 0) continue;

                    let parts = line.split(':');
                    if (parts.length >= 7) {
                        let activeFlag = parts.shift();
                        let sig = parseInt(parts.shift());
                        let freq = parts.shift();
                        let rate = parts.shift();
                        let chan = parts.shift();
                        let sec = parts.shift();
                        
                        let ssid = parts.join(':').trim();
                        ssid = ssid.replace(/\\:/g, ':'); 
                        let active = (activeFlag === '*');

                        if (ssid.length > 0) {
                            if (!tempMap[ssid]) {
                                tempMap[ssid] = { 
                                    "ssid": ssid, "signal": sig, "active": active, 
                                    "freq": freq, "rate": rate, "chan": chan, "sec": sec 
                                };
                            } else {
                                if (sig > tempMap[ssid].signal) {
                                    tempMap[ssid].signal = sig;
                                    tempMap[ssid].freq = freq;
                                    tempMap[ssid].rate = rate;
                                    tempMap[ssid].chan = chan;
                                    tempMap[ssid].sec = sec;
                                }
                                if (active) tempMap[ssid].active = true;
                            }
                        }
                    }
                }

                let finalArray = [];
                for (let key in tempMap) { finalArray.push(tempMap[key]); }
                finalArray.sort(function(a, b) { return b.signal - a.signal; });
                netPopup.networkList = finalArray;
            }
        }
    }

    Process {
        id: termConnectProcess
        property string targetSsid: ""
        command: [
            "ghostty", 
            "-e", 
            "bash", 
            "-c", 
            "echo 'Connecting to: " + targetSsid + "'; nmcli --ask dev wifi connect \"" + targetSsid + "\"; echo; read -p 'Press Enter to close...'"
        ]
    }

    // ==========================================
    // --- 3. UI CONTENT ---
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10
        
        // --- LIVE SPEED METRICS HEADER ---
        RowLayout {
            Layout.fillWidth: true
            visible: networkData !== null && !networkData.isDisconnected
            
            Column {
                Layout.alignment: Qt.AlignLeft
                Text { text: "Download"; color: Theme.inactive; font.pixelSize: 10 }
                Text { text: networkData ? "▼ " + networkData.downSpeed : "0 KB/s"; color: Theme.text; font.pixelSize: 14; font.bold: true }
            }
            Item { Layout.fillWidth: true } // Spacer
            Column {
                Layout.alignment: Qt.AlignRight
                Text { text: "Upload"; color: Theme.inactive; font.pixelSize: 10; anchors.right: parent.right }
                Text { text: networkData ? "▲ " + networkData.upSpeed : "0 KB/s"; color: Theme.text; font.pixelSize: 14; font.bold: true; anchors.right: parent.right }
            }
        }

        // Horizontal Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.secondaryBase
            visible: networkData !== null && !networkData.isDisconnected
        }

        // --- NEW: FULL WIDTH VISIBILITY PILL TOGGLE ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: height / 2 
            color: netPopup.showInBar ? Theme.main : Theme.secondaryBase
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                // Dynamically changes icon and text based on state!
                text: netPopup.showInBar ? "󰈈 Shown in Bar" : "󰈉 Hidden from Bar"
                font.bold: true
                font.pixelSize: 14
                color: netPopup.showInBar ? Theme.base : Theme.main
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: showInBarMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: netPopup.toggleShowInBar()
            }
            
            Rectangle { 
                anchors.fill: parent 
                radius: height / 2 
                color: "#FFFFFF" 
                opacity: showInBarMouse.containsMouse ? 0.15 : 0 
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        // --- TOP TOGGLE BAR (Wi-Fi & Airplane) ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            Layout.minimumHeight: 40 
            Layout.maximumHeight: 40
            spacing: 15 

            // --- WI-FI TOGGLE PILL ---
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: height / 2 
                color: netPopup.wifiEnabled ? Theme.main : Theme.secondaryBase
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰤨 Wi-Fi"
                    font.bold: true
                    font.pixelSize: 14
                    color: netPopup.wifiEnabled ? Theme.base : Theme.main
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: wifiMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let targetState = !netPopup.wifiEnabled;
                        netPopup.wifiEnabled = targetState;
                        
                        toggleWifiProcess.running = false;
                        toggleWifiProcess.command = ["nmcli", "radio", "wifi", targetState ? "on" : "off"];
                        toggleWifiProcess.running = true;
                    }
                }
                
                Rectangle { 
                    anchors.fill: parent 
                    radius: height / 2 
                    color: "#FFFFFF" 
                    opacity: wifiMouse.containsMouse ? 0.15 : 0 
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            // --- AIRPLANE MODE TOGGLE PILL ---
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: height / 2 
                color: netPopup.airplaneMode ? Theme.main : Theme.secondaryBase
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰀝 Airplane"
                    font.bold: true
                    font.pixelSize: 14
                    color: netPopup.airplaneMode ? Theme.base : Theme.main
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: airplaneMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let targetState = !netPopup.airplaneMode;
                        netPopup.airplaneMode = targetState;
                        
                        let cmd = "";
                        if (targetState) {
                            cmd = "nmcli radio wifi > /tmp/.qs_wifi_state; (bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off) > /tmp/.qs_bt_state; rfkill block all";
                        } else {
                            cmd = "rfkill unblock all; sleep 0.5; nmcli radio wifi $(cat /tmp/.qs_wifi_state 2>/dev/null || echo on); bluetoothctl power $(cat /tmp/.qs_bt_state 2>/dev/null || echo on)";
                        }

                        toggleAirplaneProcess.running = false;
                        toggleAirplaneProcess.command = ["bash", "-c", cmd];
                        toggleAirplaneProcess.running = true;
                    }
                }
                
                Rectangle { 
                    anchors.fill: parent 
                    radius: height / 2 
                    color: "#FFFFFF" 
                    opacity: airplaneMouse.containsMouse ? 0.15 : 0 
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }

        // Horizontal Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.secondaryBase
        }

        // --- NETWORK LIST ---
        Text { 
            text: netPopup.wifiEnabled ? "Available Networks" : "Wi-Fi is Disabled"
            color: Theme.text
            font.bold: true 
        }

        ListView {
            id: wifiList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: netPopup.networkList
            clip: true
            spacing: 8 
            
            property string expandedSsid: ""
            
            delegate: Rectangle {
                id: delegateRect
                width: wifiList.width
                
                property bool isExpanded: wifiList.expandedSsid === modelData.ssid
                
                height: isExpanded ? 140 : 42
                
                color: modelData.active ? Theme.main : "transparent"
                radius: 8
                clip: true
                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                Column {
                    anchors.fill: parent
                    anchors.margins: 8 
                    spacing: 8
                    
                    // 1. HEADER ROW
                    Item {
                        width: parent.width
                        height: 26
                        
                        Text { 
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 50
                            text: modelData.ssid
                            color: modelData.active ? Theme.base : Theme.text
                            font.pixelSize: 15 
                            font.bold: modelData.active
                            elide: Text.ElideRight
                        }
                        
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.signal + "%"
                            color: modelData.active ? Theme.base : Theme.inactive
                            font.pixelSize: 13 
                            font.bold: true
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (wifiList.expandedSsid === modelData.ssid) {
                                    wifiList.expandedSsid = ""; 
                                } else {
                                    wifiList.expandedSsid = modelData.ssid; 
                                }
                            }
                        }
                    }
                    
                    // 2. EXPANDED DETAILS
                    Item {
                        width: parent.width
                        height: 90
                        visible: delegateRect.isExpanded
                        opacity: delegateRect.isExpanded ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        
                        Column {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 6
                            
                            Text {
                                text: "Security: " + modelData.sec + "   •   Max Rate: " + modelData.rate
                                color: modelData.active ? Theme.base : Theme.text
                                font.pixelSize: 12
                            }
                            
                            Text {
                                text: "Frequency: " + modelData.freq + " (Ch " + modelData.chan + ")"
                                color: modelData.active ? Theme.base : Theme.text
                                font.pixelSize: 12
                            }
                            
                            Item { width: 1; height: 4 } // Spacer
                            
                            // --- THE CONNECT / DISCONNECT PILL BUTTON ---
                            Rectangle {
                                width: parent.width
                                height: 32 
                                radius: height / 2 
                                
                                color: mouseAreaConnect.containsMouse 
                                    ? (modelData.active ? Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.8) : Qt.lighter(Theme.main, 1.2)) 
                                    : (modelData.active ? Theme.base : Theme.main)
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.active ? "Disconnect" : "Connect"
                                    color: modelData.active ? Theme.urgent : Theme.base
                                    font.bold: true
                                    font.pixelSize: 13
                                }
                                
                                MouseArea {
                                    id: mouseAreaConnect
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.active) {
                                            disconnectProcess.targetSsid = modelData.ssid;
                                            disconnectProcess.running = true;
                                            wifiList.expandedSsid = "";
                                        } else {
                                            termConnectProcess.targetSsid = modelData.ssid;
                                            termConnectProcess.running = true;
                                            netPopup.toggle(); 
                                            wifiList.expandedSsid = "";
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
