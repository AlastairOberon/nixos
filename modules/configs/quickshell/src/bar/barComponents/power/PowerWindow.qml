import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

import "../../../theme"
import "../../../theme/components"

PanelWindow {
    id: root

    visible: false
    color: "transparent"

    property var parentWindow: null
    screen: (parentWindow && parentWindow.screen) ? parentWindow.screen : null

    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Overlay

    width: contentRow.width
    height: contentRow.height

    function toggle() {
        visible = !visible;
    }

    function runPowerCommand(cmd) {
        root.visible = false;
        execProcess.command = ["bash", "-c", cmd];
        execProcess.running = true;
    }

    Process { 
        id: execProcess 
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 0 

        Repeater {
            model: [
                { name: "Lock", icon: "", isUrgent: false, cmd: "pidof hyprlock || hyprlock" },
                { name: "Screen Off", icon: "󰤄", isUrgent: false, cmd: "sleep 1 && hyprctl dispatch \"hl.dsp.dpms({ action = 'disable' })\"" },
                { name: "Log Out", icon: "󰍃", isUrgent: false, cmd: "hyprctl dispatch \"hl.dsp.exit()\"" },
                { name: "Restart", icon: "", isUrgent: true, cmd: "systemctl reboot" },
                { name: "Shut Down", icon: "", isUrgent: true, cmd: "systemctl poweroff" }
            ]

            delegate: ThemeButton {
                id: btnRoot

                // <--- SCALED SIZES (Increased by ~33%) --->
                // Kept the 1:2 ratio so the math for the pill ends stays flawless!
                width: 240
                height: 480  
                
                property color itemColor: (modelData.isUrgent ? Theme.urgent : Theme.secondary) || "#ff0000"
                property color baseColor: Theme.base || "#1e1e2e"

                color: "transparent"
                border.width: 0

                Rectangle {
                    anchors.fill: parent
                    color: btnRoot.isActive ? itemColor : baseColor
                    
                    topLeftRadius: index === 0 ? height / 2 : 0
                    bottomLeftRadius: index === 0 ? height / 2 : 0
                    
                    topRightRadius: index === 4 ? height / 2 : 0
                    bottomRightRadius: index === 4 ? height / 2 : 0
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                onClicked: root.runPowerCommand(modelData.cmd)

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 24 // <--- Increased spacing

                    Text {
                        text: modelData.icon
                        Layout.alignment: Qt.AlignHCenter
                        
                        font.family: Theme.fontIcon
                        font.pixelSize: 76 // <--- Increased icon size (was 56)
                        
                        color: btnRoot.isActive ? baseColor : btnRoot.itemColor

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        text: modelData.name
                        Layout.alignment: Qt.AlignHCenter
                        
                        font.family: Theme.fontMain 
                        font.pixelSize: 24 // <--- Increased text size (was 18)
                        font.bold: true
                        
                        color: btnRoot.isActive ? baseColor : (Theme.text || "#cdd6f4")

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }
        }
    }
}
