import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

import "../../../../theme"
import "../../../../theme/components"

Item {
    id: powerUsageRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    // ==========================================
    // BACKEND DATA PROPERTIES
    // ==========================================
    property int batteryCapacity: 100
    property string batteryStatus: "Unknown"
    property string powerRate: "0.0"
    property string voltage: "0.0"
    property string energyNow: "0.0"
    property string energyFull: "0.0"
    property string energyDesign: "0.0"
    property int batteryHealth: 100
    property int cycleCount: 0
    property bool isAcOnline: false
    property string activeProfile: "balanced"

    ListModel { id: topAppsModel }

    // ==========================================
    // SHELL PROCESSES & TIMERS
    // ==========================================
    Process {
        id: fetchPowerStats
        command: [
            "bash", "-c",
            "BAT='/sys/class/power_supply/BAT0'; " +
            "AC='/sys/class/power_supply/ADP0'; " +
            "CAP=$(cat $BAT/capacity 2>/dev/null || echo 0); " +
            "STAT=$(cat $BAT/status 2>/dev/null || echo 'Unknown'); " +
            "PWR=$(cat $BAT/power_now 2>/dev/null || echo 0); " +
            "PWR_W=$(awk -v p=\"$PWR\" 'BEGIN { printf \"%.1f\", p / 1000000 }'); " +
            "VOLT=$(cat $BAT/voltage_now 2>/dev/null || echo 0); " +
            "VOLT_V=$(awk -v v=\"$VOLT\" 'BEGIN { printf \"%.2f\", v / 1000000 }'); " +
            "ENOW=$(cat $BAT/energy_now 2>/dev/null || echo 0); " +
            "EFULL=$(cat $BAT/energy_full 2>/dev/null || echo 0); " +
            "EDESIGN=$(cat $BAT/energy_full_design 2>/dev/null || echo 0); " +
            "ENOW_WH=$(awk -v e=\"$ENOW\" 'BEGIN { printf \"%.1f\", e / 1000000 }'); " +
            "EFULL_WH=$(awk -v e=\"$EFULL\" 'BEGIN { printf \"%.1f\", e / 1000000 }'); " +
            "EDESIGN_WH=$(awk -v e=\"$EDESIGN\" 'BEGIN { printf \"%.1f\", e / 1000000 }'); " +
            "HEALTH=$(awk -v f=\"$EFULL\" -v d=\"$EDESIGN\" 'BEGIN { if (d > 0) printf \"%.0f\", (f * 100) / d; else print 100 }'); " +
            "CYCLES=$(cat $BAT/cycle_count 2>/dev/null || echo 0); " +
            "AC_ONLINE=$(cat $AC/online 2>/dev/null || echo 0); " +
            "PROFILE=$(powerprofilesctl get 2>/dev/null || echo 'balanced'); " +
            "TOP_APPS=$(ps -eo comm=,pcpu=,pmem= --sort=-pcpu | grep -vE '^ps\\s' | head -n 5 | awk '{ printf \"{\\\"name\\\":\\\"%s\\\", \\\"cpu\\\":%.1f, \\\"mem\\\":%.1f},\", $1, $2, $3 }' | sed 's/,$//'); " +
            "printf '{\"capacity\":%s, \"status\":\"%s\", \"powerRate\":\"%s\", \"voltage\":\"%s\", \"energyNow\":\"%s\", \"energyFull\":\"%s\", \"energyDesign\":\"%s\", \"health\":%s, \"cycles\":%s, \"acOnline\":%s, \"profile\":\"%s\", \"topApps\":[%s]}' " +
            "\"$CAP\" \"$STAT\" \"$PWR_W\" \"$VOLT_V\" \"$ENOW_WH\" \"$EFULL_WH\" \"$EDESIGN_WH\" \"$HEALTH\" \"$CYCLES\" \"$AC_ONLINE\" \"$PROFILE\" \"$TOP_APPS\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text.trim() === "") return;
                    let parsed = JSON.parse(this.text);
                    powerUsageRoot.batteryCapacity = parsed.capacity;
                    powerUsageRoot.batteryStatus = parsed.status;
                    powerUsageRoot.powerRate = parsed.powerRate;
                    powerUsageRoot.voltage = parsed.voltage;
                    powerUsageRoot.energyNow = parsed.energyNow;
                    powerUsageRoot.energyFull = parsed.energyFull;
                    powerUsageRoot.energyDesign = parsed.energyDesign;
                    powerUsageRoot.batteryHealth = parsed.health;
                    powerUsageRoot.cycleCount = parsed.cycles;
                    powerUsageRoot.isAcOnline = (parsed.acOnline === 1);
                    powerUsageRoot.activeProfile = parsed.profile;

                    for (let i = 0; i < parsed.topApps.length; i++) {
                        let app = parsed.topApps[i];
                        if (topAppsModel.count <= i) {
                            topAppsModel.append(app);
                        } else {
                            topAppsModel.setProperty(i, "name", app.name);
                            topAppsModel.setProperty(i, "cpu", app.cpu);
                            topAppsModel.setProperty(i, "mem", app.mem);
                        }
                    }
                    while (topAppsModel.count > parsed.topApps.length) {
                        topAppsModel.remove(topAppsModel.count - 1);
                    }
                } catch(e) {
                    console.log("PowerUsage parse error: " + e.message);
                }
            }
        }
    }

    Process {
        id: setProfileProcess
        onExited: {
            running = false;
            fetchPowerStats.running = true;
        }
    }

    function setPowerProfile(profileName) {
        powerUsageRoot.activeProfile = profileName;
        setProfileProcess.running = false;
        setProfileProcess.command = ["powerprofilesctl", "set", profileName];
        setProfileProcess.running = true;
    }

    Timer {
        interval: 2500
        running: powerUsageRoot.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: fetchPowerStats.running = true
    }

    onVisibleChanged: {
        if (visible) fetchPowerStats.running = true;
    }

    // ==========================================
    // MAIN UI LAYOUT
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Metrics.spacingLarge
        spacing: Metrics.spacingLarge

        // --- 1. HEADER ---
        RowLayout {
            Layout.fillWidth: true
            spacing: Metrics.spacingLarge

            Text {
                text: "\uf240"
                color: Theme.main
                font.family: Theme.fontIcon
                font.pixelSize: 26
            }

            ColumnLayout {
                spacing: 2
                Text {
                    text: "Power & Battery Management"
                    color: Theme.main
                    font.family: Theme.fontMain
                    font.pixelSize: 18
                    font.weight: Font.Bold
                }
                Text {
                    text: "Real-time battery consumption, charge rate, and power profile controls"
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                    font.family: Theme.fontMain
                    font.pixelSize: 13
                }
            }

            Item { Layout.fillWidth: true }

            // AC Status Badge
            Rectangle {
                Layout.preferredHeight: 30
                Layout.preferredWidth: acRow.implicitWidth + 16
                radius: 15
                color: powerUsageRoot.isAcOnline ? Qt.rgba(Theme.main.r, Theme.main.g, Theme.main.b, 0.15) : Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.15)
                border.width: 1
                border.color: powerUsageRoot.isAcOnline ? Theme.main : Theme.bridge

                RowLayout {
                    id: acRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: powerUsageRoot.isAcOnline ? "\uf0e7" : "\uf242"
                        color: powerUsageRoot.isAcOnline ? Theme.main : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                        font.family: Theme.fontIcon
                        font.pixelSize: 13
                    }

                    Text {
                        text: powerUsageRoot.isAcOnline ? (powerUsageRoot.batteryStatus === "Charging" ? "Charging" : "AC Connected") : "On Battery"
                        color: powerUsageRoot.isAcOnline ? Theme.main : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                        font.family: Theme.fontMain
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
                }
            }
        }

        // --- 2. MAIN 2-COLUMN DASHBOARD ---
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Metrics.spacingLarge

            // ==========================================
            // LEFT COLUMN: BATTERY DETAILS & PROFILES
            // ==========================================
            ColumnLayout {
                Layout.preferredWidth: 420
                Layout.fillHeight: true
                spacing: Metrics.spacingLarge

                // A. BATTERY STATUS CARD
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 250
                    color: "transparent"
                    radius: Metrics.radiusBase
                    border.width: 1
                    border.color: Theme.bridge

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingLarge
                        spacing: Metrics.spacingLarge

                        // Circular Gauge Dial
                        Item {
                            width: 140
                            height: 140
                            Layout.alignment: Qt.AlignVCenter

                            property int pct: powerUsageRoot.batteryCapacity
                            property color gColor: pct <= 20 ? Theme.urgent : (powerUsageRoot.isAcOnline ? Theme.main : Theme.secondary)
                            property real animVal: pct / 100.0

                            Behavior on animVal { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                            onAnimValChanged: batCanvas.requestPaint()

                            Canvas {
                                id: batCanvas
                                anchors.fill: parent
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);
                                    ctx.lineWidth = 10;
                                    ctx.lineCap = "round";
                                    var x = width / 2;
                                    var y = height / 2;
                                    var r = width / 2 - 8;

                                    ctx.beginPath();
                                    ctx.arc(x, y, r, 0, 2 * Math.PI);
                                    ctx.strokeStyle = Qt.darker(Theme.base, 1.3).toString();
                                    ctx.stroke();

                                    if (parent.animVal > 0) {
                                        ctx.beginPath();
                                        ctx.arc(x, y, r, -Math.PI / 2, -Math.PI / 2 + (2 * Math.PI * parent.animVal));
                                        ctx.strokeStyle = parent.gColor.toString();
                                        ctx.stroke();
                                    }
                                }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    text: powerUsageRoot.isAcOnline ? "\uf0e7" : "\uf240"
                                    color: parent.parent.gColor
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 22
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Text {
                                    text: powerUsageRoot.batteryCapacity + "%"
                                    color: Theme.text
                                    font.family: Theme.fontMain
                                    font.pixelSize: 26
                                    font.weight: Font.Bold
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }

                        // Battery Specs Column
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 8

                            Text {
                                text: powerUsageRoot.batteryStatus
                                color: Theme.main
                                font.family: Theme.fontMain
                                font.pixelSize: 18
                                font.weight: Font.Bold
                            }

                            RowLayout {
                                spacing: 6
                                Text { text: "Charge Rate:"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6); font.family: Theme.fontMain; font.pixelSize: 13 }
                                Text { text: powerUsageRoot.powerRate + " W"; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 13; font.weight: Font.Bold }
                            }

                            RowLayout {
                                spacing: 6
                                Text { text: "Voltage:"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6); font.family: Theme.fontMain; font.pixelSize: 13 }
                                Text { text: powerUsageRoot.voltage + " V"; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 13; font.weight: Font.Bold }
                            }

                            RowLayout {
                                spacing: 6
                                Text { text: "Energy:"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6); font.family: Theme.fontMain; font.pixelSize: 13 }
                                Text { text: powerUsageRoot.energyNow + " / " + powerUsageRoot.energyFull + " Wh"; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 13; font.weight: Font.Bold }
                            }

                            RowLayout {
                                spacing: 6
                                Text { text: "Health:"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6); font.family: Theme.fontMain; font.pixelSize: 13 }
                                Text { text: powerUsageRoot.batteryHealth + "%"; color: powerUsageRoot.batteryHealth >= 80 ? Theme.main : Theme.urgent; font.family: Theme.fontMain; font.pixelSize: 13; font.weight: Font.Bold }
                            }

                            RowLayout {
                                spacing: 6
                                Text { text: "Cycles:"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6); font.family: Theme.fontMain; font.pixelSize: 13 }
                                Text { text: powerUsageRoot.cycleCount + " cycles"; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 13; font.weight: Font.Bold }
                            }
                        }
                    }
                }

                // B. POWER PROFILES CARD
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    radius: Metrics.radiusBase
                    border.width: 1
                    border.color: Theme.bridge

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingLarge
                        spacing: 12

                        Text {
                            text: "Power Profile (powerprofilesctl)"
                            color: Theme.main
                            font.family: Theme.fontMain
                            font.pixelSize: 15
                            font.weight: Font.Bold
                        }

                        // Profile 1: Power Saver
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            radius: Metrics.radiusBase
                            color: powerUsageRoot.activeProfile === "power-saver" ? Qt.rgba(Theme.main.r, Theme.main.g, Theme.main.b, 0.15) : "transparent"
                            border.width: 1
                            border.color: powerUsageRoot.activeProfile === "power-saver" ? Theme.main : (psHover.containsMouse ? Theme.secondary : Theme.bridge)
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 12

                                Text {
                                    text: "\uf06c"
                                    color: powerUsageRoot.activeProfile === "power-saver" ? Theme.main : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 20
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text { text: "Power Saver"; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 13; font.weight: Font.Bold }
                                    Text { text: "Throttles CPU to extend battery lifespan"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6); font.family: Theme.fontMain; font.pixelSize: 11 }
                                }

                                Rectangle {
                                    width: 12; height: 12; radius: 6
                                    color: powerUsageRoot.activeProfile === "power-saver" ? Theme.main : "transparent"
                                    border.width: 1; border.color: Theme.main
                                }
                            }

                            MouseArea {
                                id: psHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: powerUsageRoot.setPowerProfile("power-saver")
                            }
                        }

                        // Profile 2: Balanced
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            radius: Metrics.radiusBase
                            color: powerUsageRoot.activeProfile === "balanced" ? Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.15) : "transparent"
                            border.width: 1
                            border.color: powerUsageRoot.activeProfile === "balanced" ? Theme.secondary : (balHover.containsMouse ? Theme.secondary : Theme.bridge)
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 12

                                Text {
                                    text: "\uf24e"
                                    color: powerUsageRoot.activeProfile === "balanced" ? Theme.secondary : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 20
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text { text: "Balanced"; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 13; font.weight: Font.Bold }
                                    Text { text: "Standard daily efficiency and responsiveness"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6); font.family: Theme.fontMain; font.pixelSize: 11 }
                                }

                                Rectangle {
                                    width: 12; height: 12; radius: 6
                                    color: powerUsageRoot.activeProfile === "balanced" ? Theme.secondary : "transparent"
                                    border.width: 1; border.color: Theme.secondary
                                }
                            }

                            MouseArea {
                                id: balHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: powerUsageRoot.setPowerProfile("balanced")
                            }
                        }

                        // Profile 3: Performance
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            radius: Metrics.radiusBase
                            color: powerUsageRoot.activeProfile === "performance" ? Qt.rgba(Theme.urgent.r, Theme.urgent.g, Theme.urgent.b, 0.15) : "transparent"
                            border.width: 1
                            border.color: powerUsageRoot.activeProfile === "performance" ? Theme.urgent : (perfHover.containsMouse ? Theme.secondary : Theme.bridge)
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 12

                                Text {
                                    text: "\uf135"
                                    color: powerUsageRoot.activeProfile === "performance" ? Theme.urgent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 20
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text { text: "Performance"; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 13; font.weight: Font.Bold }
                                    Text { text: "High performance for heavy computational tasks"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6); font.family: Theme.fontMain; font.pixelSize: 11 }
                                }

                                Rectangle {
                                    width: 12; height: 12; radius: 6
                                    color: powerUsageRoot.activeProfile === "performance" ? Theme.urgent : "transparent"
                                    border.width: 1; border.color: Theme.urgent
                                }
                            }

                            MouseArea {
                                id: perfHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: powerUsageRoot.setPowerProfile("performance")
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            // ==========================================
            // RIGHT COLUMN: TOP 5 POWER CONSUMING APPS
            // ==========================================
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                radius: Metrics.radiusBase
                border.width: 1
                border.color: Theme.bridge

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Metrics.spacingLarge
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "\uf085"
                            color: Theme.secondary
                            font.family: Theme.fontIcon
                            font.pixelSize: 18
                        }

                        ColumnLayout {
                            spacing: 1
                            Text {
                                text: "Top Power Consumers"
                                color: Theme.main
                                font.family: Theme.fontMain
                                font.pixelSize: 15
                                font.weight: Font.Bold
                            }
                            Text {
                                text: "Applications generating the highest processing and energy load"
                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                                font.family: Theme.fontMain
                                font.pixelSize: 12
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.bridge
                        opacity: 0.4
                    }

                    // Process List
                    ListView {
                        id: appListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: topAppsModel
                        spacing: 10
                        clip: true

                        delegate: Rectangle {
                            width: appListView.width
                            height: 64
                            radius: Metrics.radiusBase
                            color: "transparent"
                            border.width: 1
                            border.color: appHover.containsMouse ? Theme.secondary : Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.3)
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 14

                                // Rank Number
                                Rectangle {
                                    width: 30
                                    height: 30
                                    radius: 15
                                    color: index === 0 ? Qt.rgba(Theme.urgent.r, Theme.urgent.g, Theme.urgent.b, 0.2) : Qt.rgba(Theme.main.r, Theme.main.g, Theme.main.b, 0.15)
                                    border.width: 1
                                    border.color: index === 0 ? Theme.urgent : Theme.main

                                    Text {
                                        anchors.centerIn: parent
                                        text: "#" + (index + 1)
                                        color: index === 0 ? Theme.urgent : Theme.main
                                        font.family: Theme.fontMain
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                    }
                                }

                                // App Name & Metrics
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: model.name
                                            color: Theme.text
                                            font.family: Theme.fontMain
                                            font.pixelSize: 14
                                            font.weight: Font.Bold
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: model.cpu.toFixed(1) + "% CPU"
                                            color: model.cpu > 25 ? Theme.urgent : Theme.secondary
                                            font.family: Theme.fontMain
                                            font.pixelSize: 12
                                            font.weight: Font.Bold
                                        }

                                        Text {
                                            text: "(" + model.mem.toFixed(1) + "% RAM)"
                                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                                            font.family: Theme.fontMain
                                            font.pixelSize: 11
                                        }
                                    }

                                    // Energy Impact Bar
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 6
                                        radius: 3
                                        color: Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.3)

                                        Rectangle {
                                            width: Math.min(parent.width, (model.cpu / 100.0) * parent.width)
                                            height: parent.height
                                            radius: 3
                                            color: model.cpu > 25 ? Theme.urgent : (index === 0 ? Theme.main : Theme.secondary)
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: appHover
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }
            }
        }
    }
}
