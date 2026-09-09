import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland 
import ".." 

PanelWindow {
    id: root
    visible: false
    color: "transparent"

    property var parentWindow: null
    screen: parentWindow ? parentWindow.screen : null

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shortcuts-menu" 
    exclusiveZone: -1 

    function toggle() {
        if (visible) {
            closeAnim.start();
        } else {
            visible = true;
            openAnim.start();
        }
    }

    // ==========================================
    // --- 1. THE BLURRED BACKDROP ---
    // ==========================================
    Rectangle {
        id: backdrop
        anchors.fill: parent
        
        property real bgAlpha: 0.0 
        color: Qt.rgba(0, 0, 0, bgAlpha) 

        MouseArea {
            anchors.fill: parent
            onClicked: root.toggle()
        }
    }

    // ==========================================
    // --- 2. THE FLOATING ISLAND ---
    // ==========================================
    Rectangle {
        id: island
        width: 1300 
        height: 820
        anchors.centerIn: parent
        
        radius: 24
        color: Theme.base
        border.color: Theme.bridge
        border.width: 1
        
        opacity: 0.0

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 40
            spacing: 30
            
            // Header
            Text {
                text: "Hyprland Shortcuts"
                color: Theme.text
                font.pixelSize: 28 
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            // Divider Line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.bridge
            }

            // ==========================================
            // --- 3. TWO-COLUMN GRID LAYOUT ---
            // ==========================================
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                flow: GridLayout.TopToBottom 
                rows: 11 
                columnSpacing: 50
                rowSpacing: 22 
                
                Repeater {
                    model: [
                        // --- APPLICATIONS & SYSTEM ---
                        { keys: ["", "󰌑 Enter"], action: "Open Terminal (Ghostty)" },
                        { keys: ["", "E"], action: "File Manager (Thunar)" },
                        { keys: ["", "󱁐 Space"], action: "App Launcher (Rofi)" },
                        { keys: ["", "C"], action: "Emoji Picker" },
                        { keys: ["", "V"], action: "Clipboard History" },
                        { keys: ["", "󰘴 Ctrl", "L"], action: "Lock Screen" },
                        
                        // --- WINDOW MANAGEMENT ---
                        { keys: ["", "Q"], action: "Close Active Window" },
                        { keys: ["", "F"], action: "Toggle Floating" },
                        { keys: ["", "P"], action: "Promote / Pseudo Tile" },
                        { keys: ["", "󰘶 Shift", "J"], action: "Toggle Split Direction" },
                        
                        // --- SCREENSHOTS ---
                        { keys: ["", "Print"], action: "Screenshot Output" },
                        { keys: ["", "󰘴 Ctrl", "Print"], action: "Screenshot Window" },
                        { keys: ["", "󰘶 Shift", "Print"], action: "Screenshot Region" },
                        
                        // --- NAVIGATION & WORKSPACES ---
                        { keys: ["", "1-0"], action: "Switch to Workspace 1-10" },
                        { keys: ["", "󰘶 Shift", "1-0"], action: "Move Window to Workspace" },
                        { keys: ["", "S"], action: "Toggle Special Workspace (Magic)" },
                        { keys: ["", "󰌒 Tab"], action: "Next Workspace" },
                        { keys: ["", "󰘶 Shift", "󰌒 Tab"], action: "Previous Workspace" },
                        
                        // --- COLUMN / LAYOUT CONTROLS ---
                        { keys: ["", " / "], action: "Focus Window Direction" },
                        { keys: ["", " / "], action: "Move Viewport Columns" },
                        { keys: ["", "[ / ]"], action: "Resize Columns" }
                    ]
                    
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: 20

                        property var keyArray: modelData.keys 

                        // 1. THE KEYCAPS CONTAINER
                        // THE FIX: Replaced RowLayout with a fixed Item and a standard Row
                        // This stops the keys from stretching apart!
                        Item {
                            Layout.preferredWidth: 320 
                            Layout.preferredHeight: 38

                            Row {
                                // Right-aligns the keys so they look clean against the text
                                anchors.right: parent.right 
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                Repeater {
                                    model: keyArray
                                    delegate: Row {
                                        spacing: 12
                                        
                                        // Individual Keycap Box
                                        Rectangle {
                                            width: keyText.implicitWidth + 24
                                            height: 38
                                            
                                            // THE FIX: Added a translucent white fill and a clear border
                                            // so it always looks like a physical button on any theme!
                                            color: Qt.rgba(255, 255, 255, 0.05) 
                                            border.color: Theme.main 
                                            border.width: 1
                                            radius: 8
                                            
                                            Text {
                                                id: keyText
                                                anchors.centerIn: parent
                                                text: modelData
                                                color: Theme.main
                                                font.pixelSize: 16 
                                                font.bold: true
                                            }
                                        }

                                        // The "+" Sign 
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "+"
                                            color: Theme.text
                                            opacity: 0.4
                                            font.pixelSize: 18
                                            font.bold: true
                                            visible: index < (keyArray.length - 1)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 2. THE DESCRIPTION
                        Text {
                            Layout.fillWidth: true
                            text: modelData.action
                            color: Theme.text
                            font.pixelSize: 19 
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // --- 4. CINEMATIC ANIMATIONS ---
    // ==========================================
    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: backdrop; property: "bgAlpha"; from: 0.0; to: 0.4; duration: 250; easing.type: Easing.OutCubic }
        NumberAnimation { target: island; property: "opacity"; from: 0.0; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation { target: backdrop; property: "bgAlpha"; from: 0.4; to: 0.0; duration: 200; easing.type: Easing.InCubic }
        NumberAnimation { target: island; property: "opacity"; from: 1.0; to: 0.0; duration: 200; easing.type: Easing.InCubic }
        onFinished: root.visible = false
    }
}
