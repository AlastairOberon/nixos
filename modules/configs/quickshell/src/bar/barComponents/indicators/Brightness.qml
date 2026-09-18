import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io 

import "../../../theme" 

Item {
    id: brightRoot
    
    Layout.preferredWidth: contentLayout.implicitWidth + 16
    Layout.preferredHeight: 30
    Layout.fillHeight: true

    property bool isActive: typeof myLauncher !== "undefined" && 
                            myLauncher.window && 
                            myLauncher.window.visible && 
                            myLauncher.window.currentTabIndex === 11

    property int brightness: 0

    // Process to change brightness when scrolling the mouse wheel
    Process { 
        id: adjustProc 
    }

    // Process to fetch current brightness
    Process {
        id: brightStats
        command: ["bash", "-c", "brightnessctl i -m | awk -F, '{print int($4)}'"]
        
        stdout: SplitParser {
            onRead: function(data) {
                let val = parseInt(data.trim());
                if (!isNaN(val)) {
                    brightRoot.brightness = val;
                }
            }
        }
    }

    Timer {
        interval: 500 
        running: true
        repeat: true
        onTriggered: brightStats.running = true
    }

    Component.onCompleted: brightStats.running = true

    // The Highlight Pill Background
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: brightRoot.isActive ? Theme.secondary : (brightMouseArea.containsMouse ? Theme.urgent : "transparent")
        
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }

    // ==========================================
    // THE UI EXPORT
    // ==========================================
    
    RowLayout {
        id: contentLayout
        anchors.centerIn: parent
        spacing: 8

        // 1. Dynamic Brightness Icon
        Text {
            id: brightIcon
            text: {
                if (brightRoot.brightness < 33) return "󰃞";      // Low brightness
                if (brightRoot.brightness < 66) return "󰃟";      // Medium brightness
                return "󰃠";                                      // High brightness
            }
            
            font.family: Theme.fontIcon    
            font.pixelSize: 18
            Layout.alignment: Qt.AlignVCenter
            
            color: (brightRoot.isActive || brightMouseArea.containsMouse) ? Theme.base : Theme.text
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // 2. Brightness Percentage Text
        Text {
            text: brightRoot.brightness + "%"
            
            font.family: Theme.fontMain    
            font.pixelSize: 10
            font.bold: true
            Layout.alignment: Qt.AlignVCenter 
            
            color: (brightRoot.isActive || brightMouseArea.containsMouse) ? Theme.base : Theme.text
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    // Hover, Scroll & Click Effects
    MouseArea {
        id: brightMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            if (typeof myLauncher !== "undefined" && myLauncher.window) {
                if (brightRoot.isActive) {
                    myLauncher.window.visible = false;
                } else {
                    myLauncher.window.visible = true;
                    myLauncher.window.currentTabIndex = 11;
                }
            }
        }

        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                adjustProc.command = ["brightnessctl", "set", "5%+"];
            } else {
                adjustProc.command = ["brightnessctl", "set", "5%-"];
            }
            adjustProc.running = true;
            brightStats.running = true; 
        }
    }
}
