import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire

import "../../../theme" 
import "../../../theme/components" 

ColumnLayout {
    id: audioRoot

    property var masterSink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [ audioRoot.masterSink ] }

    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Metrics.spacingLarge
    anchors.margins: Metrics.spacingLarge

    // --- HEADER ---
    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "Audio & Volume Controls"
            color: Theme.main
            font.family: Theme.fontMain
            font.pixelSize: 18
            font.weight: Font.Bold
        }
    }

    // --- MASTER VOLUME ENTRY ---
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 85 // Adjusted height without the card background

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: masterSink?.audio?.muted ? "\uf6a9" : "\uf028" 
                    color: masterSink?.audio?.muted ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4) : Theme.main
                    font.family: Theme.fontIcon
                    font.pixelSize: 18
                }
                Text {
                    text: masterSink ? (masterSink.properties["node.description"] || "Master Output") : "Master Output"
                    color: Theme.text
                    font.family: Theme.fontMain
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    property real volValue: masterSink?.audio ? masterSink.audio.volume : 0
                    text: masterSink?.audio?.muted ? "Muted" : (Math.round(volValue * 100) + "%")
                    color: volValue > 1.00 ? Theme.secondary : Theme.main
                    font.family: Theme.fontMain
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }
                Button {
                    implicitWidth: 32
                    implicitHeight: 32
                    background: Rectangle {
                        color: "transparent"
                        radius: 16
                        border.color: hoverHandler.hovered ? Theme.main : Theme.bridge
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }
                    
                    HoverHandler { id: hoverHandler }
                    
                    contentItem: Text {
                        text: masterSink?.audio?.muted ? "\uf6a9" : "\uf028"
                        color: masterSink?.audio?.muted ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5) : Theme.main
                        font.family: Theme.fontIcon
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (masterSink?.audio) {
                            masterSink.audio.muted = !masterSink.audio.muted;
                        }
                    }
                }
            }

            Slider {
                id: masterSlider
                Layout.fillWidth: true
                Layout.preferredHeight: 32 // Gives plenty of clickable area
                from: 0.0
                to: 2.0 
                value: masterSink?.audio ? masterSink.audio.volume : 0.0
                // THE FIX: Check that the audio interface actually exists before checking if it is muted
                enabled: masterSink?.audio ? !masterSink.audio.muted : false
                
                onMoved: {
                    if (masterSink?.audio) {
                        masterSink.audio.volume = value;
                        if (value > 0 && masterSink.audio.muted) masterSink.audio.muted = false;
                    }
                }

                background: Rectangle {
                    x: masterSlider.leftPadding
                    y: masterSlider.topPadding + masterSlider.availableHeight / 2 - height / 2
                    width: masterSlider.availableWidth
                    height: 24 // Taller, thicker track
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.15)

                    // 100% Marker Notch
                    Rectangle {
                        x: (parent.width / 2.0) - (width / 2)
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 24
                        radius: 1
                        color: Theme.base
                        opacity: 0.6
                        z: 1
                    }

                    Rectangle {
                        width: masterSlider.visualPosition * parent.width
                        height: parent.height
                        radius: 12
                        color: (masterSink?.audio?.volume ?? 0) > 1.0 ? Theme.secondary : Theme.main
                        z: 2
                    }
                }

                // Completely removes the visible circle handle while keeping it functional
                handle: Item {}
            }
        }
    }

    // Spacer Line Below Master
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Theme.bridge
        opacity: 0.4
    }

    // --- APPLICATIONS & STREAMS SECTION ---
    Text {
        text: "Applications & Streams"
        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
        font.family: Theme.fontMain
        font.pixelSize: 13
        font.weight: Font.Bold
        Layout.topMargin: 4
    }

    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: sourcesColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: sourcesColumn
            width: parent.width
            spacing: Metrics.spacingLarge // Increased spacing to account for removed backgrounds

            Repeater {
                model: Pipewire.nodes

                delegate: Item {
                    required property var modelData
                    
                    property bool isAppStream: modelData && modelData.properties && modelData.properties["media.class"] === "Stream/Output/Audio"
                    property string appName: isAppStream ? (modelData.properties["application.name"] || modelData.properties["node.name"] || "Unknown App") : ""
                    
                    visible: isAppStream
                    Layout.preferredHeight: visible ? 85 : 0
                    Layout.fillWidth: true
                    clip: true

                    PwObjectTracker { objects: [modelData] }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 6
                        visible: parent.visible

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: modelData?.audio?.muted ? "\uf6a9" : "\uf001"
                                color: modelData?.audio?.muted ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4) : ((modelData?.audio?.volume ?? 0) > 1.0 ? Theme.secondary : Theme.main)
                                font.family: Theme.fontIcon
                                font.pixelSize: 16
                            }
                            Text {
                                text: appName
                                color: Theme.text
                                font.family: Theme.fontMain
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                property real appVolValue: modelData?.audio ? modelData.audio.volume : 0
                                text: modelData?.audio?.muted ? "Muted" : (Math.round(appVolValue * 100) + "%")
                                color: appVolValue > 1.00 ? Theme.secondary : Theme.main
                                font.family: Theme.fontMain
                                font.pixelSize: 13
                                font.weight: Font.Bold
                            }
                            Button {
                                implicitWidth: 28
                                implicitHeight: 28
                                background: Rectangle {
                                    color: "transparent"
                                    radius: 14
                                    border.color: appHoverHandler.hovered ? Theme.main : Theme.bridge
                                    border.width: 1
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                }
                                
                                HoverHandler { id: appHoverHandler }
                                
                                contentItem: Text {
                                    text: modelData?.audio?.muted ? "\uf6a9" : "\uf028"
                                    color: modelData?.audio?.muted ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5) : Theme.main
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: {
                                    if (modelData?.audio) {
                                        modelData.audio.muted = !modelData.audio.muted;
                                    }
                                }
                            }
                        }

                        Slider {
                            id: streamSlider
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32 
                            from: 0.0
                            to: 2.0 
                            value: modelData?.audio ? modelData.audio.volume : 0.0
                            // THE FIX: Check that the audio interface actually exists before checking if it is muted
                            enabled: modelData?.audio ? !modelData.audio.muted : false
                            
                            onMoved: {
                                if (modelData?.audio) {
                                    modelData.audio.volume = value;
                                    if (value > 0 && modelData.audio.muted) modelData.audio.muted = false;
                                }
                            }

                            background: Rectangle {
                                x: streamSlider.leftPadding
                                y: streamSlider.topPadding + streamSlider.availableHeight / 2 - height / 2
                                width: streamSlider.availableWidth
                                height: 24 // Taller, thicker track
                                radius: 12
                                color: Qt.rgba(1, 1, 1, 0.15)

                                // 100% Marker Notch
                                Rectangle {
                                    x: (parent.width / 2.0) - (width / 2)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 2
                                    height: 24
                                    radius: 1
                                    color: Theme.base
                                    opacity: 0.6
                                    z: 1
                                }

                                Rectangle {
                                    width: streamSlider.visualPosition * parent.width
                                    height: parent.height
                                    radius: 12
                                    color: (modelData?.audio?.volume ?? 0) > 1.0 ? Theme.secondary : Theme.main
                                    z: 2
                                }
                            }

                            // Completely removes the visible circle handle
                            handle: Item {}
                        }
                        
                        // Spacer line between application streams
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            Layout.topMargin: 4
                            color: Theme.bridge
                            opacity: 0.4
                        }
                    }
                }
            }
        }
    }
}
