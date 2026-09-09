import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io 

import "../../../theme" 
import "../../../theme/components" 

Item {
    id: statsRoot
    
    // --- DATA PROPERTIES ---
    ListModel { id: coreModel }
    ListModel { id: topAppsModel }
    
    property var lastCoreTicks: ({}) 
    
    property int ramUsage: 0 
    property string cpuRam: "0M / 0.0G" 
    property int totalCpuUsage: 0
    property int cpuTemp: 0
    property int gpuUsage: 0
    property int gpuTemp: 0
    property string gpuVram: "0.0G / 0.0G"

    property var cpuHistory: Array(30).fill(0)
    property var ramHistory: Array(30).fill(0)
    property var gpuHistory: Array(30).fill(0)

    // ==========================================
    // SHELL PROCESSES & TIMERS
    // ==========================================
    Process {
        id: fetchHardwareStats
        command: [
            "sh", "-c", 
            "export LC_ALL=C; " +
            "cores=$(nproc); " +
            "ram_t=$(free -m | awk '/^Mem/{print $2}'); " +
            "ram_u=$(free -m | awk '/^Mem/{print $3}'); " +
            "ram_p=$((ram_u * 100 / ram_t)); " +
            "cpu_u=$(top -bn1 | grep -i 'cpu(s)' | awk '{print $2}' | cut -d. -f1 | cut -d, -f1); " +
            
            // SMART CPU SENSOR DETECTION: Scans for AMD (k10temp) and Intel (coretemp) sensors
            "cpu_sensor=$(grep -lE 'k10temp|coretemp' /sys/class/hwmon/hwmon*/name 2>/dev/null | head -n 1 | sed 's/name/temp1_input/'); " +
            "if [ -f \"$cpu_sensor\" ]; then cpu_temp=$(cat \"$cpu_sensor\" 2>/dev/null || echo 0); else cpu_temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0); fi; " +
            "cpu_tc=$((cpu_temp / 1000)); " +
            
            "top_apps=$(ps -eo comm=,pcpu=,pmem= --sort=-pcpu | head -n 5 | awk -v c=\"$cores\" '{ gsub(/\"/, \"\", $1); printf \"{\\\"name\\\":\\\"%s\\\", \\\"cpu\\\":%.1f, \\\"mem\\\":%.1f},\", $1, $2/c, $3 }' | sed 's/,$//'); " +
            
            // CORRECTED: Numerically sorts cores and captures extra fields for accurate ticks
            "cores_stat=$(grep -E '^cpu[0-9]+' /proc/stat | sort -V | awk '{ printf \"{\\\"name\\\":\\\"%s\\\", \\\"user\\\":%s, \\\"nice\\\":%s, \\\"sys\\\":%s, \\\"idle\\\":%s, \\\"iowait\\\":%s, \\\"irq\\\":%s, \\\"softirq\\\":%s},\", $1, $2, $3, $4, $5, $6, $7, $8 }' | sed 's/,$//'); " +
            
            "gpu_u=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | grep -Eo '^[0-9]+' | head -n 1); " +
            "gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | grep -Eo '^[0-9]+' | head -n 1); " +
            "gpu_mu=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null | grep -Eo '^[0-9]+' | head -n 1); " +
            "gpu_mt=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | grep -Eo '^[0-9]+' | head -n 1); " +
            "gpu_v=$(awk -v u=\"${gpu_mu:-0}\" -v t=\"${gpu_mt:-1}\" 'BEGIN { printf \"%.1fG / %.1fG\", u/1024, t/1024 }'); " +
            "printf '{\"ramUsage\":%s, \"cpuRam\":\"%sM / %sM\", \"cpuUsage\":%s, \"cpuTemp\":%s, \"gpuUsage\":%s, \"gpuTemp\":%s, \"gpuVram\":\"%s\", \"topApps\":[%s], \"cores\":[%s]}' \"${ram_p:-0}\" \"${ram_u:-0}\" \"${ram_t:-0}\" \"${cpu_u:-0}\" \"${cpu_tc:-0}\" \"${gpu_u:-0}\" \"${gpu_temp:-0}\" \"${gpu_v:-0}\" \"${top_apps}\" \"${cores_stat}\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text.trim() === "") return;
                    let parsed = JSON.parse(this.text);
                    
                    statsRoot.ramUsage = parsed.ramUsage;
                    statsRoot.cpuRam = parsed.cpuRam;
                    statsRoot.totalCpuUsage = parsed.cpuUsage;
                    statsRoot.cpuTemp = parsed.cpuTemp;
                    
                    statsRoot.gpuUsage = parsed.gpuUsage;
                    statsRoot.gpuTemp = parsed.gpuTemp;
                    statsRoot.gpuVram = parsed.gpuVram;
                    
                    for (let i = 0; i < parsed.cores.length; i++) {
                        let c = parsed.cores[i];
                        // CORRECTED: Includes iowait, irq, and softirq for an exact percentage calculation
                        let total = c.user + c.nice + c.sys + c.idle + c.iowait + c.irq + c.softirq;
                        let idle = c.idle + c.iowait;
                        let usage = 0;

                        if (statsRoot.lastCoreTicks[c.name]) {
                            let prev = statsRoot.lastCoreTicks[c.name];
                            let deltaTotal = total - prev.total;
                            let deltaIdle = idle - prev.idle;
                            if (deltaTotal > 0) {
                                usage = Math.round(100 * (deltaTotal - deltaIdle) / deltaTotal);
                            }
                        }
                        statsRoot.lastCoreTicks[c.name] = { total: total, idle: idle };
                        let coreName = c.name.replace("cpu", "Core ");
                        
                        if (coreModel.count <= i) {
                            coreModel.append({ name: coreName, usage: usage, rawUsage: usage / 100.0 });
                        } else {
                            coreModel.setProperty(i, "usage", usage);
                            coreModel.setProperty(i, "rawUsage", usage / 100.0);
                        }
                    }

                    for (let j = 0; j < parsed.topApps.length; j++) {
                        let app = parsed.topApps[j];
                        
                        if (topAppsModel.count <= j) {
                            topAppsModel.append(app);
                        } else {
                            topAppsModel.setProperty(j, "name", app.name);
                            topAppsModel.setProperty(j, "cpu", app.cpu);
                            topAppsModel.setProperty(j, "mem", app.mem);
                        }
                    }

                    let newCpuHist = statsRoot.cpuHistory.slice();
                    newCpuHist.push(parsed.cpuUsage);
                    if (newCpuHist.length > 30) newCpuHist.shift();
                    statsRoot.cpuHistory = newCpuHist;

                    let newRamHist = statsRoot.ramHistory.slice();
                    newRamHist.push(parsed.ramUsage);
                    if (newRamHist.length > 30) newRamHist.shift();
                    statsRoot.ramHistory = newRamHist;
                    
                    let newGpuHist = statsRoot.gpuHistory.slice();
                    newGpuHist.push(parsed.gpuUsage);
                    if (newGpuHist.length > 30) newGpuHist.shift();
                    statsRoot.gpuHistory = newGpuHist;

                    historyCanvas.requestPaint();

                } catch (e) {
                    console.log("Stats JSON Parse Error: " + e.message);
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 2000
        repeat: true
        running: statsRoot.visible
        onTriggered: fetchHardwareStats.running = true
    }

    onVisibleChanged: {
        if (visible) {
            fetchHardwareStats.running = true;
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
                text: "System Performance"
                color: Theme.main
                font.family: Theme.fontMain
                font.pixelSize: 16
                font.weight: Font.Bold
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentLayout.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height 
            
            RowLayout {
                id: contentLayout
                width: parent.width - (Metrics.spacingLarge * 2)
                height: parent.height 
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 40
                Layout.alignment: Qt.AlignTop

                // ==========================================
                // LEFT COLUMN: DASHBOARD GAUGES
                // ==========================================
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: 200
                    Layout.fillHeight: true 
                    spacing: 0 
                    
                    Item { Layout.fillHeight: true } 

                    // --- CPU GAUGE ---
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8
                        
                        Text { 
                            text: "CPU"
                            color: Theme.text
                            font.family: Theme.fontMain
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            Layout.alignment: Qt.AlignHCenter 
                        }
                        
                        Item {
                            width: 100 
                            height: 100
                            Layout.alignment: Qt.AlignHCenter
                            
                            property int pct: statsRoot.totalCpuUsage
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
                                    ctx.lineWidth = 9; 
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
                                        ctx.arc(x, y, r, -Math.PI/2, -Math.PI/2 + (2 * Math.PI * parent.animVal)); 
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
                                font.pixelSize: 22
                                font.weight: Font.Bold 
                            }
                        }
                        Text { 
                            text: statsRoot.cpuTemp + "°C"
                            color: statsRoot.cpuTemp >= 80 ? Theme.urgent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                            font.family: Theme.fontMain
                            font.pixelSize: 15
                            font.weight: Font.Medium
                            Layout.alignment: Qt.AlignHCenter 
                        }
                    }

                    Item { Layout.fillHeight: true } 

                    // --- RAM GAUGE ---
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8
                        
                        Text { 
                            text: "RAM"
                            color: Theme.text
                            font.family: Theme.fontMain
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            Layout.alignment: Qt.AlignHCenter 
                        }
                        
                        Item {
                            width: 100
                            height: 100
                            Layout.alignment: Qt.AlignHCenter
                            
                            property int pct: statsRoot.ramUsage
                            property color gColor: pct >= 80 ? Theme.urgent : Theme.main
                            property real animVal: pct / 100.0
                            
                            Behavior on animVal { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                            onAnimValChanged: ramCanvas.requestPaint() 
                            
                            Canvas {
                                id: ramCanvas
                                anchors.fill: parent
                                onPaint: {
                                    var ctx = getContext("2d"); 
                                    ctx.clearRect(0, 0, width, height);
                                    ctx.lineWidth = 9; 
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
                                        ctx.arc(x, y, r, -Math.PI/2, -Math.PI/2 + (2 * Math.PI * parent.animVal)); 
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
                                font.pixelSize: 22
                                font.weight: Font.Bold 
                            }
                        }
                        
                        Text { 
                            text: statsRoot.cpuRam
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                            font.family: Theme.fontMain
                            font.pixelSize: 15
                            font.weight: Font.Medium
                            Layout.alignment: Qt.AlignHCenter 
                        }
                        
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 4
                            width: 100
                            height: 28
                            radius: 14
                            color: clearMouse.containsMouse ? Qt.darker(Theme.base, 1.2) : "transparent"
                            border.color: Theme.bridge
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            Text { 
                                anchors.centerIn: parent
                                text: "Clear Cache"
                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.9)
                                font.family: Theme.fontMain
                                font.pixelSize: 12
                                font.weight: Font.Bold 
                            }
                            MouseArea { 
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: console.log("Clear cache triggered via backend...")
                            }
                        }
                    }

                    Item { Layout.fillHeight: true } 

                    // --- GPU GAUGE ---
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8
                        
                        Text { 
                            text: "GPU"
                            color: Theme.text
                            font.family: Theme.fontMain
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            Layout.alignment: Qt.AlignHCenter 
                        }
                        
                        Item {
                            width: 100
                            height: 100
                            Layout.alignment: Qt.AlignHCenter
                            
                            property int pct: statsRoot.gpuUsage
                            property color gColor: pct >= 80 ? Theme.urgent : Theme.main
                            property real animVal: pct / 100.0
                            
                            Behavior on animVal { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                            onAnimValChanged: gpuCanvas.requestPaint()
                            
                            Canvas {
                                id: gpuCanvas
                                anchors.fill: parent
                                onPaint: {
                                    var ctx = getContext("2d"); 
                                    ctx.clearRect(0, 0, width, height);
                                    ctx.lineWidth = 9; 
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
                                        ctx.arc(x, y, r, -Math.PI/2, -Math.PI/2 + (2 * Math.PI * parent.animVal)); 
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
                                font.pixelSize: 22
                                font.weight: Font.Bold 
                            }
                        }
                        Text { 
                            text: statsRoot.gpuTemp + "°C | " + statsRoot.gpuVram
                            color: statsRoot.gpuTemp >= 80 ? Theme.urgent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                            font.family: Theme.fontMain
                            font.pixelSize: 15
                            font.weight: Font.Medium
                            Layout.alignment: Qt.AlignHCenter 
                        }
                    }

                    Item { Layout.fillHeight: true } 
                }
                
                // ==========================================
                // VERTICAL DIVIDER LINE
                // ==========================================
                Rectangle { 
                    Layout.fillHeight: true
                    width: 2
                    color: Qt.darker(Theme.base, 1.2)
                    radius: 1 
                }

                // ==========================================
                // RIGHT COLUMN: CORES, APPS, AND GRAPH
                // ==========================================
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.fillWidth: true
                    spacing: 25

                    // --- 1. CPU CORES GRID ---
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text { 
                            text: "CPU Cores"
                            color: Theme.text
                            font.family: Theme.fontMain
                            font.pixelSize: 18
                            font.weight: Font.Bold 
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 4 
                            columnSpacing: 20
                            rowSpacing: 18

                            Repeater {
                                model: coreModel 
                                delegate: ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { 
                                            text: model.name 
                                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                                            font.family: Theme.fontMain
                                            font.pixelSize: 14
                                            Layout.fillWidth: true 
                                        }
                                        Text { 
                                            text: model.usage + "%"
                                            color: Theme.text
                                            font.family: Theme.fontMain
                                            font.pixelSize: 14
                                            font.weight: Font.Bold 
                                        }
                                    }
                                    
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 8
                                        radius: 4
                                        color: Qt.darker(Theme.base, 1.2)
                                        
                                        Rectangle {
                                            width: Math.max(0, Math.min(parent.width, parent.width * model.rawUsage))
                                            height: parent.height
                                            radius: 4
                                            color: model.usage >= 80 ? Theme.urgent : Theme.main
                                            Behavior on color { ColorAnimation { duration: 300 } }
                                            Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // --- 2. TOP PROCESSES ---
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12 

                        Text { 
                            text: "Top Power Consumers"
                            color: Theme.text
                            font.family: Theme.fontMain
                            font.pixelSize: 18
                            font.weight: Font.Bold 
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 12 
                            
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Application"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5); font.family: Theme.fontMain; font.pixelSize: 13; font.weight: Font.Bold; Layout.fillWidth: true }
                                Text { text: "CPU %"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5); font.family: Theme.fontMain; font.pixelSize: 13; font.weight: Font.Bold; Layout.preferredWidth: 60; horizontalAlignment: Text.AlignRight }
                                Text { text: "RAM %"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5); font.family: Theme.fontMain; font.pixelSize: 13; font.weight: Font.Bold; Layout.preferredWidth: 60; horizontalAlignment: Text.AlignRight }
                            }
                            
                            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.darker(Theme.base, 1.2) }

                            Repeater {
                                model: topAppsModel 
                                delegate: RowLayout {
                                    Layout.fillWidth: true
                                    
                                    property string cleanName: {
                                        if (!model.name) return "";
                                        let n = model.name.replace(/^\./, '').replace(/-wrap.*$/, '');
                                        return n.charAt(0).toUpperCase() + n.slice(1);
                                    }
                                    
                                    Text { 
                                        text: parent.cleanName
                                        color: Theme.text
                                        font.family: Theme.fontMain
                                        font.pixelSize: 15
                                        font.weight: Font.Medium
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    Text { 
                                        text: model.cpu + "%"
                                        color: model.cpu > 50 ? Theme.urgent : Theme.main
                                        font.family: Theme.fontMain
                                        font.pixelSize: 15
                                        font.weight: Font.Bold
                                        Layout.preferredWidth: 60
                                        horizontalAlignment: Text.AlignRight
                                    }
                                    Text { 
                                        text: model.mem + "%"
                                        color: Theme.secondary
                                        font.family: Theme.fontMain
                                        font.pixelSize: 15
                                        font.weight: Font.Bold
                                        Layout.preferredWidth: 60
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }

                    // --- 3. LIVE USAGE GRAPH ---
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true 
                        spacing: 12
                        Layout.topMargin: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Text { 
                                text: "Usage History (60s)"
                                color: Theme.text
                                font.family: Theme.fontMain
                                font.pixelSize: 18
                                font.weight: Font.Bold 
                                Layout.fillWidth: true
                            }
                            RowLayout {
                                spacing: 8
                                Rectangle { width: 12; height: 12; radius: 6; color: Theme.main }
                                Text { text: "CPU"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7); font.family: Theme.fontMain; font.pixelSize: 13 }
                                
                                Rectangle { width: 12; height: 12; radius: 6; color: Theme.secondary; Layout.leftMargin: 8 }
                                Text { text: "RAM"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7); font.family: Theme.fontMain; font.pixelSize: 13 }
                                
                                Rectangle { width: 12; height: 12; radius: 6; color: Theme.urgent; Layout.leftMargin: 8 }
                                Text { text: "GPU"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7); font.family: Theme.fontMain; font.pixelSize: 13 }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 120
                            color: Qt.darker(Theme.base, 1.2)
                            radius: Metrics.radiusBase

                            Canvas {
                                id: historyCanvas
                                anchors.fill: parent
                                anchors.margins: 10

                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);

                                    function drawLine(historyArray, strokeColor) {
                                        if (historyArray.length === 0) return;
                                        
                                        ctx.beginPath();
                                        ctx.lineWidth = 3;
                                        ctx.strokeStyle = strokeColor;
                                        ctx.lineJoin = "round";

                                        let stepX = width / (historyArray.length - 1);
                                        
                                        for (let i = 0; i < historyArray.length; i++) {
                                            let x = i * stepX;
                                            let y = height - (historyArray[i] / 100.0 * height);
                                            
                                            if (i === 0) {
                                                ctx.moveTo(x, y);
                                            } else {
                                                ctx.lineTo(x, y);
                                            }
                                        }
                                        ctx.stroke();
                                    }

                                    drawLine(statsRoot.cpuHistory, Theme.main.toString());
                                    drawLine(statsRoot.ramHistory, Theme.secondary.toString());
                                    drawLine(statsRoot.gpuHistory, Theme.urgent.toString());
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
