import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 
import Quickshell
import Quickshell.Services.Pipewire
import "../../" 
import "../" 

BlueprintPopup {
    id: audioPopup
    
    // --- 1. CONFIGURE THE BLUEPRINT ---
    popupWidth: 560 
    popupHeight: 440 
    isTopBar: true
    isSubMenu: true
    barOverlap: -120 
    
    timeoutDuration: 0 

    // Global state hooks
    property bool showInBar: true
    signal toggleShowInBar()

    // Clean Pipewire References
    property var masterSink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [ audioPopup.masterSink ] }

    // ==========================================
    // --- 2. SMART DECAY TIMER ---
    // ==========================================
    HoverHandler {
        id: submenuHover
    }

    Timer {
        id: decayTimer
        interval: 2500 
        running: audioPopup.visible && !submenuHover.hovered
        onTriggered: audioPopup.closeSilently() 
    }

    // ==========================================
    // --- 3. UI CONTENT ---
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        // --- FULL WIDTH VISIBILITY PILL TOGGLE ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42 // Bumped slightly for bigger text
            radius: height / 2 
            color: audioPopup.showInBar ? Theme.main : Theme.secondaryBase
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: audioPopup.showInBar ? "󰈈 Shown in Bar" : "󰈉 Hidden from Bar"
                font.bold: true
                font.pixelSize: 16 // Increased
                color: audioPopup.showInBar ? Theme.base : Theme.main
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: showInBarMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: audioPopup.toggleShowInBar()
            }
            
            Rectangle { 
                anchors.fill: parent 
                radius: height / 2 
                color: "#FFFFFF" 
                opacity: showInBarMouse.containsMouse ? 0.15 : 0 
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        // Horizontal Divider
        Rectangle { 
            Layout.fillWidth: true 
            height: 1 
            color: Theme.secondaryBase 
        }

        // --- MASTER VOLUME ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10 // Increased spacing for larger elements

            RowLayout {
                Layout.fillWidth: true
                
                Text { 
                    text: masterSink?.audio?.muted ? "󰖁" : "󰕾" 
                    color: masterSink?.audio?.muted ? Theme.urgent : Theme.text 
                    font.pixelSize: 22 // Increased icon size
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
                
                Text { 
                    Layout.fillWidth: true
                    text: masterSink ? (masterSink.properties["node.description"] || "Master Volume") : "Master Volume"
                    color: Theme.text; 
                    font.pixelSize: 17; // Increased text size
                    font.bold: true
                    elide: Text.ElideRight 
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
                
                Text { 
                    // Store the volume so we can easily check the 1.0 (100%) threshold
                    property real volValue: masterSink?.audio ? masterSink.audio.volume : 0
                    
                    text: Math.round(volValue * 100) + "%"
                    
                    // THE FIX: Color matches the active slider color precisely!
                    color: volValue > 1.00 ? Theme.secondary : Theme.main
                    
                    font.pixelSize: 15 // Increased text size
                    font.bold: true
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Master Mute Button
                Rectangle {
                    width: 36; height: 36; radius: 8 // Increased button size
                    color: masterSink?.audio?.muted ? Theme.urgent : Theme.secondaryBase
                    Behavior on color { ColorAnimation { duration: 150 } } 
                    
                    Text { 
                        anchors.centerIn: parent
                        text: masterSink?.audio?.muted ? "󰖁" : "󰕾"
                        color: masterSink?.audio?.muted ? Theme.base : Theme.text
                        font.pixelSize: 18 // Increased icon size
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    MouseArea {
                        id: masterMuteMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (masterSink?.audio) {
                                masterSink.audio.muted = !masterSink.audio.muted;
                            }
                        }
                    }
                    
                    Rectangle { 
                        anchors.fill: parent; radius: 8; color: "#FFFFFF" 
                        opacity: masterMuteMouse.containsMouse ? 0.1 : 0 
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }

                // Master Slider
                VolumeSlider {
                    Layout.fillWidth: true
                    value: masterSink?.audio ? masterSink.audio.volume : 0
                    onMoved: (val) => {
                        if (masterSink?.audio) {
                            masterSink.audio.volume = val;
                            if (val > 0 && masterSink.audio.muted) masterSink.audio.muted = false;
                        }
                    }
                }
            }
        }

        // Horizontal Divider
        Rectangle { 
            Layout.fillWidth: true 
            height: 1 
            color: Theme.secondaryBase 
        }

        Text { 
            text: "Application Mixer"
            color: Theme.text
            font.bold: true 
            font.pixelSize: 15 // Increased section header size
        }

        // --- INDIVIDUAL APP STREAMS ---
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            contentWidth: availableWidth 

            ColumnLayout {
                width: parent.width
                spacing: 20 // Increased gap between app rows

                Repeater {
                    model: Pipewire.nodes

                    delegate: ColumnLayout {
                        id: appRow
                        Layout.fillWidth: true
                        
                        property bool isAppStream: modelData && modelData.properties && modelData.properties["media.class"] === "Stream/Output/Audio"
                        property string appName: isAppStream ? (modelData.properties["application.name"] || modelData.properties["node.name"] || "Unknown App") : ""
                        
                        visible: isAppStream
                        Layout.preferredHeight: visible ? implicitHeight : 0

                        PwObjectTracker { objects: [modelData] }

                        RowLayout {
                            Layout.fillWidth: true
                            
                            Text { 
                                Layout.fillWidth: true
                                text: appRow.appName
                                color: Theme.text; // Changed from inactive to text so it's easier to read
                                font.pixelSize: 15 // Increased text size
                                font.bold: true
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                            
                            Text { 
                                property real appVolValue: modelData?.audio ? modelData.audio.volume : 0
                                
                                text: Math.round(appVolValue * 100) + "%"
                                
                                // THE FIX: App percentages also change color when driven past 100%!
                                color: appVolValue > 1.00 ? Theme.secondary : Theme.main
                                
                                font.pixelSize: 14 // Increased text size
                                font.bold: true
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            // App Mute Button
                            Rectangle {
                                width: 32; height: 32; radius: 6 // Increased button size
                                color: modelData?.audio?.muted ? Theme.urgent : Theme.secondaryBase
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Text { 
                                    anchors.centerIn: parent
                                    text: modelData?.audio?.muted ? "󰖁" : "󰕾"
                                    color: modelData?.audio?.muted ? Theme.base : Theme.text
                                    font.pixelSize: 16 // Increased icon size
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                
                                MouseArea {
                                    id: appMuteMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData?.audio) {
                                            modelData.audio.muted = !modelData.audio.muted;
                                        }
                                    }
                                }
                                
                                Rectangle { 
                                    anchors.fill: parent; radius: 6; color: "#FFFFFF" 
                                    opacity: appMuteMouse.containsMouse ? 0.1 : 0 
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }
                            }

                            // App Slider
                            VolumeSlider {
                                Layout.fillWidth: true
                                value: modelData?.audio ? modelData.audio.volume : 0
                                onMoved: (val) => {
                                    if (modelData?.audio) {
                                        modelData.audio.volume = val;
                                        if (val > 0 && modelData.audio.muted) modelData.audio.muted = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
