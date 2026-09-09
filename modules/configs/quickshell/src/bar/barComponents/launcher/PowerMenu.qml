import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io 

import "../../../theme" 
import "../../../theme/components" 

Item {
    id: powerRoot
    
    property int currentIndex: -1
    
    // Model updated to include descriptions
    property var powerModel: [
        { name: "Lock", desc: "Secure the current session", icon: "", isUrgent: false, cmd: "pidof hyprlock || hyprlock" },
        { name: "Screen Off", desc: "Turn off the displays to save power", icon: "󰤄", isUrgent: false, cmd: "sleep 1 && hyprctl dispatch \"hl.dsp.dpms({ action = 'disable' })\"" },
        { name: "Log Out", desc: "End your session and return to the greeter", icon: "󰍃", isUrgent: false, cmd: "hyprctl dispatch \"hl.dsp.exit()\"" },
        { name: "Restart", desc: "Reboot the computer entirely", icon: "", isUrgent: true, cmd: "systemctl reboot" },
        { name: "Shut Down", desc: "Power off the computer", icon: "", isUrgent: true, cmd: "systemctl poweroff" }
    ]

    // Automatically resets focus when you switch to this tab
    onVisibleChanged: {
        if (visible) {
            currentIndex = -1
            powerRoot.forceActiveFocus()
        }
    }

    Process { 
        id: execProcess 
    }

    function runPowerCommand(cmd) {
        console.log("Executing Power Command: " + cmd)
        execProcess.command = ["bash", "-c", cmd];
        execProcess.running = true;
        
        let p = powerRoot;
        while (p && !p.focusable) p = p.parent;
        if (p) p.visible = false;
    }

    // Keyboard navigation mapped to the root item
    Keys.onDownPressed: {
        if (currentIndex < powerModel.length - 1) {
            currentIndex++;
        }
    }
    Keys.onUpPressed: {
        if (currentIndex > 0) {
            currentIndex--;
        }
    }
    Keys.onReturnPressed: {
        const targetIndex = currentIndex >= 0 ? currentIndex : 0;
        const currentAction = powerModel[targetIndex];
        if (currentAction) powerRoot.runPowerCommand(currentAction.cmd);
    }
    Keys.onEscapePressed: {
        let p = powerRoot;
        while (p && !p.focusable) p = p.parent;
        if (p) p.visible = false;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Metrics.spacingLarge
        anchors.topMargin: Metrics.spacingLarge
        anchors.bottomMargin: Metrics.spacingLarge

        // --- HEADER ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Metrics.spacingLarge
            Layout.rightMargin: Metrics.spacingLarge
            spacing: 8

            Text {
                text: "Power Menu"
                color: Theme.main
                font.family: Theme.fontMain
                font.pixelSize: 14
                font.weight: Font.Bold
            }
        }

        // --- POWER ACTION LIST ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true 
            spacing: Metrics.spacingSmall
            Layout.leftMargin: Metrics.spacingLarge
            Layout.rightMargin: Metrics.spacingLarge
            Layout.topMargin: 10
            Layout.bottomMargin: 20
            
            Repeater {
                model: powerRoot.powerModel
                
                delegate: ThemeButton {
                    id: delegateRoot 
                    required property int index
                    required property var modelData
                    
                    // This is the magic! It stretches to fill the vertical space evenly
                    Layout.fillWidth: true
                    Layout.fillHeight: true 
                    
                    selected: powerRoot.currentIndex === index
                    
                    property color actionColor: modelData.isUrgent ? Theme.urgent : Theme.secondary
                    
                    color: delegateRoot.isActive ? actionColor : "transparent"
                    border.width: 0
                    border.color: "transparent"
                    
                    HoverHandler {
                        onHoveredChanged: { if (hovered) powerRoot.currentIndex = index }
                    }
                    
                    onClicked: { powerRoot.runPowerCommand(modelData.cmd) }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingBase
                        spacing: Metrics.spacingLarge

                        // --- ICON ---
                        Text {
                            text: modelData.icon
                            font.family: Theme.fontIcon
                            font.pixelSize: 36
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 60 
                            horizontalAlignment: Text.AlignHCenter
                            
                            color: delegateRoot.isActive ? Theme.base : delegateRoot.actionColor
                            Behavior on color { ColorAnimation { duration: Metrics.animBase } }
                        }

                        // --- TEXT BLOCK ---
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            Text {
                                text: modelData.name
                                color: delegateRoot.isActive ? Theme.base : Theme.text
                                font.family: Theme.fontMain   
                                font.pixelSize: 22   
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: Metrics.animBase } }
                            }

                            Text {
                                text: modelData.desc
                                color: delegateRoot.isActive ? Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.7) : Qt.lighter(Theme.text, 1.5)
                                font.family: Theme.fontMain   
                                font.pixelSize: 15   
                                Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: Metrics.animBase } }
                            }
                        }
                    }
                }
            }
        }
    }
}
