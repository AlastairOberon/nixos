import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Shapes 
import Qt5Compat.GraphicalEffects 
import Quickshell
import Quickshell.Io
import "../" 

BlueprintPopup {
    id: mediaPopup
    
    popupWidth: 1050 
    popupHeight: Math.round(Screen.height * 0.25)
    
    isTopBar: false 
    timeoutDuration: 5000 

    // --- DATA RECEIVERS ---
    property string nowPlaying: "No Media Playing"
    property string playbackStatus: "Paused"
    property real trackPosition: 0
    property real trackLength: 1
    property string trackArt: "" 
    property string currentPlayer: "%any"

    Process { id: mediaCmdProcess }
    function runMediaCmd(cmd) {
        mediaCmdProcess.command = ["bash", "-c", "playerctl -p '" + mediaPopup.currentPlayer + "' " + cmd];
        mediaCmdProcess.running = true;
    }

    // --- LIVE POSITION POLLER ---
    Process {
        id: positionPoller
        command: ["bash", "-c", "playerctl -p '" + mediaPopup.currentPlayer + "' metadata --format '{{position}},{{mpris:length}}' 2>/dev/null || echo '0,0'"]
        stdout: SplitParser {
            onRead: function(data) {
                let parts = data.trim().split(',');
                if (parts.length === 2) {
                    let pos = parseFloat(parts[0]);
                    let len = parseFloat(parts[1]);
                    if (!isNaN(pos) && !isNaN(len) && len > 0) {
                        mediaPopup.trackPosition = pos;
                        mediaPopup.trackLength = len;
                    }
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: mediaPopup.visible && mediaPopup.playbackStatus === "Playing"
        repeat: true
        triggeredOnStart: true
        onTriggered: positionPoller.running = true
    }

    // ==========================================
    // --- CAVA AUDIO VISUALIZER DAEMON ---
    // ==========================================
    Process {
        id: cavaProcess
        command: [
            "bash", "-c",
            "if command -v cava >/dev/null 2>&1; then " +
            "echo -e '[general]\\nframerate=45\\nbars=30\\n[output]\\nmethod=raw\\nraw_target=/dev/stdout\\ndata_format=ascii\\nbit_format=8bit' | cava -p /dev/stdin; " +
            "else while true; do sleep 1; done; fi"
        ]
        running: mediaPopup.visible && mediaPopup.playbackStatus === "Playing"
        
        stdout: SplitParser {
            onRead: function(data) {
                let strValues = data.trim().split(';');
                let numValues = [];
                for(let i = 0; i < strValues.length; i++) {
                    if(strValues[i] !== "") {
                        numValues.push(parseInt(strValues[i]) / 255.0); 
                    }
                }
                if(numValues.length > 0) {
                    ringContainer.cavaData = numValues;
                    cavaCanvas.requestPaint();
                }
            }
        }
    }

    // ==========================================
    // --- 1. THE BLURRED BACKDROP ---
    // ==========================================
    Item {
        anchors.fill: parent
        
        Rectangle { id: bgMask; anchors.fill: parent; radius: 8; color: "black"; visible: false }

        Image {
            id: blurredBgSource; anchors.fill: parent; source: mediaPopup.trackArt
            fillMode: Image.PreserveAspectCrop; visible: false; asynchronous: true
            property real aspectRatio: sourceSize.height > 0 ? (sourceSize.width / sourceSize.height) : 1.0
            scale: (aspectRatio > 1.3 && aspectRatio < 1.4) ? 1.6 : 1.2 
        }

        FastBlur {
            anchors.fill: parent; source: blurredBgSource; radius: 64 
            visible: mediaPopup.trackArt !== "" && blurredBgSource.status === Image.Ready
            opacity: 0.45 
            layer.enabled: true; layer.effect: OpacityMask { maskSource: bgMask }
            Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.4) }
        }
    }

    // ==========================================
    // --- 2. MAIN CONTENT LAYOUT ---
    // ==========================================
    RowLayout {
        anchors.fill: parent
        anchors.margins: 20 
        spacing: 35 

        // --- LEFT: CIRCULAR ART & REACTIVE PROGRESS RING ---
        Item {
            id: ringContainer
            
            Layout.preferredWidth: mediaPopup.popupHeight - 70
            Layout.preferredHeight: mediaPopup.popupHeight - 70
            Layout.alignment: Qt.AlignVCenter

            property var cavaData: []
            property real progressFraction: mediaPopup.trackLength > 0 ? (mediaPopup.trackPosition / mediaPopup.trackLength) : 0
            Behavior on progressFraction { NumberAnimation { duration: 1000; easing.type: Easing.Linear } }
            
            onProgressFractionChanged: cavaCanvas.requestPaint()

            // Strict proportional sizing guarantees it will never clip!
            property real minDim: Math.min(width, height)
            property real maxBarHeight: minDim * 0.01 // Bars can take up to 16% of the radius
            // Base ring is set inward with a 15px safe margin from the edge
            property real baseRadius: (minDim / 2) - maxBarHeight - 15 
            // Thumbnail shrunk by an additional 12px gap so the bars have plenty of breathing room
            property real artSize: (baseRadius - 12) * 2 

            // --- 1. Hybrid Reactive Progress Visualizer ---
            Canvas {
                id: cavaCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    
                    let centerX = width / 2;
                    let centerY = height / 2;
                    
                    let progress = parent.progressFraction;
                    let bRadius = parent.baseRadius;
                    let bMaxHeight = parent.maxBarHeight;

                    // 1. Draw the "Empty" Grey Track Ring
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, bRadius, 0, 2 * Math.PI);
                    ctx.lineWidth = 2;
                    ctx.strokeStyle = Theme.secondaryBase.toString();
                    ctx.stroke();

                    let bars = parent.cavaData;
                    if (!bars || bars.length === 0) return;

                    // 2. Draw the "Filled" Reactive Pill-Wedges
                    ctx.fillStyle = Theme.main.toString();

                    let totalBars = 60; 
                    let angleStep = (2 * Math.PI) / totalBars;
                    
                    for (let i = 0; i < totalBars; i++) {
                        if (progress >= (i / totalBars)) {
                            
                            let dataIndex = i < 30 ? i : 59 - i;
                            let val = Math.max(bars[dataIndex] || 0, 0.04); // Minimum dot size
                            let barHeight = val * bMaxHeight;

                            let angle = (i * angleStep) - (Math.PI / 2);

                            ctx.save();
                            ctx.translate(centerX, centerY);
                            ctx.rotate(angle);

                            // Width of the bar takes up 70% of its available angular slice
                            let innerHalfWidth = (bRadius * angleStep * 0.70) / 2;
                            let outerRadius = bRadius + barHeight;
                            let outerHalfWidth = (outerRadius * angleStep * 0.70) / 2;

                            ctx.beginPath();
                            // Start at top-left inner edge
                            ctx.moveTo(bRadius, -innerHalfWidth);
                            // Line to top-right outer edge
                            ctx.lineTo(outerRadius, -outerHalfWidth);
                            // Perfect semi-circle cap on the outer edge
                            ctx.arc(outerRadius, 0, outerHalfWidth, -Math.PI/2, Math.PI/2, false);
                            // Line back to bottom-left inner edge
                            ctx.lineTo(bRadius, innerHalfWidth);
                            // Perfect semi-circle cap on the inner edge
                            ctx.arc(bRadius, 0, innerHalfWidth, Math.PI/2, -Math.PI/2, false);

                            ctx.fill();
                            ctx.restore();
                        }
                    }
                }
            }

            // --- 2. Circular Album Art Mask (Inner) ---
            Rectangle {
                id: artMask
                anchors.centerIn: parent
                width: parent.artSize
                height: width
                radius: width / 2
                visible: false 
            }

            // Fallback Background 
            Rectangle {
                anchors.fill: artMask
                radius: artMask.radius
                color: Theme.secondaryBase
                visible: mediaPopup.trackArt === "" || albumArtImage.status === Image.Error
                Text { anchors.centerIn: parent; text: "󰎆"; font.pixelSize: 48; color: Theme.inactive }
            }

            // Turntable Engine
            Item {
                id: artContainer
                anchors.fill: artMask
                visible: mediaPopup.trackArt !== "" && albumArtImage.status !== Image.Error
                
                property real targetSpinSpeed: mediaPopup.playbackStatus === "Playing" ? 1.0 : 0.0
                property real currentSpinSpeed: targetSpinSpeed
                
                Behavior on currentSpinSpeed { NumberAnimation { duration: 1500; easing.type: Easing.InOutQuad } }
                
                layer.enabled: true; layer.effect: OpacityMask { maskSource: artMask }

                Image {
                    id: albumArtImage; anchors.fill: parent; source: mediaPopup.trackArt
                    fillMode: Image.PreserveAspectCrop; asynchronous: true
                    property real aspectRatio: sourceSize.height > 0 ? (sourceSize.width / sourceSize.height) : 1.0
                    scale: (aspectRatio > 1.3 && aspectRatio < 1.4) ? 1.35 : 1.0
                }
                
                Timer {
                    interval: 16; repeat: true; running: artContainer.currentSpinSpeed > 0
                    onTriggered: albumArtImage.rotation = (albumArtImage.rotation + (0.72 * artContainer.currentSpinSpeed)) % 360
                }
            }
        }

        // --- RIGHT: INFO & CONTROLS ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 15

            Item { Layout.fillHeight: true } 

            // Track Info
            ColumnLayout {
                Layout.fillWidth: true; spacing: 5
                
                Item {
                    id: titleContainer
                    Layout.fillWidth: true; Layout.preferredHeight: 35; clip: true

                    property bool needsScroll: titleText.contentWidth > titleContainer.width
                    property string trackTitle: mediaPopup.nowPlaying.split(" - ")[0] || "Unknown Title"

                    layer.enabled: titleContainer.needsScroll
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: titleContainer.width; height: titleContainer.height
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
                        id: titleRow
                        x: titleContainer.needsScroll ? 0 : (titleContainer.width - titleText.width) / 2
                        anchors.verticalCenter: parent.verticalCenter; spacing: 80

                        Text {
                            id: titleText; text: titleContainer.trackTitle; color: "#FFFFFF"; font.bold: true; font.pixelSize: 26 
                            onTextChanged: {
                                if (titleContainer.needsScroll) titleScrollAnim.restart();
                                else { titleScrollAnim.stop(); titleRow.x = (titleContainer.width - titleText.width) / 2; }
                            }
                        }
                        Text { text: titleContainer.trackTitle; color: "#FFFFFF"; font.bold: true; font.pixelSize: 26; visible: titleContainer.needsScroll }

                        NumberAnimation on x {
                            id: titleScrollAnim; loops: Animation.Infinite; running: titleContainer.needsScroll
                            from: 0; to: -(titleText.width + titleRow.spacing); duration: (titleText.width + titleRow.spacing) * 25
                        }
                    }
                }

                Text {
                    text: mediaPopup.nowPlaying.split(" - ")[1] || "Unknown Artist"
                    color: "#DDDDDD"; font.pixelSize: 18; elide: Text.ElideRight; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter 
                }
            }

            Item { Layout.preferredHeight: 10 } 

            // Jump Controls
            RowLayout {
                Layout.fillWidth: true; Layout.alignment: Qt.AlignHCenter; spacing: 20 

                Repeater {
                    model: [
                        { label: "-60s", cmd: "position 60-" }, { label: "-30s", cmd: "position 30-" }, { label: "-10s", cmd: "position 10-" },
                        { label: "|", cmd: "" },
                        { label: "+10s", cmd: "position 10+" }, { label: "+30s", cmd: "position 30+" }, { label: "+60s", cmd: "position 60+" }
                    ]
                    delegate: Text {
                        text: modelData.label; font.pixelSize: 15; font.bold: true
                        color: { if (modelData.label === "|") return "#555555"; return jumpMouse.containsMouse ? Theme.main : "#BBBBBB"; }
                        MouseArea { id: jumpMouse; anchors.fill: parent; hoverEnabled: modelData.label !== "|"; enabled: modelData.label !== "|"; cursorShape: Qt.PointingHandCursor; onClicked: mediaPopup.runMediaCmd(modelData.cmd) }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            Item { Layout.preferredHeight: 10 } 

            // Main Controls
            RowLayout {
                Layout.fillWidth: true; Layout.alignment: Qt.AlignHCenter; spacing: 50 

                Text {
                    text: "󰒮"; font.pixelSize: 42; color: prevMouse.containsMouse ? Theme.main : "#FFFFFF"
                    MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: mediaPopup.runMediaCmd("previous") }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Text {
                    text: mediaPopup.playbackStatus === "Playing" ? "󰏤" : "󰐊"
                    font.pixelSize: 56; color: playMouse.containsMouse ? Theme.main : "#FFFFFF"
                    MouseArea { id: playMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: mediaPopup.runMediaCmd("play-pause") }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Text {
                    text: "󰒭"; font.pixelSize: 42; color: nextMouse.containsMouse ? Theme.main : "#FFFFFF"
                    // THE FIX: "cursor popup:" -> "cursorShape:"
                    MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: mediaPopup.runMediaCmd("next") }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
