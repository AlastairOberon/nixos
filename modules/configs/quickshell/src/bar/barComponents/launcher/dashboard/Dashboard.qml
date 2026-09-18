import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

import "../../../../theme" 
import "../../../../theme/components" 

Item {
    id: dashboardRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    // ==========================================
    // DATA PROPERTIES & BACKEND
    // ==========================================

    // --- 1. SYSTEM DATA ---
    property string sysOs: "Loading..."
    property string sysKernel: "Loading..."
    property string sysUptime: "Loading..."
    property string sysWm: "Loading..."
    property string sysWallpaper: ""

    Process {
        id: sysInfoPoller
        command: [
            "bash", "-c",
            "fastfetch --logo none; echo '---WP---'; hyprctl hyprpaper listactive 2>/dev/null | grep -o '/.*' | head -n 1 | tr -d '\n'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parts = this.text.split("---WP---");
                    let fetchOutput = parts[0].trim().split('\n');
                    let wpOutput = parts.length > 1 ? parts[1].trim() : "";

                    for (let i = 0; i < fetchOutput.length; i++) {
                        let line = fetchOutput[i];
                        if (line.match(/OS\s*➜/)) dashboardRoot.sysOs = line.split("➜")[1].trim();
                        else if (line.match(/Kernel\s*➜/)) dashboardRoot.sysKernel = line.split("➜")[1].trim();
                        else if (line.match(/Uptime\s*➜/)) dashboardRoot.sysUptime = line.split("➜")[1].trim();
                        else if (line.match(/WM\s*➜/)) dashboardRoot.sysWm = line.split("➜")[1].trim();
                    }

                    if (wpOutput !== "") dashboardRoot.sysWallpaper = "file://" + wpOutput;
                } catch(e) {
                    console.log("Fastfetch Parse Error: " + e.message);
                }
            }
        }
    }

    Timer {
        interval: 60000 
        running: dashboardRoot.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: sysInfoPoller.running = true
    }

    // --- 2. CPU & RAM USAGE (ORANGE BOX) ---
    property int cpuUsage: 0
    property int ramUsage: 0

    Process {
        id: cpuRamPoller
        command: [
            "bash", "-c",
            "cpu=$(top -bn1 | grep -i 'cpu(s)' | awk '{print int($2)}'); ram=$(free -m | awk '/^Mem/{print int($3*100/$2)}'); echo \"$cpu|$ram\""
        ]
        stdout: SplitParser {
            onRead: function(data) {
                let parts = data.trim().split('|');
                if (parts.length >= 2) {
                    let c = parseInt(parts[0]);
                    let r = parseInt(parts[1]);
                    if (!isNaN(c)) dashboardRoot.cpuUsage = c;
                    if (!isNaN(r)) dashboardRoot.ramUsage = r;
                }
            }
        }
    }

    Timer {
        interval: 2500
        running: dashboardRoot.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: cpuRamPoller.running = true
    }

    // --- 3. VOLUME & BRIGHTNESS (YELLOW BOX) ---
    property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [ dashboardRoot.sink ] }
    property int volume: sink?.audio ? Math.round(sink.audio.volume * 100) : 0

    property int brightness: 50
    Process {
        id: brightPoller
        command: ["bash", "-c", "brightnessctl i -m 2>/dev/null | awk -F, '{print int($4)}'"]
        stdout: SplitParser {
            onRead: function(data) {
                let val = parseInt(data.trim());
                if (!isNaN(val)) dashboardRoot.brightness = val;
            }
        }
    }

    Timer {
        interval: 2000
        running: dashboardRoot.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: brightPoller.running = true
    }

    Process { id: brightSetProc }

    // --- 4. NETWORK CONNECTIVITY (DARK GREEN BOX) ---
    property string netName: "Disconnected"
    property string netType: ""
    property int netSignal: 0

    Process {
        id: netPoller
        command: [
            "bash", "-c",
            "active_line=$(nmcli -t -f NAME,TYPE,DEVICE c show --active 2>/dev/null | grep -Ev 'loopback|tun|virbr|docker' | head -n 1); " +
            "a_name=$(echo \"$active_line\" | awk -F':' '{print $1}'); " +
            "a_type=$(echo \"$active_line\" | awk -F':' '{print $2}'); " +
            "sig=$(nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | awk -F: '/^\\*/ {print $2}'); " +
            "[ -z \"$sig\" ] && sig=0; " +
            "echo \"$a_name|$a_type|$sig\""
        ]
        stdout: SplitParser {
            onRead: function(data) {
                let parts = data.trim().split('|');
                if (parts.length >= 3) {
                    dashboardRoot.netName = parts[0] || "Disconnected";
                    dashboardRoot.netType = parts[1] || "";
                    let s = parseInt(parts[2]);
                    dashboardRoot.netSignal = isNaN(s) ? 0 : s;
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: dashboardRoot.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: netPoller.running = true
    }

    // --- 5. BATTERY & POWER PROFILE ---
    property int batCapacity: 100
    property string batStatus: "Unknown"
    property bool batAcOnline: false
    property string batProfile: "balanced"

    Process {
        id: dashBatPoller
        command: [
            "bash", "-c",
            "CAP=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 0); " +
            "STAT=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo 'Unknown'); " +
            "AC=$(cat /sys/class/power_supply/ADP0/online 2>/dev/null || echo 0); " +
            "PROF=$(powerprofilesctl get 2>/dev/null || echo 'balanced'); " +
            "echo \"$CAP|$STAT|$AC|$PROF\""
        ]
        stdout: SplitParser {
            onRead: function(data) {
                let parts = data.trim().split('|');
                if (parts.length >= 4) {
                    let c = parseInt(parts[0]);
                    dashboardRoot.batCapacity = isNaN(c) ? 0 : c;
                    dashboardRoot.batStatus = parts[1];
                    dashboardRoot.batAcOnline = (parts[2] === "1");
                    dashboardRoot.batProfile = parts[3];
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: dashboardRoot.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: dashBatPoller.running = true
    }

    // --- 6. OPEN APPLICATIONS / SYSTEM TRAY DATA ---
    property int openAppCount: 0
    property var openAppIcons: []

    Process {
        id: openAppsPoller
        command: [
            "python3",
            "/etc/nixos/modules/configs/quickshell/src/bar/barComponents/launcher/systemTray/tray_scanner.py"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text.trim() === "") return;
                    let res = JSON.parse(this.text);
                    dashboardRoot.openAppCount = res.totalRunning || 0;
                    let icons = [];
                    if (res.items) {
                        for (let i = 0; i < res.items.length; i++) {
                            let item = res.items[i];
                            if (item.statusType === "open" || item.statusType === "background") {
                                if (!icons.includes(item.icon) && icons.length < 4) {
                                    icons.push(item.icon);
                                }
                            }
                        }
                    }
                    dashboardRoot.openAppIcons = icons;
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 3000
        running: dashboardRoot.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: openAppsPoller.running = true
    }

    // --- NAVIGATION & EVENT HELPERS ---
    function navigateToTab(tabIdx) {
        let p = dashboardRoot;
        while (p) {
            if (p.currentTabIndex !== undefined) {
                p.currentTabIndex = tabIdx;
                return;
            }
            p = p.parent;
        }
        if (typeof launcherWindow !== "undefined" && launcherWindow) {
            launcherWindow.currentTabIndex = tabIdx;
        }
    }

    function getUnreadCount() {
        if (typeof launcherWindow !== "undefined" && launcherWindow && launcherWindow.unreadNotificationCount !== undefined) {
            return launcherWindow.unreadNotificationCount;
        }
        return 0;
    }

    onVisibleChanged: {
        if (visible) {
            sysInfoPoller.running = true;
            cpuRamPoller.running = true;
            brightPoller.running = true;
            netPoller.running = true;
            dashBatPoller.running = true;
            openAppsPoller.running = true;
        }
    }

    // ==========================================
    // UI LAYOUT
    // ==========================================
    GridLayout {
        anchors.fill: parent
        anchors.margins: Metrics.spacingLarge
        columns: 6
        rows: 4
        columnSpacing: Metrics.spacingLarge
        rowSpacing: Metrics.spacingLarge

        // ==========================================
        // 1. SYSTEM INFO CARD (Rows 0-1, Cols 0-3)
        // ==========================================
        Rectangle {
            Layout.column: 0
            Layout.row: 0
            Layout.columnSpan: 4
            Layout.rowSpan: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 160 
            Layout.preferredHeight: 90 
            color: Theme.base
            radius: Metrics.radiusBase
            clip: true

            Image {
                id: sysBg
                source: dashboardRoot.sysWallpaper
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                visible: false 
                cache: false
            }

            MultiEffect {
                anchors.fill: parent
                source: sysBg
                blurEnabled: true
                blurMax: 64
                blur: 1.0
                colorizationColor: "#000000"
                colorization: 0.65 
                visible: dashboardRoot.sysWallpaper !== ""
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.darker(Theme.main, 2.5)
                visible: dashboardRoot.sysWallpaper === ""
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: Metrics.spacingLarge * 3
                spacing: Metrics.spacingLarge * 3

                Text {
                    text: "\uf313" 
                    color: "white" 
                    font.family: Theme.fontIcon
                    font.pixelSize: 130 
                    Layout.alignment: Qt.AlignVCenter
                    opacity: 0.95
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 10

                    Text {
                        text: "System Information"
                        color: "white"
                        font.family: Theme.fontMain
                        font.pixelSize: 26
                        font.weight: Font.Bold
                        Layout.bottomMargin: 8
                    }

                    RowLayout {
                        spacing: 16
                        Text { text: "\uf108"; color: "white"; font.family: Theme.fontIcon; font.pixelSize: 16; opacity: 0.7 }
                        Text { text: dashboardRoot.sysOs; color: "white"; font.family: Theme.fontMain; font.pixelSize: 16; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                    
                    RowLayout {
                        spacing: 16
                        Text { text: "\uf013"; color: "white"; font.family: Theme.fontIcon; font.pixelSize: 16; opacity: 0.7 }
                        Text { text: dashboardRoot.sysKernel; color: "white"; font.family: Theme.fontMain; font.pixelSize: 16; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                    }

                    RowLayout {
                        spacing: 16
                        Text { text: "\uf2d0"; color: "white"; font.family: Theme.fontIcon; font.pixelSize: 16; opacity: 0.7 }
                        Text { text: dashboardRoot.sysWm; color: "white"; font.family: Theme.fontMain; font.pixelSize: 16; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                    }

                    RowLayout {
                        spacing: 16
                        Text { text: "\uf017"; color: "white"; font.family: Theme.fontIcon; font.pixelSize: 16; opacity: 0.7 }
                        Text { text: dashboardRoot.sysUptime; color: "white"; font.family: Theme.fontMain; font.pixelSize: 16; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                }
            }
        }

        // ==========================================
        // 2. TALL ORANGE BOX: CPU & RAM CIRCULAR BARS (Rows 0-1, Col 4)
        // ==========================================
        Rectangle {
            id: orangeBox
            Layout.column: 4
            Layout.row: 0
            Layout.columnSpan: 1
            Layout.rowSpan: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            Layout.preferredHeight: 90
            color: "transparent"
            radius: Metrics.radiusBase
            border.width: 1
            border.color: orangeHover.containsMouse ? Theme.secondary : Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.4)
            Behavior on border.color { ColorAnimation { duration: 150 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Metrics.spacingBase
                spacing: 4

                Item { Layout.fillHeight: true }

                // --- CPU CIRCULAR GAUGE ---
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    Text {
                        text: "CPU"
                        color: Theme.text
                        font.family: Theme.fontMain
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Item {
                        width: 82
                        height: 82
                        Layout.alignment: Qt.AlignHCenter

                        property int pct: dashboardRoot.cpuUsage
                        property color gColor: pct >= 80 ? Theme.urgent : Theme.main
                        property real animVal: pct / 100.0

                        Behavior on animVal { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                        onAnimValChanged: cpuCanvas.requestPaint()

                        Canvas {
                            id: cpuCanvas
                            anchors.fill: parent
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.lineWidth = 7;
                                ctx.lineCap = "round";
                                var x = width / 2;
                                var y = height / 2;
                                var r = width / 2 - 5;

                                ctx.beginPath();
                                ctx.arc(x, y, r, 0, 2 * Math.PI);
                                ctx.strokeStyle = Qt.darker(Theme.base, 1.2).toString();
                                ctx.stroke();

                                if (parent.animVal > 0) {
                                    ctx.beginPath();
                                    ctx.arc(x, y, r, -Math.PI / 2, -Math.PI / 2 + (2 * Math.PI * parent.animVal));
                                    ctx.strokeStyle = parent.gColor.toString();
                                    ctx.stroke();
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: parent.pct + "%"
                            color: Theme.text
                            font.family: Theme.fontMain
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // --- RAM CIRCULAR GAUGE ---
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    Text {
                        text: "RAM"
                        color: Theme.text
                        font.family: Theme.fontMain
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Item {
                        width: 82
                        height: 82
                        Layout.alignment: Qt.AlignHCenter

                        property int pct: dashboardRoot.ramUsage
                        property color gColor: pct >= 80 ? Theme.urgent : Theme.secondary
                        property real animVal: pct / 100.0

                        Behavior on animVal { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                        onAnimValChanged: ramCanvas.requestPaint()

                        Canvas {
                            id: ramCanvas
                            anchors.fill: parent
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.lineWidth = 7;
                                ctx.lineCap = "round";
                                var x = width / 2;
                                var y = height / 2;
                                var r = width / 2 - 5;

                                ctx.beginPath();
                                ctx.arc(x, y, r, 0, 2 * Math.PI);
                                ctx.strokeStyle = Qt.darker(Theme.base, 1.2).toString();
                                ctx.stroke();

                                if (parent.animVal > 0) {
                                    ctx.beginPath();
                                    ctx.arc(x, y, r, -Math.PI / 2, -Math.PI / 2 + (2 * Math.PI * parent.animVal));
                                    ctx.strokeStyle = parent.gColor.toString();
                                    ctx.stroke();
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: parent.pct + "%"
                            color: Theme.text
                            font.family: Theme.fontMain
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            MouseArea {
                id: orangeHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: dashboardRoot.navigateToTab(13) // SystemStats tab
            }
        }

        // ==========================================
        // 3. TALL YELLOW BOX: VOLUME & BRIGHTNESS SLIDERS (Rows 0-1, Col 5)
        // ==========================================
        Rectangle {
            id: yellowBox
            Layout.column: 5
            Layout.row: 0
            Layout.columnSpan: 1
            Layout.rowSpan: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            Layout.preferredHeight: 90
            color: "transparent"
            radius: Metrics.radiusBase
            border.width: 1
            border.color: yellowHover.containsMouse ? Theme.secondary : Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.4)
            Behavior on border.color { ColorAnimation { duration: 150 } }

            MouseArea {
                id: yellowHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Metrics.spacingBase
                spacing: 6

                Text {
                    text: "Quick Controls"
                    color: Theme.main
                    font.family: Theme.fontMain
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    // --- VERTICAL VOLUME SLIDER ---
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6
                        Layout.alignment: Qt.AlignHCenter

                        Text {
                            text: "\uf028"
                            color: Theme.main
                            font.family: Theme.fontIcon
                            font.pixelSize: 16
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: Math.round(volSlider.value) + "%"
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.8)
                            font.family: Theme.fontMain
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Slider {
                            id: volSlider
                            orientation: Qt.Vertical
                            Layout.fillHeight: true
                            Layout.preferredWidth: 26
                            Layout.alignment: Qt.AlignHCenter
                            from: 0
                            to: 100
                            value: dashboardRoot.volume
                            onMoved: {
                                if (dashboardRoot.sink?.audio) {
                                    dashboardRoot.sink.audio.volume = value / 100.0;
                                }
                            }

                            background: Rectangle {
                                x: volSlider.leftPadding + (volSlider.availableWidth - width) / 2
                                y: volSlider.topPadding
                                width: 22
                                height: volSlider.availableHeight
                                radius: 11
                                color: Qt.rgba(1, 1, 1, 0.15)

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: Math.max(0, Math.min(parent.height, (volSlider.value / 100.0) * parent.height))
                                    radius: 11
                                    color: Theme.main
                                }
                            }

                            handle: Item {}
                        }

                        Text {
                            text: "Volume"
                            color: Theme.text
                            font.family: Theme.fontMain
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    // --- VERTICAL BRIGHTNESS SLIDER ---
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6
                        Layout.alignment: Qt.AlignHCenter

                        Text {
                            text: "\uf185"
                            color: Theme.secondary
                            font.family: Theme.fontIcon
                            font.pixelSize: 16
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: Math.round(brightSlider.value) + "%"
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.8)
                            font.family: Theme.fontMain
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Slider {
                            id: brightSlider
                            orientation: Qt.Vertical
                            Layout.fillHeight: true
                            Layout.preferredWidth: 26
                            Layout.alignment: Qt.AlignHCenter
                            from: 5
                            to: 100
                            value: dashboardRoot.brightness
                            onMoved: {
                                let val = Math.round(value);
                                brightSetProc.command = ["brightnessctl", "set", val + "%"];
                                brightSetProc.running = true;
                            }
                            onPressedChanged: {
                                if (!pressed) {
                                    let val = Math.round(value);
                                    brightSetProc.command = ["brightnessctl", "set", val + "%"];
                                    brightSetProc.running = true;
                                }
                            }

                            background: Rectangle {
                                x: brightSlider.leftPadding + (brightSlider.availableWidth - width) / 2
                                y: brightSlider.topPadding
                                width: 22
                                height: brightSlider.availableHeight
                                radius: 11
                                color: Qt.rgba(1, 1, 1, 0.15)

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: Math.max(0, Math.min(parent.height, ((brightSlider.value - brightSlider.from) / (brightSlider.to - brightSlider.from)) * parent.height))
                                    radius: 11
                                    color: Theme.secondary
                                }
                            }

                            handle: Item {}
                        }

                        Text {
                            text: "Bright"
                            color: Theme.text
                            font.family: Theme.fontMain
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }

        // ==========================================
        // 4. WEATHER WIDGET (Rows 2-3, Cols 0-1)
        // ==========================================
        Rectangle {
            id: weatherWidget
            Layout.column: 0
            Layout.row: 2
            Layout.columnSpan: 2
            Layout.rowSpan: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 80
            Layout.preferredHeight: 80
            color: "transparent"
            radius: Metrics.radiusBase
            border.width: 1
            border.color: weatherHover.containsMouse ? Theme.secondary : Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.4)
            Behavior on border.color { ColorAnimation { duration: 150 } }
            clip: true

            property int currentTemp: 0
            property int feelsLike: 0
            property int dayTemp: 0
            property int nightTemp: 0
            property string weatherDesc: "Loading..."
            property string weatherIcon: "\uf0c2"

            function getTemp(celsius) {
                return Settings.weatherIsFahrenheit ? Math.round((celsius * 9/5) + 32) : Math.round(celsius);
            }

            function getFaIconFromWmo(code, isDay) {
                if (code === 0) return isDay ? "\uf185" : "\uf186";
                if (code === 1 || code === 2) return isDay ? "\uf185" : "\uf0c2";
                if (code === 3 || (code >= 45 && code <= 48)) return "\uf0c2";
                if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return "\uf043";
                if (code >= 71 && code <= 77) return "\uf2dc";
                if (code >= 95) return "\uf0e7";
                return isDay ? "\uf185" : "\uf0c2";
            }

            function fetchOpenMeteoData() {
                var lat = Settings.weatherLat || 10.0158;
                var lon = Settings.weatherLon || 76.3418;
                var url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon +
                          "&current=temperature_2m,apparent_temperature,is_day,weather_code" +
                          "&daily=temperature_2m_max,temperature_2m_min" +
                          "&timezone=auto";

                var xhr = new XMLHttpRequest();
                xhr.open("GET", url);
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                        try {
                            var data = JSON.parse(xhr.responseText);
                            weatherWidget.currentTemp = Math.round(data.current.temperature_2m);
                            weatherWidget.feelsLike = Math.round(data.current.apparent_temperature);
                            weatherWidget.dayTemp = Math.round(data.daily.temperature_2m_max[0]);
                            weatherWidget.nightTemp = Math.round(data.daily.temperature_2m_min[0]);
                            weatherWidget.weatherDesc = (data.current.weather_code === 0) ? "Clear Sky" : ((data.current.weather_code <= 3) ? "Partly Cloudy" : "Overcast");
                            weatherWidget.weatherIcon = weatherWidget.getFaIconFromWmo(data.current.weather_code, data.current.is_day);
                        } catch (e) {
                            console.log("Mini Weather Error: " + e);
                        }
                    }
                }
                xhr.send();
            }

            Timer {
                interval: 300000 
                running: dashboardRoot.visible
                repeat: true
                triggeredOnStart: true
                onTriggered: weatherWidget.fetchOpenMeteoData()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Metrics.spacingLarge
                spacing: 0

                Item { Layout.fillHeight: true }

                // TOP HALF: Icon & Status
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    Text {
                        text: weatherWidget.weatherIcon
                        color: Theme.main
                        font.family: Theme.fontIcon
                        font.pixelSize: 48 
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: weatherWidget.weatherDesc
                        color: Theme.text
                        font.family: Theme.fontMain
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: weatherWidget.getTemp(weatherWidget.currentTemp) + "°"
                        color: Theme.text
                        font.family: Theme.fontMain
                        font.pixelSize: 28
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                Item { Layout.fillHeight: true }

                // CENTERED SEPARATOR
                Rectangle {
                    Layout.preferredWidth: parent.width * 0.85
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 1
                    color: Theme.bridge
                    opacity: 0.5
                }

                Item { Layout.preferredHeight: Metrics.spacingLarge }

                // BOTTOM HALF: Auxiliary Temps
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 24 

                    ColumnLayout {
                        spacing: 4
                        Text { text: "Feels Like"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6); font.family: Theme.fontMain; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter }
                        Text { text: weatherWidget.getTemp(weatherWidget.feelsLike) + "°"; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 18; font.weight: Font.Bold; Layout.alignment: Qt.AlignHCenter }
                    }
                    ColumnLayout {
                        spacing: 4
                        Text { text: "Max"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6); font.family: Theme.fontMain; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter }
                        Text { text: weatherWidget.getTemp(weatherWidget.dayTemp) + "°"; color: Theme.main; font.family: Theme.fontMain; font.pixelSize: 18; font.weight: Font.Bold; Layout.alignment: Qt.AlignHCenter }
                    }
                    ColumnLayout {
                        spacing: 4
                        Text { text: "Min"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6); font.family: Theme.fontMain; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter }
                        Text { text: weatherWidget.getTemp(weatherWidget.nightTemp) + "°"; color: Theme.secondary; font.family: Theme.fontMain; font.pixelSize: 18; font.weight: Font.Bold; Layout.alignment: Qt.AlignHCenter }
                    }
                }

                Item { Layout.fillHeight: true }
            }
            
            MouseArea {
                id: weatherHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: dashboardRoot.navigateToTab(9) // WeatherReport tab
            }
        }

        // ==========================================
        // 5. CLOCK & CALENDAR WIDGET (Row 2, Cols 2-3)
        // ==========================================
        Rectangle {
            id: clockWidget
            Layout.column: 2
            Layout.row: 2
            Layout.columnSpan: 2
            Layout.rowSpan: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 80
            Layout.preferredHeight: 40
            color: "transparent"
            radius: Metrics.radiusBase
            border.width: 1
            border.color: clockHover.containsMouse ? Theme.secondary : Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.4)
            Behavior on border.color { ColorAnimation { duration: 150 } }
            clip: true

            property string timeStr: "00:00"
            property string secStr: "00"
            property string amPmStr: "AM"
            property string dayStr: "Monday"
            property string dateStr: "Jan 1, 1970"
            property bool is24h: Settings.is24HourFormat

            function updateTime() {
                let d = new Date();
                
                let hours = d.getHours();
                let mins = d.getMinutes();
                let secs = d.getSeconds();
                
                clockWidget.is24h = Settings.is24HourFormat;
                clockWidget.amPmStr = hours >= 12 ? "PM" : "AM";
                
                if (!clockWidget.is24h) {
                    hours = hours % 12;
                    hours = hours ? hours : 12; 
                }
                
                let hoursStr = hours < 10 && clockWidget.is24h ? '0' + hours : '' + hours;
                let minsStr = mins < 10 ? '0' + mins : mins;
                let secsStr = secs < 10 ? '0' + secs : secs;
                
                clockWidget.timeStr = hoursStr + ":" + minsStr;
                clockWidget.secStr = secsStr;
                
                const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
                const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
                
                clockWidget.dayStr = days[d.getDay()];
                clockWidget.dateStr = months[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear();
            }

            Timer {
                interval: 1000
                running: dashboardRoot.visible
                repeat: true
                triggeredOnStart: true
                onTriggered: clockWidget.updateTime()
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: Metrics.spacingLarge * 2
                spacing: Metrics.spacingLarge

                // LEFT: Time
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 12
                    
                    Text {
                        text: "\uf017" 
                        color: Theme.main
                        font.family: Theme.fontIcon
                        font.pixelSize: 46
                        opacity: 0.8
                    }

                    Text {
                        text: clockWidget.timeStr
                        color: Theme.text
                        font.family: Theme.fontMain
                        font.pixelSize: 56
                        font.weight: Font.Bold
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: 8
                        spacing: -4
                        
                        Text {
                            visible: !clockWidget.is24h
                            text: clockWidget.amPmStr
                            color: Theme.secondary
                            font.family: Theme.fontMain
                            font.pixelSize: 18
                            font.weight: Font.Bold
                        }
                        Text {
                            text: clockWidget.secStr
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                            font.family: Theme.fontMain
                            font.pixelSize: 18
                        }
                    }
                }

                Item { Layout.fillWidth: true } 

                // RIGHT: Day & Date
                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    spacing: 4
                    
                    Text {
                        text: clockWidget.dayStr
                        color: Theme.main
                        font.family: Theme.fontMain
                        font.pixelSize: 26
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignRight
                    }
                    Text {
                        text: clockWidget.dateStr
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                        font.family: Theme.fontMain
                        font.pixelSize: 18
                        font.weight: Font.Medium
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }

            MouseArea {
                id: clockHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: dashboardRoot.navigateToTab(8) // TimeDate tab
            }
        }

        // ==========================================
        // 6. BLUE BOX: UNREAD NOTIFICATIONS (Row 3, Cols 2-3)
        // ==========================================
        Rectangle {
            id: notifBox
            Layout.column: 2
            Layout.row: 3
            Layout.columnSpan: 2
            Layout.rowSpan: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 80
            Layout.preferredHeight: 40
            color: "transparent"
            radius: Metrics.radiusBase
            border.width: 1
            border.color: notifHover.containsMouse ? Theme.secondary : Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.4)
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 24

                Text {
                    text: "\uf0f3"
                    color: dashboardRoot.getUnreadCount() > 0 ? Theme.urgent : Theme.main
                    font.family: Theme.fontIcon
                    font.pixelSize: 46
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: "" + dashboardRoot.getUnreadCount()
                    color: dashboardRoot.getUnreadCount() > 0 ? Theme.urgent : Theme.text
                    font.family: Theme.fontMain
                    font.pixelSize: 46
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            MouseArea {
                id: notifHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: dashboardRoot.navigateToTab(3) // NotificationTray tab
            }
        }

        // ==========================================
        // 7. BATTERY INDICATOR (Row 2, Col 4)
        // ==========================================
        Rectangle {
            id: batBox
            Layout.column: 4
            Layout.row: 2
            Layout.columnSpan: 1
            Layout.rowSpan: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            color: "transparent"
            radius: Metrics.radiusBase
            border.width: 1
            border.color: batHover.containsMouse ? Theme.secondary : Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.4)
            Behavior on border.color { ColorAnimation { duration: 150 } }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    Text {
                        text: dashboardRoot.batAcOnline ? "\uf0e7" : (dashboardRoot.batCapacity >= 90 ? "\uf240" : (dashboardRoot.batCapacity >= 60 ? "\uf241" : (dashboardRoot.batCapacity >= 30 ? "\uf242" : "\uf243")))
                        color: dashboardRoot.batAcOnline ? Theme.main : (dashboardRoot.batCapacity <= 20 ? Theme.urgent : Theme.secondary)
                        font.family: Theme.fontIcon
                        font.pixelSize: 22
                    }

                    Text {
                        text: dashboardRoot.batCapacity + "%"
                        color: Theme.text
                        font.family: Theme.fontMain
                        font.pixelSize: 18
                        font.weight: Font.Bold
                    }
                }

                Text {
                    text: dashboardRoot.batAcOnline ? (dashboardRoot.batStatus === "Charging" ? "Charging" : "AC Connected") : "On Battery"
                    color: dashboardRoot.batAcOnline ? Theme.main : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                    font.family: Theme.fontMain
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 18
                    Layout.preferredWidth: profileText.implicitWidth + 12
                    radius: 9
                    color: Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.2)
                    border.width: 1
                    border.color: Theme.bridge

                    Text {
                        id: profileText
                        anchors.centerIn: parent
                        text: dashboardRoot.batProfile.charAt(0).toUpperCase() + dashboardRoot.batProfile.slice(1).replace("-", " ")
                        color: dashboardRoot.batProfile === "performance" ? Theme.urgent : (dashboardRoot.batProfile === "power-saver" ? Theme.main : Theme.secondary)
                        font.family: Theme.fontMain
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }
            }

            MouseArea {
                id: batHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: dashboardRoot.navigateToTab(15) // PowerUsage tab
            }
        }

        // ==========================================
        // 8. DARK GREEN BOX: NETWORK CONNECTIVITY (Row 2, Col 5)
        // ==========================================
        Rectangle {
            id: netBox
            Layout.column: 5
            Layout.row: 2
            Layout.columnSpan: 1
            Layout.rowSpan: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            color: "transparent"
            radius: Metrics.radiusBase
            border.width: 1
            border.color: netHover.containsMouse ? Theme.secondary : Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.4)
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: dashboardRoot.netType.indexOf("wireless") !== -1 ? "\uf1eb" : (dashboardRoot.netType.indexOf("ethernet") !== -1 ? "\uf796" : "\uf0ac")
                color: dashboardRoot.netName === "Disconnected" ? Qt.rgba(Theme.urgent.r, Theme.urgent.g, Theme.urgent.b, 0.4) : Theme.main
                font.family: Theme.fontIcon
                font.pixelSize: 46
            }

            MouseArea {
                id: netHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: dashboardRoot.navigateToTab(10) // NetworkConnectivity tab
            }
        }

        // ==========================================
        // 9. OPEN APPLICATIONS / SYSTEM TRAY (Row 3, Col 4)
        // ==========================================
        Rectangle {
            id: trayBox
            Layout.column: 4
            Layout.row: 3
            Layout.columnSpan: 1
            Layout.rowSpan: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            color: "transparent"
            radius: Metrics.radiusBase
            border.width: 1
            border.color: trayHover.containsMouse ? Theme.secondary : Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.4)
            Behavior on border.color { ColorAnimation { duration: 150 } }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 5

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    Text {
                        text: "\uf2d2"
                        color: Theme.main
                        font.family: Theme.fontIcon
                        font.pixelSize: 20
                    }

                    Text {
                        text: "" + dashboardRoot.openAppCount
                        color: Theme.text
                        font.family: Theme.fontMain
                        font.pixelSize: 18
                        font.weight: Font.Bold
                    }
                }

                // Mini preview of active app icons
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6
                    visible: dashboardRoot.openAppIcons.length > 0

                    Repeater {
                        model: dashboardRoot.openAppIcons
                        Text {
                            text: modelData
                            color: Theme.secondary
                            font.family: Theme.fontIcon
                            font.pixelSize: 12
                        }
                    }
                }

                Text {
                    text: "Open Apps"
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                    font.family: Theme.fontMain
                    font.pixelSize: 11
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            MouseArea {
                id: trayHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: dashboardRoot.navigateToTab(16) // SystemTray tab
            }
        }

        // ==========================================
        // 10. BROWN BOX: POWER BUTTON (Row 3, Col 5)
        // ==========================================
        Rectangle {
            id: powerBox
            Layout.column: 5
            Layout.row: 3
            Layout.columnSpan: 1
            Layout.rowSpan: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            color: "transparent"
            radius: Metrics.radiusBase
            border.width: 1
            border.color: powerHover.containsMouse ? Theme.secondary : Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.4)
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "\uf011"
                color: powerHover.containsMouse ? Theme.urgent : Theme.main
                font.family: Theme.fontIcon
                font.pixelSize: 46
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: powerHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: dashboardRoot.navigateToTab(14) // PowerMenu tab
            }
        }
    }
}
