import QtQuick
import QtQuick.Layouts
import Quickshell.Io

import "../../../theme"

Item {
    id: visRoot
    
    Layout.preferredWidth: (6 * 3) + (4 * 2) + 16
    Layout.preferredHeight: 30
    Layout.fillHeight: true

    property bool isActive: typeof myLauncher !== "undefined" && 
                            myLauncher.window && 
                            myLauncher.window.visible && 
                            myLauncher.window.currentTabIndex === 4

    property real val0: 0
    property real val1: 0
    property real val2: 0

    property bool isPlaying: (val0 > 0 || val1 > 0 || val2 > 0)

    function getBarColor(val) {
        let ratio = Math.max(0.0, Math.min(1.0, val / 100.0));
        let r = Theme.main.r * (1 - ratio) + Theme.secondary.r * ratio;
        let g = Theme.main.g * (1 - ratio) + Theme.secondary.g * ratio;
        let b = Theme.main.b * (1 - ratio) + Theme.secondary.b * ratio;
        
        return Qt.rgba(r, g, b, 1.0);
    }

    // 1. The Safety Timer
    Timer {
        interval: 800
        running: true
        repeat: false
        onTriggered: cavaProcess.running = true
    }

    // 2. The Audio Engine
    Process {
        id: cavaProcess
        running: false 
        
        command: [
            "bash", 
            "-c", 
            "printf '[general]\nframerate=30\nbars=3\n[output]\nchannels=mono\nmethod=raw\nraw_target=/dev/stdout\ndata_format=ascii\nascii_max_range=100\n' > /tmp/qcava.conf && cava -p /tmp/qcava.conf"
        ]
        
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(';');
                if (parts.length >= 3) {
                    visRoot.val0 = parseInt(parts[0]) || 0;
                    visRoot.val1 = parseInt(parts[1]) || 0;
                    visRoot.val2 = parseInt(parts[2]) || 0;
                }
            }
        }

        stderr: SplitParser {
            onRead: data => console.log("[CAVA FATAL ERROR]:", data)
        }
    }

    // Highlight pill background
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: visRoot.isActive ? Theme.secondary : (visMouseArea.containsMouse ? Theme.urgent : "transparent")
        
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }

    // 3. The 3 Bars
    RowLayout {
        anchors.centerIn: parent
        height: 24
        spacing: 4

        // Bar 1
        Rectangle {
            Layout.preferredWidth: 6
            Layout.preferredHeight: visRoot.isPlaying ? Math.max(6, (visRoot.val0 / 100.0) * 24) : 6
            Layout.alignment: Qt.AlignVCenter
            radius: width / 2
            
            color: (visRoot.isActive || visMouseArea.containsMouse) ? Theme.base : (visRoot.isPlaying ? visRoot.getBarColor(visRoot.val0) : "transparent")
            border.color: (visRoot.isActive || visMouseArea.containsMouse) ? Theme.base : (visRoot.isPlaying ? visRoot.getBarColor(visRoot.val0) : Theme.main)
            border.width: 1
            
            Behavior on Layout.preferredHeight { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }
        }

        // Bar 2
        Rectangle {
            Layout.preferredWidth: 6
            Layout.preferredHeight: visRoot.isPlaying ? Math.max(6, (visRoot.val1 / 100.0) * 24) : 6
            Layout.alignment: Qt.AlignVCenter
            radius: width / 2
            
            color: (visRoot.isActive || visMouseArea.containsMouse) ? Theme.base : (visRoot.isPlaying ? visRoot.getBarColor(visRoot.val1) : "transparent")
            border.color: (visRoot.isActive || visMouseArea.containsMouse) ? Theme.base : (visRoot.isPlaying ? visRoot.getBarColor(visRoot.val1) : Theme.main)
            border.width: 1
            
            Behavior on Layout.preferredHeight { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }
        }

        // Bar 3
        Rectangle {
            Layout.preferredWidth: 6
            Layout.preferredHeight: visRoot.isPlaying ? Math.max(6, (visRoot.val2 / 100.0) * 24) : 6
            Layout.alignment: Qt.AlignVCenter
            radius: width / 2
            
            color: (visRoot.isActive || visMouseArea.containsMouse) ? Theme.base : (visRoot.isPlaying ? visRoot.getBarColor(visRoot.val2) : "transparent")
            border.color: (visRoot.isActive || visMouseArea.containsMouse) ? Theme.base : (visRoot.isPlaying ? visRoot.getBarColor(visRoot.val2) : Theme.main)
            border.width: 1
            
            Behavior on Layout.preferredHeight { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }
        }
    }

    MouseArea {
        id: visMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (typeof myLauncher !== "undefined" && myLauncher.window) {
                if (visRoot.isActive) {
                    myLauncher.window.visible = false;
                } else {
                    myLauncher.window.visible = true;
                    myLauncher.window.currentTabIndex = 4;
                }
            }
        }
    }
}
