import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io 

import "../../../../theme" 
import "../../../../theme/components" 

Item {
    id: monitorRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    ListModel { id: monitorModel }

    // ==========================================
    // BACKEND: FETCH HYPRLAND MONITORS
    // ==========================================
    Process {
        id: fetchMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(this.text);
                    monitorModel.clear();
                    
                    for (let i = 0; i < parsed.length; i++) {
                        let m = parsed[i];
                        monitorModel.append({
                            monName: m.name,
                            monDesc: m.description,
                            w: m.width,
                            h: m.height,
                            rr: Math.round(m.refreshRate),
                            
                            qsScale: Theme.getMonitorScale(m.name), 
                            
                            brightness: 100 
                        });
                    }
                } catch (e) {
                    console.log("Monitor JSON Parse Error: " + e.message);
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            fetchMonitors.running = true;
        }
    }

    // ==========================================
    // UI LAYOUT
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Metrics.spacingLarge
        spacing: Metrics.spacingLarge

        // --- HEADER ---
        Text {
            text: "Monitor Configuration"
            color: Theme.main
            font.family: Theme.fontMain
            font.pixelSize: 18
            font.weight: Font.Bold
        }

        // --- HYPRLAND MONITORS LIST ---
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: Metrics.spacingLarge 

                Repeater {
                    model: monitorModel
                    
                    delegate: Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 110
                        clip: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8

                            // 1. Monitor Header
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "\uf108"; color: Theme.main; font.family: Theme.fontIcon; font.pixelSize: 20 }
                                Text { 
                                    text: model.monName + "  —  " + model.w + "x" + model.h + " @ " + model.rr + "Hz"
                                    color: Theme.text
                                    font.family: Theme.fontMain
                                    font.pixelSize: 15
                                    font.weight: Font.Bold 
                                    Layout.fillWidth: true
                                }
                            }

                            // 2. Brightness Slider
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 15
                                Text { text: "\uf185"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7); font.family: Theme.fontIcon; font.pixelSize: 14 }
                                
                                Slider {
                                    id: brightSlider
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32 
                                    from: 5
                                    to: 100
                                    value: model.brightness
                                    
                                    Process {
                                        id: brightnessProcess
                                        onExited: running = false
                                    }

                                    onPressedChanged: {
                                        if (!pressed) {
                                            brightnessProcess.running = false;
                                            let val = Math.round(value);
                                            let cmd = "";
                                            
                                            // Laptops
                                            if (model.monName.indexOf("eDP") !== -1) {
                                                cmd = "brightnessctl set " + val + "%";
                                            } 
                                            // External Monitors
                                            else {
                                                cmd = "ddcutil setvcp 10 " + val + " --display " + (index + 1);
                                            }
                                            
                                            brightnessProcess.command = ["bash", "-c", cmd];
                                            brightnessProcess.running = true;
                                        }
                                    }
                                    
                                    background: Rectangle {
                                        x: brightSlider.leftPadding
                                        y: brightSlider.topPadding + brightSlider.availableHeight / 2 - height / 2
                                        width: brightSlider.availableWidth
                                        height: 24 
                                        radius: 12
                                        color: Qt.rgba(1, 1, 1, 0.15)

                                        Rectangle {
                                            width: brightSlider.visualPosition * parent.width
                                            height: parent.height
                                            radius: 12
                                            color: Theme.main
                                        }
                                    }

                                    handle: Item {}
                                }
                                
                                Text { 
                                    text: Math.round(parent.children[1].value) + "%"
                                    color: Theme.text
                                    font.family: Theme.fontMain
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                    Layout.minimumWidth: 40 
                                }
                            }

                            // 3. Quickshell UI Scaling Controls
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 15
                                
                                Text { text: "Quickshell Scale:"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7); font.family: Theme.fontMain; font.pixelSize: 14 }
                                
                                Item { Layout.fillWidth: true } 

                                Rectangle {
                                    width: 26; height: 26; radius: 13
                                    color: "transparent"
                                    border.width: 1
                                    border.color: qsScaleMinus.containsMouse ? Theme.secondary : Theme.bridge
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    
                                    Text { anchors.centerIn: parent; text: "-"; color: qsScaleMinus.containsMouse ? Theme.base : Theme.text; font.pixelSize: 16; font.weight: Font.Bold }
                                    
                                    MouseArea { 
                                        id: qsScaleMinus; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (model.qsScale > 0.5) {
                                                let newScale = model.qsScale - 0.1;
                                                monitorModel.setProperty(index, "qsScale", newScale);
                                                applyQuickshellScale(model.monName, newScale);
                                            }
                                        }
                                    }
                                }
                                
                                Text { 
                                    text: model.qsScale.toFixed(2) + "x"
                                    color: Theme.text
                                    font.family: Theme.fontMain
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                    Layout.minimumWidth: 40
                                    horizontalAlignment: Text.AlignHCenter 
                                }
                                
                                Rectangle {
                                    width: 26; height: 26; radius: 13
                                    color: "transparent"
                                    border.width: 1
                                    border.color: qsScalePlus.containsMouse ? Theme.main : Theme.bridge
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    
                                    Text { anchors.centerIn: parent; text: "+"; color: qsScalePlus.containsMouse ? Theme.base : Theme.text; font.pixelSize: 16; font.weight: Font.Bold }
                                    
                                    MouseArea { 
                                        id: qsScalePlus; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (model.qsScale < 3.0) {
                                                let newScale = model.qsScale + 0.1;
                                                monitorModel.setProperty(index, "qsScale", newScale);
                                                applyQuickshellScale(model.monName, newScale);
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Spacer Line Between Monitors
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                Layout.topMargin: 10
                                color: Theme.bridge
                                opacity: 0.4
                            }
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // HELPER FUNCTIONS & SAVING LOGIC
    // ==========================================
    
    Process {
        id: saveConfigProcess
        onExited: running = false
    }

    Timer {
        id: restartDebounceTimer
        interval: 600
        repeat: false
        onTriggered: {
            let script = "assets/launch_quickshell.sh 2>/dev/null || ~/.config/quickshell/assets/launch_quickshell.sh 2>/dev/null || /etc/nixos/modules/configs/quickshell/src/assets/launch_quickshell.sh";
            saveConfigProcess.command = ["bash", "-c", script];
            saveConfigProcess.running = true;
        }
    }

    function applyQuickshellScale(monitorName, scaleValue) {
        Settings.setMonitorScale(monitorName, scaleValue);
        Theme.setMonitorScale(monitorName, scaleValue);
        restartDebounceTimer.restart();
    }
}
