import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes 
import Quickshell
import Quickshell.Io 

import "../../../theme" 

Item {
    id: disksRoot
    
    Layout.preferredWidth: contentLayout.implicitWidth
    Layout.fillHeight: true

    property int rootUsage: 0
    property int dataUsage: 0

    Process {
        id: disksProc
        command: ["bash", "-c", "
            ROOT=$(df -P / | tail -1 | awk '{print $5}' | tr -d '%')
            DATA=$(df -P /mnt/data 2>/dev/null | tail -1 | awk '{print $5}' | tr -d '%')
            echo \"${ROOT:-0}|${DATA:-0}\"
        "]
        
        stdout: SplitParser {
            onRead: function(data) {
                let parts = data.trim().split('|');
                if (parts.length < 2) return;
                
                disksRoot.rootUsage = parseInt(parts[0]) || 0;
                disksRoot.dataUsage = parseInt(parts[1]) || 0;
            }
        }
    }

    Timer {
        interval: 5000 
        running: true
        repeat: true
        onTriggered: disksProc.running = true
    }

    Component.onCompleted: disksProc.running = true

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

                // --- INACTIVE BACKGROUND: LEFT HALF (ROOT) ---
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

                // --- INACTIVE BACKGROUND: RIGHT HALF (DATA) ---
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

                // --- ACTIVE FOREGROUND: LEFT HALF (ROOT) ---
                ShapePath {
                    strokeColor: Theme.font
                    fillColor: "transparent"
                    strokeWidth: 6 
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: 20; centerY: 20
                        radiusX: 14; radiusY: 14
                        startAngle: 105
                        
                        sweepAngle: 150 * (disksRoot.rootUsage / 100)
                        
                        Behavior on sweepAngle {
                            NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                        }
                    }
                }

                // --- ACTIVE FOREGROUND: RIGHT HALF (DATA) ---
                ShapePath {
                    strokeColor: Theme.font
                    fillColor: "transparent"
                    strokeWidth: 6
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: 20; centerY: 20
                        radiusX: 14; radiusY: 14
                        startAngle: 75
                        
                        sweepAngle: -150 * (disksRoot.dataUsage / 100)
                        
                        Behavior on sweepAngle {
                            NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }

        // 2. The Disk Stats Text 
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 0 

            Text {
                text: "ROOT  " + disksRoot.rootUsage + "%"
                font.family: Theme.fontMain    
                font.pixelSize: 10
                font.bold: true
                color: Theme.text // <--- Changed from Theme.main
                Layout.alignment: Qt.AlignLeft 
            }

            Text {
                text: "DATA  " + disksRoot.dataUsage + "%"
                font.family: Theme.fontMain    
                font.pixelSize: 10
                font.bold: true
                color: Theme.text // <--- Changed from Theme.secondary
                Layout.alignment: Qt.AlignLeft 
            }
        }
    }
}
