import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io 

import "../../../theme" as Theme
import "../../../theme/components" as Components

Components.Template_Floating {
    id: clipWindow
    
    windowWidth: 600
    windowHeight: 700
    visible: false
    focusable: true 

    property string searchQuery: ""
    property bool imagesOnly: false 
    
    WlrLayershell.namespace: "quickshell"
    property var clipboardDatabase: []

    // ==========================================
    // ACTIVE ENTRY STATE
    // ==========================================
    property var activeEntry: clipboardDatabase.length > 0 ? clipboardDatabase[0] : null
    property bool activeIsImage: activeEntry ? activeEntry.content.includes("[[ binary data") : false
    property string activeImagePath: activeEntry ? "/tmp/qsh_clip_" + activeEntry.id + ".png" : ""
    
    // We track the source URL explicitly so we can force reloads if the disk cache lags
    property string activeImageSource: ""

    function checkAndExtractActiveImage() {
        if (!activeIsImage || !activeEntry) {
            activeImageSource = "";
            return;
        }

        // Optimistically tell the Image component to look for the file.
        activeImageSource = "file://" + activeImagePath;

        // Trigger the decode process to ensure file exists
        const safeLine = activeEntry.rawLine.replace(/'/g, "'\\''");
        activeExtractProcess.command = [
            "sh", "-c",
            `if [ ! -f "${clipWindow.activeImagePath}" ]; then echo '${safeLine}' | cliphist decode > "${clipWindow.activeImagePath}"; fi`
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

    function copyItem(rawLine) {
        console.log("Pasting full item to wl-clipboard...")
        const safeLine = rawLine.replace(/'/g, "'\\''")
        copyProcess.command = ["sh", "-c", `echo '${safeLine}' | cliphist decode | wl-copy`]
        copyProcess.running = true
        clipWindow.visible = false
    }

    function copyString(customText) {
        console.log("Pasting selection to wl-clipboard...")
        const safeLine = customText.replace(/'/g, "'\\''")
        copyProcess.command = ["sh", "-c", `printf "%s" '${safeLine}' | wl-copy`]
        copyProcess.running = true
        clipWindow.visible = false
    }

    // ==========================================
    // SHELL PROCESSES
    // ==========================================
    Process {
        id: activeExtractProcess
        stdout: StdioCollector {
            onStreamFinished: {
                // If the process finished but the image is stuck in an error/loading state,
                // we clear the source and set it back to force QML to reload the newly written file!
                if (activePreviewImage.status !== Image.Ready) {
                    clipWindow.activeImageSource = "";
                    clipWindow.activeImageSource = "file://" + clipWindow.activeImagePath;
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
                clipWindow.clipboardDatabase = newDb
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
            fetchProcess.running = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.Metrics.spacingLarge
        anchors.margins: Theme.Metrics.spacingLarge

        // --- ACTIVE ENTRY SECTION ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: activeIsImage ? 150 : 80
            color: Theme.Theme.bridge 
            radius: Theme.Metrics.radiusBase
            border.color: Theme.Theme.main
            border.width: 1
            visible: clipWindow.activeEntry !== null

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.Metrics.spacingBase
                spacing: 4

                // Header
                Text {
                    text: "TO BE PASTED (Ctrl+V)"
                    color: Theme.Theme.main
                    font.family: Theme.Theme.fontMain
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                // Text Content View
                Text {
                    visible: !clipWindow.activeIsImage
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: clipWindow.activeEntry ? clipWindow.activeEntry.content : ""
                    color: Theme.Theme.text
                    font.family: Theme.Theme.fontMain
                    font.pixelSize: 18
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                }

                // Image Content View
                Item {
                    visible: clipWindow.activeIsImage
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    Text {
                        // Automatically hides the moment the Image component successfully loads
                        visible: activePreviewImage.status !== Image.Ready
                        text: "🖼️ Loading Preview..."
                        color: Theme.Theme.text
                        anchors.centerIn: parent
                        font.family: Theme.Theme.fontMain
                        font.pixelSize: 14
                    }
                    
                    Image {
                        id: activePreviewImage
                        anchors.fill: parent
                        source: clipWindow.activeImageSource
                        visible: status === Image.Ready
                        fillMode: Image.PreserveAspectFit
                        horizontalAlignment: Image.AlignLeft
                        cache: false
                    }
                }
            }
        }

        // --- SEARCH BAR ---
        TextField {
            id: searchInput
            Layout.fillWidth: true
            Layout.preferredHeight: 60   
            placeholderText: "Search clipboard history..."
            color: Theme.Theme.text 
            
            font.family: Theme.Theme.fontMain   
            font.pixelSize: 24   
            verticalAlignment: TextInput.AlignVCenter
            
            background : Rectangle {
                color: Theme.Theme.bridge
                radius: Theme.Metrics.radiusBase
                border.width: 0
                border.color: "transparent"
            }
            
            onTextChanged: {
                clipWindow.searchQuery = text.toLowerCase()
                clipList.currentIndex = -1 
            }
            
            Keys.onDownPressed: {
                if (clipList.currentIndex < 0) clipList.currentIndex = 0; 
                else clipList.currentIndex = Math.min(clipList.currentIndex + 1, clipList.count - 1);
            }
            Keys.onUpPressed: {
                if (clipList.currentIndex <= 0) clipList.currentIndex = clipList.count - 1; 
                else clipList.currentIndex = Math.max(clipList.currentIndex - 1, 0);
            }
            Keys.onReturnPressed: {
                const targetIndex = clipList.currentIndex >= 0 ? clipList.currentIndex : 0;
                const currentItem = clipList.model[targetIndex]
                if (currentItem) clipWindow.copyItem(currentItem.rawLine)
            }
            Keys.onEscapePressed: clipWindow.visible = false
        }

        // --- CLIPBOARD LIST ---
        Components.FadedList {
            id: clipList
            Layout.fillWidth: true
            Layout.fillHeight: true 
            spacing: Theme.Metrics.spacingSmall
            
            model: {
                let data = clipWindow.clipboardDatabase
                if (clipWindow.imagesOnly) {
                    data = data.filter(item => item.content.includes("[[ binary data"))
                }
                const query = clipWindow.searchQuery.trim()
                if (query === "") return data
                return data.filter(item => {
                    return item.content && item.content.toLowerCase().includes(query)
                })
            }
            
            delegate: Components.ThemeButton {
                id: delegateRoot 
                required property int index
                required property var modelData
                
                property bool isImage: modelData.content.includes("[[ binary data")
                property string imagePath: "/tmp/qsh_clip_" + modelData.id + ".png"
                property bool imageCached: false
                
                property string decodedText: modelData.content 
                property bool isExpanded: false
                
                width: clipList.width - (Theme.Metrics.spacingBase * 2)
                
                // Height snaps instantly for flawless scroll performance
                height: isImage ? 150 : (delegateRoot.isExpanded ? 200 : 60)
                selected: clipList.currentIndex === index
                
                color: delegateRoot.isActive ? Theme.Theme.main : "transparent"
                border.width: 0
                border.color: "transparent"

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
                
                onClicked: {
                    if (!delegateRoot.isExpanded) {
                        delegateRoot.isExpanded = true
                        if (textContentEdit) textContentEdit.forceActiveFocus()
                    } else {
                        clipWindow.copyItem(modelData.rawLine)
                    }
                }

                // --- COLLAPSED VIEW ---
                Text {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 60
                    anchors.margins: Theme.Metrics.spacingBase
                    verticalAlignment: Text.AlignVCenter
                    
                    textFormat: Text.StyledText
                    text: clipWindow.formatContent(delegateRoot.decodedText, clipWindow.searchQuery)
                    
                    color: delegateRoot.isActive ? Theme.Theme.base : Theme.Theme.text
                    font.family: Theme.Theme.fontMain   
                    font.pixelSize: 18   
                    font.weight: Font.Medium
                    
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    
                    opacity: delegateRoot.isImage || delegateRoot.isExpanded ? 0 : 1
                    visible: opacity > 0 
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: Theme.Metrics.animBase } }
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
                        anchors.margins: Theme.Metrics.spacingBase
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
                            
                            textFormat: Text.StyledText
                            text: clipWindow.formatContent(delegateRoot.decodedText, clipWindow.searchQuery)
                            
                            color: delegateRoot.isActive ? Theme.Theme.base : Theme.Theme.text
                            font.family: Theme.Theme.fontMain   
                            font.pixelSize: 18   
                            font.weight: Font.Medium
                            wrapMode: TextEdit.Wrap
                            
                            Behavior on color { ColorAnimation { duration: Theme.Metrics.animBase } }

                            Keys.onPressed: (event) => {
                                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_C) {
                                    if (textContentEdit.selectedText !== "") {
                                        clipWindow.copyString(textContentEdit.selectedText)
                                        event.accepted = true
                                    }
                                }
                            }

                            TapHandler {
                                acceptedButtons: Qt.LeftButton
                                gesturePolicy: TapHandler.DragThreshold
                                onTapped: {
                                    if (textContentEdit.selectedText === "") {
                                        clipWindow.copyItem(modelData.rawLine)
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
                            color: delegateRoot.isActive ? Theme.Theme.base : Theme.Theme.text
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
                    anchors.margins: Theme.Metrics.spacingBase
                    
                    Text {
                        visible: !delegateRoot.imageCached
                        text: "🖼️ Loading Image..."
                        color: delegateRoot.isActive ? Theme.Theme.base : Theme.Theme.text
                        anchors.centerIn: parent
                        font.family: Theme.Theme.fontMain
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
        }

        // --- BOTTOM ACTION ROW ---
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.Metrics.spacingBase

            Components.ThemeButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 45
                color: clipWindow.imagesOnly ? Theme.Theme.main : Theme.Theme.bridge
                border.width: 0
                border.color: "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: clipWindow.imagesOnly ? "🖼️ Showing Images" : "📄 Showing All"
                    color: clipWindow.imagesOnly ? Theme.Theme.base : Theme.Theme.text
                    font.family: Theme.Theme.fontMain
                    font.pixelSize: 16
                    font.weight: Font.Medium
                }
                
                onClicked: {
                    clipWindow.imagesOnly = !clipWindow.imagesOnly
                    clipList.currentIndex = -1 
                    searchInput.forceActiveFocus() 
                }
            }

            Components.ThemeButton {
                Layout.preferredWidth: 160
                Layout.preferredHeight: 45
                color: Theme.Theme.urgent 
                border.width: 0
                border.color: "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: "🗑️ Clear History"
                    color: Theme.Theme.base
                    font.family: Theme.Theme.fontMain
                    font.pixelSize: 16
                    font.weight: Font.Medium
                }
                
                onClicked: {
                    wipeProcess.running = true
                    clipWindow.clipboardDatabase = [] 
                    searchInput.forceActiveFocus()
                }
            }
        }
    }
}
