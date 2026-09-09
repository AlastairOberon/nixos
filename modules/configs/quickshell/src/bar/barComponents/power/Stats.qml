import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes 
import Quickshell
import Quickshell.Io 

import "../../../theme" 

Item {
    id: statsRoot
    
    Layout.preferredWidth: contentLayout.implicitWidth
    Layout.fillHeight: true

    property int cpuUsage: 0
    property int ramUsage: 0

    property real prevIdle: 0
    property real prevTotal: 0

    Process {
        id: statsProc
        command: ["bash", "-c", "echo \"$(grep '^cpu ' /proc/stat) | $(free -m | grep Mem)\""]
        
        stdout: SplitParser {
            onRead: function(data) {
                let parts = data.trim().split('|');
                if (parts.length < 2) return;
                
                // --- 1. CPU CALCULATION ---
                let cpuCols = parts[0].trim().split(/\s+/);
                if (cpuCols.length >= 8 && cpuCols[0] === "cpu") {
                    
                    // Explicitly map each column according to standard Linux docs
                    let user = parseInt(cpuCols[1]) || 0;
                    let nice = parseInt(cpuCols[2]) || 0;
                    let system = parseInt(cpuCols[3]) || 0;
                    let idle = parseInt(cpuCols[4]) || 0;
                    let iowait = parseInt(cpuCols[5]) || 0;
                    let irq = parseInt(cpuCols[6]) || 0;
                    let softirq = parseInt(cpuCols[7]) || 0;
                    let steal = parseInt(cpuCols[8]) || 0;
                    
                    // The Magic Fix: iowait must be grouped with idle!
                    let currentIdle = idle + iowait;
                    
                    // We purposefully ignore columns 9 and 10 to prevent double-counting
                    let currentNonIdle = user + nice + system + irq + softirq + steal;
                    let currentTotal = currentIdle + currentNonIdle;
                    
                    if (statsRoot.prevTotal > 0) {
                        let diffTotal = currentTotal - statsRoot.prevTotal;
                        let diffIdle = currentIdle - statsRoot.prevIdle;
                        
                        if (diffTotal > 0) {
                            let usage = Math.round(100 * (diffTotal - diffIdle) / diffTotal);
                            statsRoot.cpuUsage = Math.max(0, Math.min(100, usage)); 
                        }
                    }
                    
                    statsRoot.prevIdle = currentIdle;
                    statsRoot.prevTotal = currentTotal;
                }
                
                // --- 2. RAM CALCULATION ---
                let ramCols = parts[1].trim().split(/\s+/);
                if (ramCols.length >= 3 && ramCols[0] === "Mem:") {
                    let totalRam = parseInt(ramCols[1]) || 1;
                    let usedRam = parseInt(ramCols[2]) || 0;
                    statsRoot.ramUsage = Math.round((usedRam / totalRam) * 100);
                }
            }
        }
    }

    Timer {
        interval: 2000 
        running: true
        repeat: true
        onTriggered: statsProc.running = true
    }

    Component.onCompleted: statsProc.running = true

    // ==========================================
    // THE UI EXPORT
    // ==========================================
    
    RowLayout {
        id: contentLayout
        anchors.right: parent.right 
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        // 1. The Split Circular Gauge 
        Item {
            width: 40
            height: 40
            Layout.alignment: Qt.AlignVCenter

            Shape {
                anchors.fill: parent
                layer.enabled: true
                layer.samples: 4 

                // --- INACTIVE BACKGROUND: LEFT HALF (CPU) ---
                ShapePath {
                    strokeColor: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15) 
                    fillColor: "transparent"
                    strokeWidth: 6 
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: 20; centerY: 20
                        radiusX: 14; radiusY: 14
                        startAngle: 105
                        sweepAngle: 150 
                    }
                }

                // --- INACTIVE BACKGROUND: RIGHT HALF (RAM) ---
                ShapePath {
                    strokeColor: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)
                    fillColor: "transparent"
                    strokeWidth: 6 
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: 20; centerY: 20
                        radiusX: 14; radiusY: 14
                        startAngle: 75 
                        sweepAngle: -150 
                    }
                }

                // --- ACTIVE FOREGROUND: LEFT HALF (CPU) ---
                ShapePath {
                    strokeColor: Theme.main
                    fillColor: "transparent"
                    strokeWidth: 6 
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: 20; centerY: 20
                        radiusX: 14; radiusY: 14
                        startAngle: 105
                        
                        sweepAngle: 150 * (statsRoot.cpuUsage / 100)
                        
                        Behavior on sweepAngle {
                            NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                        }
                    }
                }

                // --- ACTIVE FOREGROUND: RIGHT HALF (RAM) ---
                ShapePath {
                    strokeColor: Theme.secondary
                    fillColor: "transparent"
                    strokeWidth: 6
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: 20; centerY: 20
                        radiusX: 14; radiusY: 14
                        startAngle: 75
                        
                        sweepAngle: -150 * (statsRoot.ramUsage / 100)
                        
                        Behavior on sweepAngle {
                            NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }

        // 2. The Stats Text 
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 0 

            Text {
                text: "CPU  " + statsRoot.cpuUsage + "%"
                font.family: Theme.fontMain    
                font.pixelSize: 10
                font.bold: true
                color: Theme.main
                Layout.alignment: Qt.AlignLeft 
            }

            Text {
                text: "RAM  " + statsRoot.ramUsage + "%"
                font.family: Theme.fontMain    
                font.pixelSize: 10
                font.bold: true
                color: Theme.secondary
                Layout.alignment: Qt.AlignLeft 
            }
        }
    }
}
