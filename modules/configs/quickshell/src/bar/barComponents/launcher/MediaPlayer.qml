import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects 
import Quickshell
import Quickshell.Io

import "../../../theme" 
import "../../../theme/components" 

Item {
    id: mediaRoot

    // ==========================================
    // DATA RECEIVERS (SHELL BACKEND)
    // ==========================================
    property string playbackStatus: "Paused"
    property string trackTitle: "No Media Playing"
    property string trackArtist: ""
    property string trackAlbum: ""
    property string trackArt: "" 
    property string displayArt: "" 
    property real trackPosition: 0
    property real trackLength: 1
    
    property string currentPlayer: "" 
    // Now exclusively stores base names like "firefox" or "spotify"
    property string manualPlayer: "" 
    property var availablePlayers: []
    
    property var cavaData: Array(60).fill(0)
    property real progressFraction: trackLength > 0 ? (trackPosition / trackLength) : 0
    property bool isInitialized: false

    opacity: isInitialized ? 1 : 0
    Behavior on opacity { OpacityAnimator { duration: 300; easing.type: Easing.InOutQuad } }

    // ==========================================
    // SHELL PROCESSES
    // ==========================================
    Process { id: mediaCmdProcess }
    
    Process {
        id: focusAppProcess
        onExited: running = false
    }
    
    function runMediaCmd(cmd) {
        let target = mediaRoot.manualPlayer !== "" ? mediaRoot.manualPlayer : mediaRoot.currentPlayer;
        
        if (target !== "") {
            // Strip any leftover instance IDs just to be safe
            let cleanTarget = target.split('.')[0];
            // Removed the dangerous fallback! It will now exclusively target the requested app.
            mediaCmdProcess.command = ["bash", "-c", "playerctl -p '" + cleanTarget + "' " + cmd];
        } else {
            mediaCmdProcess.command = ["bash", "-c", "playerctl " + cmd];
        }
        
        mediaCmdProcess.running = true;
        fastUpdateTimer.restart();
    }

    Timer {
        id: fastUpdateTimer
        interval: 150
        onTriggered: mediaPoller.running = true
    }

    // 1. FETCH AVAILABLE PLAYERS LIST (Cleaned up to base names)
    Process {
        id: playerListPoller
        command: ["playerctl", "-l"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split('\n');
                let validPlayers = [];
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].trim() !== "") {
                        // Extract just the base name (e.g., 'zen.instance123' -> 'zen')
                        let base = lines[i].trim().split('.')[0];
                        if (!validPlayers.includes(base)) validPlayers.push(base);
                    }
                }
                
                if (mediaRoot.manualPlayer !== "" && !validPlayers.includes(mediaRoot.manualPlayer)) {
                    mediaRoot.manualPlayer = "";
                }
                
                mediaRoot.availablePlayers = validPlayers;
            }
        }
    }

    // 2. SMART UNIFIED POLLER (Base Name Locking)
    Process {
        id: mediaPoller
        command: [
            "bash", "-c",
            "M_PLAYER='" + mediaRoot.manualPlayer + "'; " +
            "if [ -n \"$M_PLAYER\" ]; then P=$(playerctl -l 2>/dev/null | grep -i \"^$M_PLAYER\" | head -n 1); " +
            "else P=$(playerctl -a metadata --format '{{playerName}}|{{status}}' 2>/dev/null | awk -F'|' '$2==\"Playing\"{print $1; exit}'); " +
            "[ -z \"$P\" ] && P=$(playerctl -l 2>/dev/null | head -n 1); fi; " +
            "if [ -n \"$P\" ]; then " +
            "playerctl -p \"$P\" metadata --format '{{status}};;{{title}};;{{artist}};;{{album}};;{{mpris:artUrl}};;{{position}};;{{mpris:length}};;'\"$P\" 2>/dev/null; " +
            "else echo 'Paused;;No Media Playing;;;;;;;;0;;1;;'; fi"
        ]
        
        stdout: SplitParser {
            onRead: data => {
                let parts = data.split(';;');
                if (parts.length >= 8) {
                    mediaRoot.playbackStatus = parts[0].trim();
                    mediaRoot.trackTitle = parts[1].trim() || "Unknown Title";
                    mediaRoot.trackArtist = parts[2].trim();
                    mediaRoot.trackAlbum = parts[3].trim();
                    
                    let rawArt = parts[4].trim();
                    if (rawArt !== "") {
                        if (rawArt.startsWith("file://") || rawArt.startsWith("http://") || rawArt.startsWith("https://")) {
                            mediaRoot.trackArt = rawArt;
                        } else if (rawArt.startsWith("/")) {
                            mediaRoot.trackArt = "file://" + rawArt;
                        } else {
                            mediaRoot.trackArt = "https://" + rawArt;
                        }
                    } else {
                        mediaRoot.trackArt = "";
                    }
                    
                    let pos = parseFloat(parts[5].trim());
                    let len = parseFloat(parts[6].trim());
                    if (!isNaN(pos) && !isNaN(len) && len > 0) {
                        mediaRoot.trackPosition = pos;
                        mediaRoot.trackLength = len;
                    } else {
                        mediaRoot.trackPosition = 0;
                        mediaRoot.trackLength = 1;
                    }
                    
                    let playerStr = parts[7].trim();
                    if (playerStr !== "") mediaRoot.currentPlayer = playerStr;

                    if (!mediaRoot.isInitialized) {
                        mediaRoot.isInitialized = true;
                        mediaRoot.displayArt = mediaRoot.trackArt;
                    }
                }
            }
        }
    }

    Timer {
        id: startupDelay
        interval: 50
        running: false
        repeat: false
        onTriggered: {
            playerListPoller.running = true;
            mediaPoller.running = true;
        }
    }
    
    onVisibleChanged: {
        if (visible) {
            startupDelay.restart();
        } else {
            mediaRoot.isInitialized = false; 
        }
    }

    Timer {
        interval: 500
        running: mediaRoot.visible && !startupDelay.running
        repeat: true
        onTriggered: {
            if (Date.now() % 2000 < 500) playerListPoller.running = true; 
            mediaPoller.running = true;
        }
    }

    // 3. CAVA AUDIO VISUALIZER DAEMON 
    Process {
        id: cavaProcess
        command: [
            "bash", "-c",
            "if command -v cava >/dev/null 2>&1; then " +
            "echo -e '[general]\\nframerate=45\\nbars=60\\n[output]\\nmethod=raw\\nraw_target=/dev/stdout\\ndata_format=ascii\\nbit_format=8bit' | cava -p /dev/stdin; " +
            "else while true; do sleep 1; done; fi"
        ]
        running: mediaRoot.visible && mediaRoot.playbackStatus === "Playing"
        
        stdout: SplitParser {
            onRead: function(data) {
                let strValues = data.trim().split(';');
                let numValues = [];
                for(let i = 0; i < 60; i++) {
                    let val = parseInt(strValues[i]);
                    numValues.push(isNaN(val) ? 0 : val / 255.0); 
                }
                if(numValues.length > 0) {
                    mediaRoot.cavaData = numValues;
                }
            }
        }
    }

    // ==========================================
    // UI LAYOUT
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Metrics.spacingLarge
        spacing: Metrics.spacingLarge

        // --- TOP SECTION: Thumbnail & Info ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 50 

            // 1. Static Rounded Thumbnail
            Item {
                id: thumbContainer
                
                property real artRatio: (albumArt.sourceSize.width > 0 && albumArt.sourceSize.height > 0) 
                                        ? (albumArt.sourceSize.width / albumArt.sourceSize.height) 
                                        : 1.0
                
                Layout.preferredWidth: artRatio < 0.95 ? (400 * artRatio) : 400
                Layout.preferredHeight: artRatio > 1.05 ? (400 / artRatio) : 400
                
                Behavior on Layout.preferredWidth { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

                Item {
                    id: artContainer
                    anchors.fill: parent
                    
                    Rectangle {
                        id: maskRect
                        width: parent.width
                        height: parent.height
                        radius: 32 
                        visible: false 
                        layer.enabled: true 
                    }

                    Image {
                        id: albumArt
                        anchors.fill: parent
                        source: mediaRoot.displayArt
                        fillMode: Image.PreserveAspectCrop 
                        asynchronous: true
                        visible: false 
                        layer.enabled: true 
                    }

                    MultiEffect {
                        id: artEffect
                        anchors.fill: parent
                        source: albumArt
                        maskEnabled: true
                        maskSource: maskRect
                        
                        visible: true 
                        
                        opacity: (mediaRoot.displayArt !== "" && albumArt.status === Image.Ready && mediaRoot.displayArt === mediaRoot.trackArt) ? 1 : 0
                        Behavior on opacity { OpacityAnimator { duration: 400; easing.type: Easing.InOutQuad } }
                        
                        onOpacityChanged: {
                            if (opacity === 0 && mediaRoot.displayArt !== mediaRoot.trackArt) {
                                mediaRoot.displayArt = mediaRoot.trackArt;
                            }
                        }
                    }
                }
                
                Text {
                    anchors.centerIn: parent
                    text: "\uf001" 
                    color: Theme.text
                    font.family: Theme.fontIcon
                    font.pixelSize: 120
                    opacity: artEffect.opacity < 0.5 ? 1 : 0
                    Behavior on opacity { OpacityAnimator { duration: 400 } }
                }
                
                Rectangle {
                    anchors.fill: parent
                    radius: 32 
                    color: "transparent"
                    border.width: 5 
                    border.color: Theme.main
                }
            }

            // 2. Track Info & Main Playback Controls
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Metrics.spacingLarge 

                Text {
                    text: mediaRoot.trackTitle
                    color: Theme.main
                    font.family: Theme.fontMain
                    font.pixelSize: 38
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                Text {
                    text: mediaRoot.trackArtist
                    color: Theme.text
                    font.family: Theme.fontMain
                    font.pixelSize: 24
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    visible: text !== ""
                }

                Text {
                    text: mediaRoot.trackAlbum
                    color: Qt.darker(Theme.text, 1.2)
                    font.family: Theme.fontMain
                    font.pixelSize: 18
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    visible: text !== ""
                }

                Item { Layout.preferredHeight: 4 } 

                // --- SOURCE SELECTOR PILLS ---
                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    Layout.alignment: Qt.AlignHCenter
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    visible: mediaRoot.availablePlayers.length > 0

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Repeater {
                            model: mediaRoot.availablePlayers
                            delegate: Rectangle {
                                property bool isLocked: mediaRoot.manualPlayer === modelData
                                // Checks if the currently playing instance starts with the base name
                                property bool isActive: mediaRoot.currentPlayer.split('.')[0] === modelData

                                Layout.preferredHeight: 28
                                Layout.preferredWidth: pillText.implicitWidth + 24
                                radius: 14
                                color: (isLocked || isActive) ? Theme.main : "transparent"
                                border.width: 1
                                border.color: (isLocked || isActive) ? Theme.main : Theme.bridge
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    
                                    Text {
                                        visible: isLocked
                                        text: "\uf023" // fa-lock
                                        color: Theme.base
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 10
                                    }
                                    
                                    Text {
                                        id: pillText
                                        // The modelData is already cleanly formatted (e.g. "firefox" or "spotify")
                                        text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                        color: (isLocked || isActive) ? Theme.base : Theme.text
                                        font.family: Theme.fontMain
                                        font.pixelSize: 12
                                        font.weight: (isLocked || isActive) ? Font.Bold : Font.Medium
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (mediaRoot.manualPlayer === modelData) {
                                            mediaRoot.manualPlayer = ""; // Toggle lock off
                                        } else {
                                            mediaRoot.manualPlayer = modelData; // Lock to player
                                        }
                                        mediaPoller.running = true;
                                    }
                                }
                            }
                        }
                    }
                }

                Item { Layout.preferredHeight: 4 } 

                // --- GHOST SEEK CONTROLS ---
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Metrics.spacingSmall

                    component SeekButton: Rectangle {
                        id: seekBtn
                        property int offset: 0
                        Layout.preferredWidth: 50
                        Layout.preferredHeight: 50
                        radius: 25
                        
                        color: seekMouse.containsMouse ? Theme.bridge : "transparent"
                        border.width: 2
                        border.color: seekMouse.containsMouse ? Theme.main : "transparent"
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: seekMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mediaRoot.runMediaCmd("position " + Math.abs(offset) + (offset > 0 ? "+" : "-"))
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: (seekBtn.offset > 0 ? "+" : "") + seekBtn.offset + "s"
                            color: Theme.text 
                            font.family: Theme.fontMain
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }
                    }

                    SeekButton { offset: -60 }
                    SeekButton { offset: -30 }
                    SeekButton { offset: -10 }
                    
                    Item { Layout.preferredWidth: 20 } 
                    
                    SeekButton { offset: 10 }
                    SeekButton { offset: 30 }
                    SeekButton { offset: 60 }
                }

                // --- MAIN PLAYBACK CONTROLS ---
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 35

                    ThemeButton {
                        Layout.preferredWidth: 70
                        Layout.preferredHeight: 70
                        radius: 35
                        color: Theme.bridge
                        Text { anchors.centerIn: parent; text: "\uf048"; color: Theme.text; font.family: Theme.fontIcon; font.pixelSize: 24 }
                        onClicked: mediaRoot.runMediaCmd("previous")
                    }

                    ThemeButton {
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 100
                        radius: 50
                        color: Theme.main
                        Text { anchors.centerIn: parent; text: mediaRoot.playbackStatus === "Playing" ? "\uf04c" : "\uf04b"; color: Theme.base; font.family: Theme.fontIcon; font.pixelSize: 36 }
                        onClicked: mediaRoot.runMediaCmd("play-pause")
                    }

                    ThemeButton {
                        Layout.preferredWidth: 70
                        Layout.preferredHeight: 70
                        radius: 35
                        color: Theme.bridge
                        Text { anchors.centerIn: parent; text: "\uf051"; color: Theme.text; font.family: Theme.fontIcon; font.pixelSize: 24 }
                        onClicked: mediaRoot.runMediaCmd("next")
                    }
                }
            }
        }

        Item { Layout.fillHeight: true } 

        // --- INTERACTIVE AUDIO VISUALIZER PROGRESS BAR ---
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 60 
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mediaRoot.trackLength > 0) {
                        let clickFraction = mouse.x / width;
                        let targetPositionInSeconds = (clickFraction * mediaRoot.trackLength) / 1000000;
                        mediaRoot.runMediaCmd("position " + targetPositionInSeconds);
                    }
                }
            }
            
            RowLayout {
                id: waveRow
                anchors.fill: parent 
                spacing: 4
                property int totalBars: 60 
                
                Repeater {
                    model: waveRow.totalBars
                    
                    Item {
                        Layout.fillWidth: true 
                        Layout.fillHeight: true 
                        
                        Rectangle {
                            anchors.centerIn: parent 
                            
                            property real barProgress: index / waveRow.totalBars
                            property bool isPassed: barProgress <= mediaRoot.progressFraction
                            
                            property real val: mediaRoot.cavaData[index] !== undefined ? mediaRoot.cavaData[index] : 0
                            property real baseHeight: 6
                            property real waveAmplitude: (mediaRoot.playbackStatus === "Playing" && isPassed) ? val * 30 : 0
                            
                            width: Math.max(2, parent.width)
                            height: baseHeight + waveAmplitude 
                            radius: width / 2
                            
                            color: isPassed ? Theme.main : Theme.bridge
                            
                            Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
            }
        }

        // --- BOTTOM SECTION: Action Buttons ---
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Metrics.spacingBase
            spacing: Metrics.spacingBase

            ThemeButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: Theme.secondary
                border.width: 0
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    Text { text: "\uf08e"; color: Theme.base; font.family: Theme.fontIcon; font.pixelSize: 18 }
                    Text { text: "Focus Application"; color: Theme.base; font.family: Theme.fontMain; font.pixelSize: 18; font.weight: Font.Medium }
                }
                
                onClicked: {
                    let cleanPlayer = mediaRoot.currentPlayer.split('.')[0]; 
                    if (cleanPlayer === "%any" || cleanPlayer === "") return;
                    
                    let cmd = [
                        "INFO=$(hyprctl clients -j | jq -r -c '.[] | select(.class != null and (.class | test(\"" + cleanPlayer + "\"; \"i\"))) | \"\\(.address);\\(.workspace.name)\"' | head -n 1)",
                        "if [ -n \"$INFO\" ] && [ \"$INFO\" != \"null\" ]; then",
                        "  ADDR=$(echo \"$INFO\" | cut -d';' -f1)",
                        "  WS=$(echo \"$INFO\" | cut -d';' -f2)",
                        "  if [[ \"$ADDR\" != 0x* ]]; then ADDR=\"0x$ADDR\"; fi",
                        "  hyprctl eval 'hl.dispatch(hl.dsp.focus({ workspace = \"'$WS'\" })); hl.dispatch(hl.dsp.focus({ window = \"address:'$ADDR'\" }))'",
                        "fi"
                    ].join("; ");

                    focusAppProcess.command = ["bash", "-c", cmd];
                    focusAppProcess.running = true;

                    let p = mediaRoot;
                    while (p && !p.focusable) p = p.parent;
                    if (p) p.visible = false;
                }
            }

            ThemeButton {
                Layout.preferredWidth: 60
                Layout.preferredHeight: 60
                color: Theme.urgent
                border.width: 0
                Text { anchors.centerIn: parent; text: "\uf04d"; color: Theme.base; font.family: Theme.fontIcon; font.pixelSize: 20 }
                onClicked: mediaRoot.runMediaCmd("stop")
            }
        }
    }
}
