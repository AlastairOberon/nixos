import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io 

import "../../../../theme" 
import "../../../../theme/components" 

Item {
    id: networkRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    
    // --- REAL STATE PROPERTIES ---
    property bool isWifiScanning: true
    property bool isAirplaneMode: false
    property bool isShowingQr: false
    property string qrCodeSource: "" 
    
    property string activeNetwork: ""
    property string activeType: ""
    property string activeDevice: "" 
    property string activeIpLocal: ""
    property string activeIpPublic: "Hidden for Speed"
    property int activeSignal: 0
    property string activeFreq: ""
    property string activeChannel: ""
    property string activeSecurity: ""
    
    property string expandedNetworkName: ""
    property bool isConnected: activeNetwork !== ""

    // --- PING GRAPH PROPERTIES ---
    property int currentPing: 0
    property int maxPing: 0
    property int minPing: 0
    property var pingHistory: [] 

    ListModel { id: availableNetworks }
    ListModel { id: listeningPortsModel }

    // ==========================================
    // BACKEND EXECUTION PROCESSES
    // ==========================================
    
    Process {
        id: networkAction
        onExited: running = false 
    }

    Process {
        id: portAction
        onExited: {
            running = false;
            fetchPortsStats.running = true; 
        }
    }

    Process {
        id: generateQrProcess
        stdout: StdioCollector {
            onStreamFinished: {
                networkRoot.qrCodeSource = "file:///tmp/wifi_qr.svg?" + Date.now();
                networkRoot.isShowingQr = true;
            }
        }
    }

    Process {
        id: fetchPortsStats
        command: [
            "sh", "-c", 
            "ss -tunlp 2>/dev/null | awk 'NR>1 { split($5, a, \":\"); port=a[length(a)]; match($7, /pid=([0-9]+)/); pid=substr($7, RSTART+4, RLENGTH-4); match($7, /\"([^\"]+)\"/); proc=substr($7, RSTART+1, RLENGTH-2); if (pid && proc && !seen[port]++) { if (c++) printf \",\"; printf \"{\\\"proto\\\":\\\"%s\\\",\\\"port\\\":%s,\\\"process\\\":\\\"%s\\\",\\\"pid\\\":%s}\", $1, port, proc, pid } } BEGIN { printf \"[\" } END { printf \"]\" }'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text.trim() === "") return;
                    let parsed = JSON.parse(this.text);
                    listeningPortsModel.clear();
                    
                    parsed.sort((a, b) => a.port - b.port);
                    
                    for (let i = 0; i < parsed.length; i++) {
                        listeningPortsModel.append(parsed[i]);
                    }
                } catch (e) {
                    console.log("Ports JSON Parse Error: " + e.message);
                }
            }
        }
    }

    Process {
        id: fetchNetworkStats
        command: [
            "sh", "-c", 
            "export LC_ALL=C; " +
            "ping_res=$(ping -c 1 -W 1 1.1.1.1 2>/dev/null | awk -F'/' 'END{ print (/^rtt/ ? $5 : \"0\") }' | cut -d. -f1); " +
            "active_line=$(nmcli -t -f NAME,TYPE,DEVICE c show --active | grep -Ev 'loopback|tun|virbr|docker' | head -n 1); " +
            "a_name=$(echo \"$active_line\" | awk -F':' '{print $1}'); " +
            "a_type=$(echo \"$active_line\" | awk -F':' '{print $2}'); " +
            "a_dev=$(echo \"$active_line\" | awk -F':' '{print $3}'); " +
            "a_ip=$(ip -4 addr show dev \"$a_dev\" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -n 1); " +
            "w_state=$(nmcli -t -f WIFI radio); " +
            "wifi_en=\"false\"; [ \"$w_state\" = \"enabled\" ] && wifi_en=\"true\"; " +
            "wifi_json=\"[]\"; " +
            "if [ \"$w_state\" = \"enabled\" ]; then " +
                "wifi_json=$(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY,FREQ,CHAN dev wifi 2>/dev/null | awk -F':' 'BEGIN { printf \"[\" } { inuse=($1==\"*\")?\"true\":\"false\"; ssid=$2; sig=$3; sec=$4; freq=$5; chan=$6; if(ssid!=\"\") { is_sec=(sec==\"\" || sec==\"--\" || sec==\"Open\")?\"false\":\"true\"; sec_disp=(sec==\"\")?\"Open\":sec; if(c++) printf \",\"; printf \"{\\\"inUse\\\":%s, \\\"name\\\":\\\"%s\\\", \\\"strength\\\":%s, \\\"security\\\":\\\"%s\\\", \\\"isSecured\\\":%s, \\\"freq\\\":\\\"%s\\\", \\\"channel\\\":\\\"%s\\\"}\", inuse, ssid, (sig==\"\"?0:sig), sec_disp, is_sec, freq, chan } } END { printf \"]\" }'); " +
            "fi; " +
            "printf '{\"ping\":%s, \"activeName\":\"%s\", \"activeType\":\"%s\", \"activeDevice\":\"%s\", \"activeIp\":\"%s\", \"wifiEnabled\":%s, \"networks\":%s}' \"${ping_res:-0}\" \"${a_name}\" \"${a_type}\" \"${a_dev}\" \"${a_ip}\" \"${wifi_en}\" \"${wifi_json:-[]}\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text.trim() === "") return;
                    let parsed = JSON.parse(this.text);
                    
                    networkRoot.activeNetwork = parsed.activeName;
                    networkRoot.activeType = parsed.activeType;
                    networkRoot.activeDevice = parsed.activeDevice;
                    networkRoot.activeIpLocal = parsed.activeIp;
                    
                    if (parsed.ping > 0) {
                        networkRoot.currentPing = parsed.ping;
                        let newHist = networkRoot.pingHistory.slice();
                        newHist.push(parsed.ping);
                        if (newHist.length > 30) newHist.shift();
                        networkRoot.pingHistory = newHist;
                        networkRoot.maxPing = Math.max.apply(null, newHist);
                        networkRoot.minPing = Math.min.apply(null, newHist);
                        if (pingCanvas) pingCanvas.requestPaint();
                    } else if (!networkRoot.isConnected) {
                        networkRoot.currentPing = 0;
                        networkRoot.pingHistory = [];
                        if (pingCanvas) pingCanvas.requestPaint();
                    }

                    if (networkRoot.isWifiScanning) {
                        let foundActiveParams = false;
                        
                        let uniqueNets = {};
                        for (let i = 0; i < parsed.networks.length; i++) {
                            let net = parsed.networks[i];
                            let existing = uniqueNets[net.name];
                            
                            if (!existing) {
                                uniqueNets[net.name] = net;
                            } else {
                                if (net.inUse || (!existing.inUse && parseInt(net.strength) > parseInt(existing.strength))) {
                                    uniqueNets[net.name] = net;
                                }
                            }
                        }
                        
                        let sortedNets = Object.values(uniqueNets);
                        sortedNets.sort((a, b) => parseInt(b.strength) - parseInt(a.strength));

                        if (networkRoot.expandedNetworkName !== "" && availableNetworks.count > 0) {
                            for (let i = 0; i < availableNetworks.count; i++) {
                                let oldName = availableNetworks.get(i).name;
                                let freshData = uniqueNets[oldName];
                                if (freshData) {
                                    availableNetworks.setProperty(i, "strength", freshData.strength);
                                    availableNetworks.setProperty(i, "inUse", freshData.inUse);
                                }
                            }
                        } else {
                            availableNetworks.clear();
                            for (let i = 0; i < sortedNets.length; i++) {
                                availableNetworks.append(sortedNets[i]);
                            }
                        }

                        for (let i = 0; i < sortedNets.length; i++) {
                            let net = sortedNets[i];
                            if (net.inUse || net.name === networkRoot.activeNetwork) {
                                networkRoot.activeSignal = net.strength;
                                networkRoot.activeFreq = net.freq;
                                networkRoot.activeChannel = net.channel;
                                networkRoot.activeSecurity = net.security;
                                foundActiveParams = true;
                            }
                        }
                        
                        if (!foundActiveParams) {
                            networkRoot.activeSignal = 0;
                            networkRoot.activeFreq = "";
                            networkRoot.activeChannel = "";
                        }
                    }
                } catch (e) {
                    console.log("Network JSON Parse Error: " + e.message);
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 2500 
        repeat: true
        running: networkRoot.visible
        onTriggered: {
            fetchNetworkStats.running = true;
            fetchPortsStats.running = true; 
        }
    }

    onVisibleChanged: {
        if (visible) {
            fetchNetworkStats.running = true;
            fetchPortsStats.running = true;
        }
    }

    // ==========================================
    // UI LAYOUT
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        spacing: Metrics.spacingLarge
        anchors.topMargin: Metrics.spacingLarge
        anchors.bottomMargin: Metrics.spacingLarge

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Metrics.spacingLarge
            Layout.rightMargin: Metrics.spacingLarge
            spacing: 8

            Text {
                text: "Network Connectivity"
                color: Theme.main
                font.family: Theme.fontMain
                font.pixelSize: 16
                font.weight: Font.Bold
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: Metrics.spacingLarge
            Layout.rightMargin: Metrics.spacingLarge
            spacing: Metrics.spacingLarge * 3

            // ==========================================
            // LEFT COLUMN: ACTIVE CONNECTION 
            // ==========================================
            ColumnLayout {
                // THE FIX 1: Prevent recursive resize by referencing the absolute parent width
                Layout.preferredWidth: networkRoot.width * 0.33
                Layout.fillHeight: true
                spacing: Metrics.spacingLarge

                Text {
                    text: "Current Status"
                    color: Theme.text
                    font.family: Theme.fontMain
                    font.pixelSize: 16 
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                }

                Item { Layout.fillHeight: true } 

                Text {
                    text: networkRoot.isAirplaneMode ? "\uf072" : (!networkRoot.isConnected ? "\uf12a" : (networkRoot.activeType.includes("ethernet") ? "\uf796" : "\uf1eb"))
                    color: networkRoot.isAirplaneMode ? Theme.urgent : (networkRoot.isConnected ? Theme.main : Theme.secondary)
                    font.family: Theme.fontIcon
                    font.pixelSize: 80
                    Layout.alignment: Qt.AlignHCenter
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    Text {
                        text: networkRoot.isAirplaneMode ? "Airplane Mode" : (networkRoot.isConnected ? networkRoot.activeNetwork : "Disconnected")
                        color: Theme.text
                        font.family: Theme.fontMain
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignHCenter
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4
                        visible: !networkRoot.isAirplaneMode && networkRoot.isConnected
                        
                        Text {
                            visible: networkRoot.activeType.includes("wireless")
                            text: "Signal: " + networkRoot.activeSignal + "%  •  " + networkRoot.activeSecurity
                            color: Theme.main
                            font.family: Theme.fontMain
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            visible: networkRoot.activeType.includes("wireless") && networkRoot.activeFreq !== ""
                            text: "Freq: " + networkRoot.activeFreq + "  •  Ch: " + networkRoot.activeChannel
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                            font.family: Theme.fontMain
                            font.pixelSize: 13
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: "Local IP: " + networkRoot.activeIpLocal
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.8)
                            font.family: Theme.fontMain
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            Layout.topMargin: 8
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                Item { Layout.fillHeight: true } 

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Metrics.spacingLarge
                    visible: networkRoot.isConnected && !networkRoot.isAirplaneMode && networkRoot.activeType.includes("wireless")
                    
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 140
                        height: 36
                        radius: 18
                        color: shareMouse.containsMouse ? Qt.darker(Theme.base, 1.2) : "transparent"
                        border.color: Theme.bridge
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "\uf1e0"; color: Theme.main; font.family: Theme.fontIcon; font.pixelSize: 14 }
                            Text { 
                                text: networkRoot.isShowingQr ? "Hide QR Code" : "Share Wi-Fi"
                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.9)
                                font.family: Theme.fontMain
                                font.pixelSize: 13
                                font.weight: Font.Bold 
                            }
                        }
                        
                        MouseArea { 
                            id: shareMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (networkRoot.isShowingQr) {
                                    networkRoot.isShowingQr = false;
                                } else {
                                    let mColor = Theme.main.toString();
                                    let cmd = "ssid='" + networkRoot.activeNetwork + "'; " +
                                              "pass=$(nmcli -s -g 802-11-wireless-security.psk connection show \"$ssid\" 2>/dev/null); " +
                                              "qrencode -t SVG -o /tmp/wifi_qr.svg \"WIFI:S:$ssid;T:WPA;P:$pass;;\"; " +
                                              "sed -i 's/#000000/" + mColor + "/gi; s/#FFFFFF/none/gi' /tmp/wifi_qr.svg; " +
                                              "echo 'Success'";
                                    generateQrProcess.command = ["sh", "-c", cmd];
                                    generateQrProcess.running = true;
                                }
                            }
                        }
                    }
                    
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        visible: networkRoot.isShowingQr
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 160
                        color: "transparent" 
                        radius: Metrics.radiusBase
                        
                        Image {
                            anchors.centerIn: parent
                            width: 160
                            height: 160
                            source: networkRoot.qrCodeSource
                            fillMode: Image.PreserveAspectFit
                            cache: false 
                            
                            Text {
                                anchors.centerIn: parent
                                text: "\uf029" 
                                color: Theme.main
                                font.family: Theme.fontIcon
                                font.pixelSize: 120
                                visible: parent.status === Image.Error || networkRoot.qrCodeSource === ""
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    Layout.topMargin: Metrics.spacingBase
                    radius: Metrics.radiusBase
                    color: Qt.darker(Theme.base, 1.2)
                    border.color: networkRoot.isConnected ? Theme.main : Theme.secondary
                    border.width: 1
                    visible: !networkRoot.isAirplaneMode && networkRoot.isConnected
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Ping (1.1.1.1)"
                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                                font.family: Theme.fontMain
                                font.pixelSize: 14
                                Layout.fillWidth: true
                            }
                            Text {
                                text: networkRoot.isConnected ? networkRoot.currentPing + " ms" : "--"
                                color: networkRoot.isConnected ? Theme.base : Theme.text
                                font.family: Theme.fontMain
                                font.pixelSize: 14
                                font.weight: Font.Bold
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 8

                            ColumnLayout {
                                Layout.fillHeight: true
                                Layout.preferredWidth: 24
                                visible: networkRoot.pingHistory.length > 0
                                
                                Text {
                                    text: networkRoot.maxPing
                                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                                    font.family: Theme.fontMain
                                    font.pixelSize: 11
                                    Layout.alignment: Qt.AlignTop | Qt.AlignRight
                                }
                                Item { Layout.fillHeight: true }
                                Text {
                                    text: networkRoot.minPing
                                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                                    font.family: Theme.fontMain
                                    font.pixelSize: 11
                                    Layout.alignment: Qt.AlignBottom | Qt.AlignRight
                                }
                            }

                            Canvas {
                                id: pingCanvas
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);

                                    if (!networkRoot.isConnected || networkRoot.pingHistory.length < 2) return;
                                    
                                    ctx.beginPath();
                                    ctx.lineWidth = 2;
                                    ctx.strokeStyle = Theme.main.toString();
                                    ctx.lineJoin = "round";

                                    let minP = networkRoot.minPing;
                                    let maxP = networkRoot.maxPing;
                                    let range = maxP - minP;
                                    if (range === 0) range = 1; 
                                    
                                    let stepX = width / (networkRoot.pingHistory.length - 1);
                                    
                                    for (let i = 0; i < networkRoot.pingHistory.length; i++) {
                                        let x = i * stepX;
                                        let y = height - (((networkRoot.pingHistory[i] - minP) / range) * height);
                                        let paddedY = 2 + (y * ((height - 4) / height));

                                        if (i === 0) {
                                            ctx.moveTo(x, paddedY);
                                        } else {
                                            ctx.lineTo(x, paddedY);
                                        }
                                    }
                                    ctx.stroke();
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true } 

                ThemeButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45
                    color: networkRoot.isConnected ? Theme.urgent : Theme.main
                    border.width: 0
                    visible: !networkRoot.isAirplaneMode
                    
                    Text {
                        anchors.centerIn: parent
                        text: networkRoot.isConnected ? "Disconnect" : "Refresh Network"
                        color: Theme.base
                        font.family: Theme.fontMain
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }
                    
                    onClicked: {
                        if (networkRoot.isConnected && networkRoot.activeDevice !== "") {
                            networkAction.command = ["sh", "-c", "nmcli device disconnect " + networkRoot.activeDevice];
                            networkAction.running = true;
                            fetchNetworkStats.running = true; 
                        } else {
                            fetchNetworkStats.running = true;
                        }
                    }
                }
            }

            // ==========================================
            // RIGHT COLUMN: 50/50 SPLIT (NETWORKS & PORTS)
            // ==========================================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Metrics.spacingLarge

                // ------------------------------------------
                // TOP HALF: AVAILABLE NETWORKS
                // ------------------------------------------
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Metrics.spacingLarge

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Metrics.spacingLarge

                        ThemeButton {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40 
                            color: networkRoot.isWifiScanning && !networkRoot.isAirplaneMode ? Theme.secondary : Theme.bridge
                            border.width: 0
                            
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 12
                                Text { text: "\uf002"; color: networkRoot.isWifiScanning && !networkRoot.isAirplaneMode ? Theme.base : Theme.text; font.family: Theme.fontIcon; font.pixelSize: 16 }
                                Text { text: networkRoot.isWifiScanning ? "Scanning: ON" : "Scanning: OFF"; color: networkRoot.isWifiScanning && !networkRoot.isAirplaneMode ? Theme.base : Theme.text; font.family: Theme.fontMain; font.pixelSize: 14; font.weight: Font.Bold }
                            }
                            
                            onClicked: {
                                if (!networkRoot.isAirplaneMode) {
                                    networkRoot.isWifiScanning = !networkRoot.isWifiScanning;
                                    if (networkRoot.isWifiScanning) fetchNetworkStats.running = true;
                                }
                            }
                        }

                        ThemeButton {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            color: networkRoot.isAirplaneMode ? Theme.urgent : Theme.bridge
                            border.width: 0
                            
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 12
                                Text { text: "\uf072"; color: networkRoot.isAirplaneMode ? Theme.base : Theme.text; font.family: Theme.fontIcon; font.pixelSize: 16 }
                                Text { text: "Airplane Mode"; color: networkRoot.isAirplaneMode ? Theme.base : Theme.text; font.family: Theme.fontMain; font.pixelSize: 14; font.weight: Font.Bold }
                            }
                            
                            onClicked: {
                                networkRoot.isAirplaneMode = !networkRoot.isAirplaneMode;
                                if (networkRoot.isAirplaneMode) {
                                    networkRoot.isWifiScanning = false;
                                    networkRoot.expandedNetworkName = "";
                                    networkAction.command = ["sh", "-c", "nmcli radio wifi off"];
                                    networkAction.running = true;
                                } else {
                                    networkAction.command = ["sh", "-c", "nmcli radio wifi on"];
                                    networkAction.running = true;
                                }
                                fetchNetworkStats.running = true;
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "transparent"
                        
                        Text {
                            visible: networkRoot.isAirplaneMode || !networkRoot.isWifiScanning || availableNetworks.count === 0
                            text: {
                                if (networkRoot.isAirplaneMode) return "Radios disabled by Airplane Mode.";
                                if (!networkRoot.isWifiScanning) return "Scanning paused. Enable scanning to see nearby networks.";
                                return "Scanning for networks...";
                            }
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                            font.family: Theme.fontMain
                            font.pixelSize: 14
                            anchors.centerIn: parent
                        }

                        ScrollView {
                            id: netScroll // THE FIX 2: Added ID
                            anchors.fill: parent
                            visible: !networkRoot.isAirplaneMode && networkRoot.isWifiScanning
                            clip: true
                            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                            ColumnLayout {
                                width: netScroll.width // THE FIX 3: Bound directly to scroll width
                                spacing: 4 

                                Repeater {
                                    model: availableNetworks
                                    delegate: Rectangle {
                                        id: delegateRoot
                                        Layout.fillWidth: true
                                        
                                        Layout.preferredHeight: contentCol.implicitHeight + 24
                                        Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                        
                                        property bool isActive: model.inUse || networkRoot.activeNetwork === model.name
                                        property bool isExpanded: networkRoot.expandedNetworkName === model.name
                                        
                                        color: isActive ? Qt.rgba(Theme.main.r, Theme.main.g, Theme.main.b, 0.15) : (isExpanded ? Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.2) : "transparent")
                                        border.width: (hoverHandler.hovered || isActive || isExpanded) ? 1 : 0
                                        border.color: isActive ? Theme.main : ((hoverHandler.hovered || isExpanded) ? Theme.bridge : "transparent")
                                        Behavior on border.color { ColorAnimation { duration: 150 } }
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        
                                        radius: Metrics.radiusBase
                                        clip: true
                                        
                                        HoverHandler { id: hoverHandler }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (networkRoot.expandedNetworkName === model.name) {
                                                    networkRoot.expandedNetworkName = "";
                                                } else {
                                                    networkRoot.expandedNetworkName = model.name;
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            id: contentCol
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: 12
                                            spacing: 12
                                            
                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 16

                                                Text {
                                                    text: model.isSecured ? "\uf023" : "\uf09c" 
                                                    color: delegateRoot.isActive ? Theme.main : (model.isSecured ? Theme.text : Theme.urgent)
                                                    font.family: Theme.fontIcon
                                                    font.pixelSize: 18
                                                    Layout.alignment: Qt.AlignVCenter
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignVCenter
                                                    spacing: 2
                                                    
                                                    Text {
                                                        text: model.name
                                                        color: delegateRoot.isActive ? Theme.main : Theme.text
                                                        font.family: Theme.fontMain
                                                        font.pixelSize: 14
                                                        font.weight: Font.Bold
                                                    }
                                                    Text {
                                                        text: model.security + " • Signal: " + model.strength + "%"
                                                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                                                        font.family: Theme.fontMain
                                                        font.pixelSize: 12
                                                    }
                                                }
                                                
                                                Text {
                                                    text: delegateRoot.isExpanded ? "\uf106" : "\uf107" 
                                                    color: delegateRoot.isActive ? Theme.main : Theme.text
                                                    font.family: Theme.fontIcon
                                                    font.pixelSize: 20
                                                    Layout.alignment: Qt.AlignVCenter
                                                }
                                            }
                                            
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                visible: delegateRoot.isExpanded
                                                opacity: delegateRoot.isExpanded ? 1 : 0
                                                Behavior on opacity { NumberAnimation { duration: 250 } }
                                                spacing: 12
                                                
                                                Text {
                                                    text: "Freq: " + model.freq + "  •  Channel: " + model.channel
                                                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                                                    font.family: Theme.fontMain
                                                    font.pixelSize: 13
                                                }
                                                
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    visible: !delegateRoot.isActive
                                                    spacing: Metrics.spacingLarge
                                                    
                                                    ThemeButton {
                                                        Layout.preferredWidth: 90
                                                        Layout.preferredHeight: 32
                                                        color: Theme.main
                                                        border.width: 0
                                                        
                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: "Connect"
                                                            color: Theme.base
                                                            font.family: Theme.fontMain
                                                            font.pixelSize: 13
                                                            font.weight: Font.Bold
                                                        }
                                                        
                                                        onClicked: {
                                                            let cmd = "nmcli device wifi connect '" + model.name + "'";
                                                            if (model.isSecured && pwField.text !== "") {
                                                                cmd += " password '" + pwField.text + "'";
                                                            }
                                                            networkAction.command = ["sh", "-c", cmd];
                                                            networkAction.running = true;
                                                            networkRoot.expandedNetworkName = ""; 
                                                            fetchNetworkStats.running = true; 
                                                        }
                                                    }
                                                    
                                                    TextField {
                                                        id: pwField
                                                        Layout.fillWidth: true
                                                        Layout.preferredHeight: 32
                                                        visible: model.isSecured
                                                        placeholderText: "Enter Password..."
                                                        
                                                        echoMode: TextInput.Password
                                                        passwordCharacter: "•"
                                                        
                                                        font.family: Theme.fontMain
                                                        font.pixelSize: 13
                                                        color: Theme.text
                                                        
                                                        background: Rectangle {
                                                            color: Qt.darker(Theme.base, 1.2)
                                                            radius: 16
                                                            border.width: 1
                                                            border.color: parent.activeFocus ? Theme.main : "transparent"
                                                        }
                                                        
                                                        MouseArea {
                                                            anchors.fill: parent
                                                            acceptedButtons: Qt.NoButton
                                                            cursorShape: Qt.IBeamCursor
                                                        }
                                                    }
                                                }
                                                
                                                ThemeButton {
                                                    Layout.preferredWidth: 90
                                                    Layout.preferredHeight: 32
                                                    visible: !model.isSecured && !delegateRoot.isActive
                                                    color: Theme.main
                                                    border.width: 0
                                                    
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "Connect"
                                                        color: Theme.base
                                                        font.family: Theme.fontMain
                                                        font.pixelSize: 13
                                                        font.weight: Font.Bold
                                                    }
                                                    
                                                    onClicked: {
                                                        networkRoot.activeNetwork = model.name;
                                                        networkRoot.expandedNetworkName = ""; 
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

                // ------------------------------------------
                // DIVIDER LINE
                // ------------------------------------------
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.bridge
                    opacity: 0.4
                }

                // ------------------------------------------
                // BOTTOM HALF: LISTENING PORTS
                // ------------------------------------------
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Metrics.spacingLarge

                    Text {
                        text: "Active Listening Ports"
                        color: Theme.text
                        font.family: Theme.fontMain
                        font.pixelSize: 16 
                        font.weight: Font.Bold
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "transparent"
                        
                        Text {
                            visible: listeningPortsModel.count === 0
                            text: "No exposed listening ports found."
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                            font.family: Theme.fontMain
                            font.pixelSize: 14
                            anchors.centerIn: parent
                        }

                        ScrollView {
                            id: portsScroll // THE FIX 2: Added ID
                            anchors.fill: parent
                            clip: true
                            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                            ColumnLayout {
                                width: portsScroll.width // THE FIX 3: Bound directly to scroll width
                                spacing: 4 

                                Repeater {
                                    model: listeningPortsModel
                                    delegate: Rectangle {
                                        id: portDelegate
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 46 
                                        radius: Metrics.radiusBase
                                        color: "transparent"
                                        border.width: portHover.hovered ? 1 : 0
                                        border.color: portHover.hovered ? Theme.main : "transparent"
                                        Behavior on border.color { ColorAnimation { duration: 150 } }
                                        HoverHandler { id: portHover }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 12

                                            Text {
                                                text: "\uf233" 
                                                color: Theme.main
                                                font.family: Theme.fontIcon
                                                font.pixelSize: 14 
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 0 
                                                
                                                Text {
                                                    text: "Port " + model.port
                                                    color: Theme.text
                                                    font.family: Theme.fontMain
                                                    font.pixelSize: 14 
                                                    font.weight: Font.Bold
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }
                                                
                                                Text {
                                                    text: model.process + " (" + model.proto + ")"
                                                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                                                    font.family: Theme.fontMain
                                                    font.pixelSize: 12 
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Text {
                                                text: "\uf00d" 
                                                color: killHover.containsMouse ? Theme.urgent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
                                                font.family: Theme.fontIcon
                                                font.pixelSize: 14
                                                
                                                Behavior on color { ColorAnimation { duration: 150 } }

                                                MouseArea {
                                                    id: killHover
                                                    anchors.fill: parent
                                                    anchors.margins: -8 
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        portAction.running = false;
                                                        portAction.command = ["bash", "-c", "kill -9 " + model.pid];
                                                        portAction.running = true;
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
        }
    }
}
