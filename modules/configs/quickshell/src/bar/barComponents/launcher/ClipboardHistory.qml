import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io 

import "../../../theme" 
import "../../../theme/components" 

Item {
    id: clipboardRoot
    
    property string searchQuery: ""
    property bool imagesOnly: false 
    
    property var clipboardDatabase: []

    // ==========================================
    // ACTIVE ENTRY STATE
    // ==========================================
    property var activeEntry: clipboardDatabase.length > 0 ? clipboardDatabase[0] : null
    property bool activeIsImage: activeEntry ? activeEntry.content.includes("[[ binary data") : false
    property string activeImagePath: activeEntry ? "/tmp/qsh_clip_" + activeEntry.id + ".png" : ""
    
    property string activeImageSource: ""

    function checkAndExtractActiveImage() {
        if (!activeIsImage || !activeEntry) {
            activeImageSource = "";
            return;
        }

        activeImageSource = "file://" + activeImagePath;

        const safeLine = activeEntry.rawLine.replace(/'/g, "'\\''");
        activeExtractProcess.command = [
            "sh", "-c",
            `if [ ! -f "${clipboardRoot.activeImagePath}" ]; then echo '${safeLine}' | cliphist decode > "${clipboardRoot.activeImagePath}"; fi`
        ];
        activeExtractProcess.running = true;
    }

    onActiveEntryChanged: checkAndExtractActiveImage()

    // ==========================================
    // UTILITIES
    // ==========================================
    function formatContent(text, query) {
        if (!text) return "";
        let escaped = text.replace(/&/g, "&amp;")
                          .replace(/</g, "&lt;")
                          .replace(/>/g, "&gt;")
                          .replace(/"/g, "&quot;")
                          .replace(/'/g, "&#039;")
                          .replace(/\n/g, "<br>")
                          .replace(/\t/g, "&nbsp;&nbsp;&nbsp;&nbsp;")
                          .replace(/  /g, "&nbsp;&nbsp;");
        
        let q = query.trim();
        if (q === "") return escaped;
        
        let safeQuery = q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        safeQuery = safeQuery.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        
        let regex = new RegExp("(" + safeQuery + ")", "gi");
        return escaped.replace(regex, "<b>$1</b>");
    }

    function closeWindow() {
        let p = clipboardRoot;
        while (p && !p.focusable) p = p.parent;
        if (p) p.visible = false;
    }

    function copyItem(rawLine) {
        console.log("Pasting full item to wl-clipboard...")
        const safeLine = rawLine.replace(/'/g, "'\\''")
        copyProcess.command = ["sh", "-c", `echo '${safeLine}' | cliphist decode | wl-copy`]
        copyProcess.running = true
        
        toastOverlay.opacity = 1;
        closeTimer.restart();
    }

    function copyString(customText) {
        console.log("Pasting selection to wl-clipboard...")
        const safeLine = customText.replace(/'/g, "'\\''")
        copyProcess.command = ["sh", "-c", `printf "%s" '${safeLine}' | wl-copy`]
        copyProcess.running = true
        
        toastOverlay.opacity = 1;
        closeTimer.restart();
    }

    // ==========================================
    // TOAST NOTIFICATION COMPONENT
    // ==========================================
    Rectangle {
        id: toastOverlay
        z: 100 
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100 
        
        width: 220
        height: 45
        radius: Metrics.radiusBase
        color: Theme.main
        
        opacity: 0
        visible: opacity > 0
        
        Text {
            anchors.centerIn: parent
            text: "✓ Copied to clipboard"
            color: Theme.base
            font.family: Theme.fontMain
            font.pixelSize: 16
            font.weight: Font.Medium
        }

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
    }

    Timer {
        id: closeTimer
        interval: 800 
        onTriggered: {
            toastOverlay.opacity = 0;
            closeWindow();
        }
    }

    // ==========================================
    // SHELL PROCESSES
    // ==========================================
    Process {
        id: activeExtractProcess
        stdout: StdioCollector {
            onStreamFinished: {
                if (activePreviewImage.status !== Image.Ready) {
                    clipboardRoot.activeImageSource = "";
                    clipboardRoot.activeImageSource = "file://" + clipboardRoot.activeImagePath;
                }
            }
        }
    }

    Process {
        id: fetchProcess
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split('\n')
                let newDb = []
                const maxItems = Math.min(lines.length, 50)
                
                for (let i = 0; i < maxItems; i++) {
                    if (lines[i] === "") continue
                    const parts = lines[i].split('\t')
                    if (parts.length >= 2) {
                        newDb.push({
                            id: parts[0], 
                            rawLine: lines[i], 
                            content: parts.slice(1).join('\t') 
                        })
                    }
                }
                clipboardRoot.clipboardDatabase = newDb
            }
        }
    }

    Process { id: copyProcess }
    Process { id: wipeProcess; command: ["cliphist", "wipe"] }

    // ==========================================
    // WINDOW LOGIC
    // ==========================================
    onVisibleChanged: {
        if (visible) {
            searchQuery = ""
            searchInput.text = ""
            imagesOnly = false 
            searchInput.forceActiveFocus()
            clipList.currentIndex = -1 
            toastOverlay.opacity = 0 
            fetchProcess.running = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Metrics.spacingLarge
        anchors.topMargin: Metrics.spacingLarge
        anchors.bottomMargin: Metrics.spacingLarge

        // --- ACTIVE ENTRY SECTION ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: activeIsImage ? 150 : 80
            Layout.leftMargin: Metrics.spacingLarge
            Layout.rightMargin: Metrics.spacingLarge
            
            radius: Metrics.radiusBase
            color: "transparent"
            border.width: activeBoxHover.hovered ? 1 : 0
            border.color: activeBoxHover.hovered ? Theme.main : "transparent"
            visible: clipboardRoot.activeEntry !== null
            
            Behavior on border.color { ColorAnimation { duration: Metrics.animFast } }
            HoverHandler { id: activeBoxHover }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Metrics.spacingBase
                spacing: 4

                Text {
                    text: "TO BE PASTED (Ctrl+V)"
                    color: Theme.main
                    font.family: Theme.fontMain
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                Text {
                    visible: !clipboardRoot.activeIsImage
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: clipboardRoot.activeEntry ? clipboardRoot.activeEntry.content : ""
                    color: Theme.text
                    font.family: Theme.fontMain
                    font.pixelSize: 18
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                }

                Item {
                    visible: clipboardRoot.activeIsImage
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    Text {
                        visible: activePreviewImage.status !== Image.Ready
                        text: "🖼️ Loading Preview..."
                        color: Theme.text
                        anchors.centerIn: parent
                        font.family: Theme.fontMain
                        font.pixelSize: 14
                    }
                    
                    Image {
                        id: activePreviewImage
                        anchors.fill: parent
                        source: clipboardRoot.activeImageSource
                        visible: status === Image.Ready
                        fillMode: Image.PreserveAspectFit
                        horizontalAlignment: Image.AlignLeft
                        cache: false
                    }
                }
            }
        }

        // --- HEADER & SEARCH BAR CONTAINER ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Metrics.spacingLarge
            Layout.rightMargin: Metrics.spacingLarge
            spacing: 8

            Text {
                text: "Clipboard History"
                color: Theme.main
                font.family: Theme.fontMain
                font.pixelSize: 14
                font.weight: Font.Bold
            }

            TextField {
                id: searchInput
                Layout.fillWidth: true
                Layout.preferredHeight: 60   
                placeholderText: "Search clipboard history..."
                color: Theme.text 
                
                font.family: Theme.fontMain   
                font.pixelSize: 24   
                verticalAlignment: TextInput.AlignVCenter
                
                leftPadding: 20
                rightPadding: 20
                
                background: Rectangle {
                    color: Theme.bridge
                    radius: Metrics.radiusBase
                    border.width: 0
                    border.color: "transparent"
                }
                
                onTextChanged: {
                    clipboardRoot.searchQuery = text.toLowerCase().trim()
                    clipList.currentIndex = -1 
                }
                
                Keys.onDownPressed: {
                    if (clipList.currentIndex < clipList.count - 1) clipList.currentIndex++;
                }
                Keys.onUpPressed: {
                    if (clipList.currentIndex > 0) clipList.currentIndex--;
                }
                Keys.onReturnPressed: {
                    const targetIndex = clipList.currentIndex >= 0 ? clipList.currentIndex : 0;
                    const currentItem = clipList.model[targetIndex]
                    if (currentItem) clipboardRoot.copyItem(currentItem.rawLine)
                }
                Keys.onEscapePressed: clipboardRoot.closeWindow()
            }
        }

        // --- CLIPBOARD LIST ---
        FadedList {
            id: clipList
            Layout.fillWidth: true
            Layout.fillHeight: true 
            spacing: Metrics.spacingSmall
            Layout.leftMargin: Metrics.spacingLarge
            Layout.rightMargin: Metrics.spacingLarge
            Layout.topMargin: 10
            
            model: {
                let data = clipboardRoot.clipboardDatabase
                if (clipboardRoot.imagesOnly) {
                    data = data.filter(item => item.content.includes("[[ binary data"))
                }
                const query = clipboardRoot.searchQuery.trim()
                if (query === "") return data
                return data.filter(item => {
                    return item.content && item.content.toLowerCase().includes(query)
                })
            }
            
            delegate: Item {
                id: delegateRoot 
                required property int index
                required property var modelData
                
                property bool isImage: modelData.content.includes("[[ binary data")
                property string imagePath: "/tmp/qsh_clip_" + modelData.id + ".png"
                property bool imageCached: false
                
                property string decodedText: modelData.content 
                property bool isExpanded: false
                
                property bool isActive: clipList.currentIndex === index
                
                width: clipList.width - (Metrics.spacingBase * 2)
                height: isImage ? 150 : (delegateRoot.isExpanded ? 200 : 60)
                
                clip: true 

                Behavior on height {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }

                HoverHandler {
                    onHoveredChanged: { if (hovered) clipList.currentIndex = index }
                }

                Process {
                    id: extractImageProcess
                    command: ["sh", "-c", `if [ ! -f "${delegateRoot.imagePath}" ]; then echo '${modelData.rawLine.replace(/'/g, "'\\''")}' | cliphist decode > "${delegateRoot.imagePath}"; fi`]
                    stdout: StdioCollector { onStreamFinished: { delegateRoot.imageCached = true } }
                }

                Process {
                    id: decodeTextProcess
                    command: ["sh", "-c", `echo '${modelData.rawLine.replace(/'/g, "'\\''")}' | cliphist decode`]
                    stdout: StdioCollector { onStreamFinished: { delegateRoot.decodedText = this.text } }
                }

                Component.onCompleted: {
                    if (isImage) extractImageProcess.running = true
                    else decodeTextProcess.running = true
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: Metrics.spacingBase

                    // --- 1. DEDICATED SQUARE COPY BUTTON ---
                    ThemeButton {
                        id: copyBtn
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 60 
                        Layout.alignment: Qt.AlignTop 
                        
                        property bool isHovered: false
                        selected: copyBtn.isHovered 
                        
                        color: copyBtn.isHovered ? Theme.main : "transparent"
                        border.width: copyBtn.isHovered ? 1 : 0
                        border.color: copyBtn.isHovered ? Theme.base : "transparent"
                        
                        HoverHandler {
                            onHoveredChanged: copyBtn.isHovered = hovered
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "\uf0c5"
                            color: copyBtn.selected ? Theme.base : Theme.text
                            font.family: Theme.fontIcon
                            font.pixelSize: 20
                            Behavior on color { ColorAnimation { duration: Metrics.animBase } }
                        }
                        
                        onClicked: clipboardRoot.copyItem(modelData.rawLine)
                    }

                    // --- 2. MAIN CONTENT BODY ---
                    ThemeButton {
                        id: contentBody
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        selected: delegateRoot.isActive 
                        clip: true 
                        
                        color: delegateRoot.isActive ? Theme.main : "transparent"
                        border.width: contentHover.hovered ? 1 : 0
                        border.color: contentHover.hovered ? Theme.base : "transparent"
                        
                        HoverHandler {
                            id: contentHover
                            onHoveredChanged: { if (hovered) clipList.currentIndex = index }
                        }
                        
                        onClicked: {
                            delegateRoot.isExpanded = !delegateRoot.isExpanded;
                            if (delegateRoot.isExpanded && typeof textContentEdit !== "undefined" && textContentEdit) {
                                textContentEdit.forceActiveFocus();
                            }
                        }

                        // --- COLLAPSED VIEW ---
                        Text {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.topMargin: 12
                            anchors.leftMargin: Metrics.spacingBase
                            anchors.rightMargin: Metrics.spacingBase
                            
                            textFormat: Text.StyledText 
                            
                            text: {
                                let t = delegateRoot.decodedText || "";
                                if (t.indexOf('\n') !== -1) {
                                    t = t.substring(0, t.indexOf('\n')) + "...";
                                }
                                if (t.length > 120) {
                                    t = t.substring(0, 120) + "...";
                                }
                                return clipboardRoot.formatContent(t, clipboardRoot.searchQuery);
                            }
                            
                            color: delegateRoot.isActive ? Theme.base : Theme.text
                            font.family: Theme.fontMain   
                            font.pixelSize: 18   
                            font.weight: Font.Medium
                            
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                            elide: Text.ElideRight 
                            
                            opacity: delegateRoot.isImage || delegateRoot.isExpanded ? 0 : 1
                            visible: opacity > 0 
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            Behavior on color { ColorAnimation { duration: Metrics.animBase } }
                        }

                        // --- EXPANDED VIEW ---
                        Item {
                            anchors.fill: parent
                            
                            opacity: !delegateRoot.isImage && delegateRoot.isExpanded ? 1 : 0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            Flickable {
                                id: textFlickable
                                anchors.fill: parent
                                anchors.margins: Metrics.spacingBase
                                contentHeight: textContentEdit.implicitHeight
                                clip: true
                                
                                interactive: delegateRoot.isExpanded && textContentEdit.implicitHeight > parent.height
                                
                                ScrollBar.vertical: ScrollBar {
                                    width: 6
                                    policy: textContentEdit.implicitHeight > parent.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                                }

                                TextEdit {
                                    id: textContentEdit
                                    width: parent.width - 25 
                                    
                                    readOnly: true
                                    selectByMouse: true
                                    persistentSelection: true
                                    activeFocusOnPress: true
                                    
                                    textFormat: Text.RichText
                                    text: clipboardRoot.formatContent(delegateRoot.decodedText, clipboardRoot.searchQuery)
                                    
                                    color: delegateRoot.isActive ? Theme.base : Theme.text
                                    font.family: Theme.fontMain   
                                    font.pixelSize: 18   
                                    font.weight: Font.Medium
                                    
                                    wrapMode: TextEdit.WrapAnywhere
                                    
                                    Behavior on color { ColorAnimation { duration: Metrics.animBase } }

                                    Keys.onPressed: (event) => {
                                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_C) {
                                            if (textContentEdit.selectedText !== "") {
                                                clipboardRoot.copyString(textContentEdit.selectedText)
                                                event.accepted = true
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                width: 30
                                height: 30
                                anchors.right: parent.right
                                anchors.top: parent.top
                                z: 10

                                Text {
                                    anchors.centerIn: parent
                                    text: "▲"
                                    color: delegateRoot.isActive ? Theme.base : Theme.text
                                    font.pixelSize: 14
                                }

                                TapHandler {
                                    acceptedButtons: Qt.LeftButton
                                    cursorShape: Qt.PointingHandCursor
                                    onTapped: { delegateRoot.isExpanded = false }
                                }
                            }
                        }
                        
                        // --- IMAGE RENDERER ---
                        Item {
                            visible: delegateRoot.isImage
                            anchors.fill: parent
                            anchors.margins: Metrics.spacingBase
                            
                            Text {
                                visible: !delegateRoot.imageCached
                                text: "🖼️ Loading Image..."
                                color: delegateRoot.isActive ? Theme.base : Theme.text
                                anchors.centerIn: parent
                                font.family: Theme.fontMain
                                font.pixelSize: 16
                            }
                            
                            Image {
                                anchors.fill: parent
                                visible: delegateRoot.imageCached
                                source: delegateRoot.imageCached ? "file://" + delegateRoot.imagePath : ""
                                fillMode: Image.PreserveAspectFit
                                horizontalAlignment: Image.AlignLeft
                            }
                        }
                    }
                    
                    // --- 3. SYMMETRICAL RIGHT SPACER ---
                    // This creates an invisible empty space matching the exact width of the left copy button (60px).
                    // This naturally forces the text body to stop expanding before it gets cut off!
                    Item {
                        Layout.preferredWidth: 60
                        Layout.fillHeight: true
                    }
                }
            }
        }

        // --- BOTTOM ACTION ROW ---
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Metrics.spacingLarge
            Layout.rightMargin: Metrics.spacingLarge
            spacing: Metrics.spacingBase

            ThemeButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 45
                
                HoverHandler { id: btn1Hover }
                color: clipboardRoot.imagesOnly ? Theme.main : "transparent"
                border.width: btn1Hover.hovered ? 1 : 0
                border.color: btn1Hover.hovered ? (clipboardRoot.imagesOnly ? Theme.base : Theme.main) : "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: clipboardRoot.imagesOnly ? "🖼️ Showing Images" : "📄 Showing All"
                    color: clipboardRoot.imagesOnly ? Theme.base : Theme.text
                    font.family: Theme.fontMain
                    font.pixelSize: 16
                    font.weight: Font.Medium
                }
                
                onClicked: {
                    clipboardRoot.imagesOnly = !clipboardRoot.imagesOnly
                    clipList.currentIndex = -1 
                    searchInput.forceActiveFocus() 
                }
            }

            ThemeButton {
                Layout.preferredWidth: 160
                Layout.preferredHeight: 45
                
                HoverHandler { id: btn2Hover }
                color: "transparent"
                border.width: btn2Hover.hovered ? 1 : 0
                border.color: btn2Hover.hovered ? Theme.urgent : "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: "🗑️ Clear History"
                    color: Theme.urgent
                    font.family: Theme.fontMain
                    font.pixelSize: 16
                    font.weight: Font.Medium
                }
                
                onClicked: {
                    wipeProcess.running = true
                    clipboardRoot.clipboardDatabase = [] 
                    searchInput.forceActiveFocus()
                }
            }
        }
    }
}
