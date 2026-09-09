import QtQuick
import QtQuick.Layouts
import QtQuick.Effects 
import Quickshell
import Quickshell.Io
import "../" 

Item {
    id: visRoot
    Layout.preferredWidth: barLayout.implicitWidth
    Layout.fillHeight: true

    property var parentWindow: null

    property var levels: [0,0,0,0,0,0,0,0,0,0] 
    property int numBars: 10
    property string nowPlaying: "No Media Playing"
    property bool isPlaying: nowPlaying !== "No Media Playing"

    property string playbackStatus: "Paused"
    property real trackPosition: 0
    property real trackLength: 1
    property string trackArt: "" 
    property string currentPlayer: "%any"

    function getScriptPath() {
        let rawUrl = String(Qt.resolvedUrl("media_daemon.lua"));
        if (rawUrl.startsWith("file://")) {
            rawUrl = rawUrl.substring(7);
        }
        return decodeURIComponent(rawUrl);
    }

    property string scriptPath: getScriptPath()

    // 1. The Audio Visualizer 
    Process {
        id: cavaProcess
        running: false 
        command: ["bash", "-c", "cava -p <(echo -e '[general]\nframerate=30\nbars=" + numBars + "\n[output]\nmethod=raw\nraw_target=/dev/stdout\ndata_format=ascii\nascii_max_range=100')"]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(';');
                if (parts.length >= visRoot.numBars) {
                    let newLevels = [];
                    for (let i = 0; i < visRoot.numBars; i++) {
                        newLevels.push(parseInt(parts[i]) || 0);
                    }
                    visRoot.levels = newLevels;
                }
            }
        }
    }

    // 2. THE LUA PRIORITY DAEMON
    Process {
        id: priorityEngine
        running: false 
        command: ["bash", "-c", "lua '" + visRoot.scriptPath + "'"]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split('<|>');
                if (parts.length >= 6) {
                    visRoot.playbackStatus = parts[0];
                    
                    let text = parts[1];
                    let newNowPlaying = (text === " - " || text.startsWith(" - ") || text === "") ? "No Media Playing" : text;
                    
                    let newArt = parts[4] || "";
                    
                    // THE FIX: QML Memory! 
                    // If the browser drops the image, keep the old one unless the song actually changed.
                    if (newArt !== "") {
                        visRoot.trackArt = newArt;
                    } else if (newNowPlaying !== visRoot.nowPlaying) {
                        visRoot.trackArt = "";
                    }

                    visRoot.nowPlaying = newNowPlaying;
                    visRoot.trackPosition = parseFloat(parts[2]) || 0;
                    visRoot.trackLength = Math.max(1, (parseFloat(parts[3]) || 0) / 1000000);
                    visRoot.currentPlayer = parts[5]; 
                }
            }
        }
    }

    // --- BOOT UP DELAY TIMER ---
    Timer {
        interval: 800 
        running: true
        repeat: false
        onTriggered: {
            cavaProcess.running = true;
            priorityEngine.running = true;
        }
    }

    // --- UI CONTENT ---
    RowLayout {
        id: barLayout
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left 
        height: 30 
        spacing: 15 

        RowLayout {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                model: visRoot.numBars
                delegate: Rectangle {
                    property real levelRatio: visRoot.levels[index] / 100.0
                    Layout.preferredWidth: 6
                    Layout.preferredHeight: isPlaying ? Math.max(6, levelRatio * 30) : 6
                    Layout.alignment: Qt.AlignVCenter 
                    radius: width / 2 
                    
                    color: {
                        if (!isPlaying) return Theme.inactive;
                        let ratio = Math.max(0.0, Math.min(1.0, levelRatio));
                        let quietColor = Theme.main; 
                        let loudColor = Theme.secondary;
                        
                        let r = quietColor.r * (1 - ratio) + loudColor.r * ratio;
                        let g = quietColor.g * (1 - ratio) + loudColor.g * ratio;
                        let b = quietColor.b * (1 - ratio) + loudColor.b * ratio;
                        
                        return Qt.rgba(r, g, b, 1.0);
                    }
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                }
            }
        }

        RowLayout {
            spacing: 8
            
            Text {
                text: "󰎆" 
                color: isPlaying ? Theme.secondary : Theme.inactive
                font.pixelSize: 16
                Layout.alignment: Qt.AlignVCenter
                Behavior on color { ColorAnimation { duration: 300 } }
            }
            
            Item {
                id: marqueeContainer
                Layout.maximumWidth: 250 
                Layout.preferredWidth: needsScroll ? 250 : originalText.contentWidth 
                Layout.fillHeight: true
                clip: true 
                property bool needsScroll: originalText.contentWidth > 230

                layer.enabled: marqueeContainer.needsScroll
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: marqueeContainer.width
                        height: marqueeContainer.height
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.1; color: "black" }
                            GradientStop { position: 0.9; color: "black" }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }
                }

                Row {
                    id: scrollingRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 50 

                    Text {
                        id: originalText
                        text: visRoot.nowPlaying
                        color: isPlaying ? Theme.text : Theme.inactive
                        font.pixelSize: 13
                        font.bold: true
                        leftPadding: marqueeContainer.needsScroll ? 20 : 0
                        
                        onTextChanged: {
                            if (marqueeContainer.needsScroll) scrollAnim.restart();
                            else { scrollAnim.stop(); scrollingRow.x = 0; }
                        }
                    }

                    Text {
                        text: visRoot.nowPlaying
                        color: isPlaying ? Theme.text : Theme.inactive
                        font.pixelSize: 13
                        font.bold: true
                        visible: marqueeContainer.needsScroll
                        leftPadding: marqueeContainer.needsScroll ? 20 : 0
                    }

                    NumberAnimation on x {
                        id: scrollAnim
                        loops: Animation.Infinite
                        running: marqueeContainer.needsScroll
                        from: 0
                        to: -(originalText.width + scrollingRow.spacing)
                        duration: (originalText.width + scrollingRow.spacing) * 30 
                    }
                }
            }
        }
    } 

    MouseArea {
        width: parent.width
        height: parent.height
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!popupLoader.active) {
                popupLoader.active = true;
            } else if (popupLoader.status === Loader.Ready) {
                popupLoader.item.parentWindow = visRoot.parentWindow;
                popupLoader.item.anchorTarget = barLayout;
                popupLoader.item.toggle();
            }
        }
    }

    Loader {
        id: popupLoader
        active: false 
        asynchronous: true 
        
        sourceComponent: Component {
            MediaPopup {
                nowPlaying: visRoot.nowPlaying
                playbackStatus: visRoot.playbackStatus
                trackPosition: visRoot.trackPosition
                trackLength: visRoot.trackLength
                trackArt: visRoot.trackArt
                currentPlayer: visRoot.currentPlayer 
            }
        }

        onLoaded: {
            item.parentWindow = visRoot.parentWindow;
            item.anchorTarget = barLayout;
            item.toggle();
        }
    }
}
