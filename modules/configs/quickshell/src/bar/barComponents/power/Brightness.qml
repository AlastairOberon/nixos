import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io 

import "../../../theme" 

Item {
    id: brightRoot
    
    // Allows the Bar's RowLayout to size this component correctly
    Layout.preferredWidth: contentLayout.implicitWidth
    Layout.fillHeight: true

    property int brightness: 0

    // Process to change brightness when scrolling the mouse wheel
    Process { 
        id: adjustProc 
    }

    // Process to fetch current brightness
    Process {
        id: brightStats
        // brightnessctl -m outputs CSV format.
        // awk -F, '{print int($4)}' grabs the 4th column (e.g. "50%") and strips the % sign
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
        // Polling twice a second keeps it snappy, especially when scrolling
        interval: 500 
        running: true
        repeat: true
        onTriggered: brightStats.running = true
    }

    Component.onCompleted: brightStats.running = true

    // ==========================================
    // THE UI EXPORT
    // ==========================================
    
    RowLayout {
        id: contentLayout
        anchors.right: parent.right 
        anchors.verticalCenter: parent.verticalCenter
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
            
            color: brightMouseArea.containsMouse ? Theme.main : Theme.text
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // 2. Brightness Percentage Text
        Text {
            text: brightRoot.brightness + "%"
            
            font.family: Theme.fontMain    
            font.pixelSize: 10 // Matched to your Volume and Stats text sizes
            font.bold: true
            Layout.alignment: Qt.AlignVCenter 
            
            color: brightMouseArea.containsMouse ? Theme.main : Theme.text
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    // Hover & Scroll Effects
    MouseArea {
        id: brightMouseArea
        anchors.fill: parent
        hoverEnabled: true
        
        // Allows you to scroll up/down on the widget to change brightness!
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                // Scrolled up
                adjustProc.command = ["brightnessctl", "set", "5%+"];
            } else {
                // Scrolled down
                adjustProc.command = ["brightnessctl", "set", "5%-"];
            }
            adjustProc.running = true;
            
            // Force an immediate UI update so it doesn't wait for the timer tick
            brightStats.running = true; 
        }
    }
}
