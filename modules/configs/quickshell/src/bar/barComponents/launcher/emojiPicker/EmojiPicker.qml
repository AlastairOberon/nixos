import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io 

import "../../../../theme" 
import "../../../../theme/components" 

Item {
    id: emojiPickerRoot
    
    property string searchQuery: ""
    property string selectedMainCategory: "All"
    property string selectedSubCategory: "All"

    // The parsed database and dynamic nested category trees
    property var emojiDatabase: []
    property var mainCategories: ["All"]
    property var categoryTree: ({})

    // ==========================================
    // 1. FETCH & PARSE FULL EMOJI JSON
    // ==========================================
    Process {
        id: fetchGemoji
        command: [
            "sh", "-c", 
            "if [ ! -f ~/.cache/full_unicode_emojis.json ]; then curl -sL https://raw.githubusercontent.com/amio/emoji.json/master/emoji.json > ~/.cache/full_unicode_emojis.json; fi; cat ~/.cache/full_unicode_emojis.json"
        ]
        running: true
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let rawText = this.text;
                    if (!rawText || rawText.trim() === "") return;
                    let parsed = JSON.parse(rawText);
                    
                    let validEmojis = parsed.filter(e => e.char);
                    let tempTree = {};
                    
                    emojiPickerRoot.emojiDatabase = validEmojis.map(e => {
                        let mainCat = e.group ? e.group : (e.category ? e.category.split("(")[0].trim() : "Uncategorized");
                        let subCat = e.subgroup ? e.subgroup : "General";
                        
                        if (!tempTree[mainCat]) tempTree[mainCat] = new Set();
                        tempTree[mainCat].add(subCat);
                        
                        let searchStr = (e.name + " " + mainCat + " " + subCat).toLowerCase();
                        
                        return {
                            emoji: e.char,
                            description: e.name,
                            mainCategory: mainCat,
                            subCategory: subCat,
                            tags: mainCat + " • " + subCat, 
                            searchStr: searchStr
                        };
                    });
                    
                    let mCats = ["All"];
                    let pTree = {};
                    for (let key in tempTree) {
                        mCats.push(key);
                        pTree[key] = ["All"].concat(Array.from(tempTree[key]));
                    }
                    
                    emojiPickerRoot.categoryTree = pTree;
                    emojiPickerRoot.mainCategories = mCats;
                    
                } catch (e) {
                    console.log("Emoji JSON Parse Error: " + e.message);
                }
            }
        }
    }

    // ==========================================
    // COPY UTILITY & WINDOW LOGIC
    // ==========================================
    Process { id: copyProcess }

    function closeWindow() {
        let p = emojiPickerRoot;
        while (p && !p.focusable) p = p.parent;
        if (p) p.visible = false;
    }

    function copyEmoji(emojiChar) {
        console.log("Copying emoji: " + emojiChar)
        const safeChar = emojiChar.replace(/'/g, "'\\''")
        copyProcess.command = ["sh", "-c", `printf "%s" '${safeChar}' | wl-copy`]
        copyProcess.running = true
        
        // Trigger the toast instead of closing instantly
        toastOverlay.opacity = 1;
        closeTimer.restart();
    }

    onVisibleChanged: {
        if (visible) {
            searchQuery = ""
            searchInput.text = ""
            selectedMainCategory = "All"
            selectedSubCategory = "All"
            searchInput.forceActiveFocus()
            emojiList.currentIndex = -1
            toastOverlay.opacity = 0 // Reset toast state
        }
    }

    // ==========================================
    // TOAST NOTIFICATION COMPONENT
    // ==========================================
    Rectangle {
        id: toastOverlay
        z: 100 // Forces it to render on top of the scrolling list!
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100 // Floats perfectly above the bottom edge
        
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
        interval: 800 // Delays closing for 800ms so you can see the toast
        onTriggered: {
            toastOverlay.opacity = 0;
            closeWindow();
        }
    }

    // ==========================================
    // UI LAYOUT
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        spacing: Metrics.spacingLarge
        anchors.topMargin: Metrics.spacingLarge
        anchors.bottomMargin: Metrics.spacingLarge

        // --- HEADER & SEARCH BAR CONTAINER ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Metrics.spacingLarge
            Layout.rightMargin: Metrics.spacingLarge
            spacing: 8

            Text {
                text: "Emoji Picker"
                color: Theme.main
                font.family: Theme.fontMain
                font.pixelSize: 14
                font.weight: Font.Bold
            }

            TextField {
                id: searchInput
                Layout.fillWidth: true
                Layout.preferredHeight: 60   
                placeholderText: "Search emojis..."
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
                }
                
                onTextChanged: {
                    emojiPickerRoot.searchQuery = text.toLowerCase().trim()
                    emojiList.currentIndex = -1 
                }
                
                Keys.onDownPressed: {
                    if (emojiList.currentIndex < emojiList.count - 1) {
                        emojiList.currentIndex++;
                    }
                }
                Keys.onUpPressed: {
                    if (emojiList.currentIndex > 0) {
                        emojiList.currentIndex--;
                    }
                }
                Keys.onReturnPressed: {
                    const targetIndex = emojiList.currentIndex >= 0 ? emojiList.currentIndex : 0;
                    const currentItem = emojiList.model[targetIndex]
                    if (currentItem) emojiPickerRoot.copyEmoji(currentItem.emoji)
                }
                Keys.onEscapePressed: emojiPickerRoot.closeWindow()
            }
        }

        // --- MAIN CATEGORY TABS ---
        ListView {
            id: mainCategoryTabs
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            Layout.leftMargin: Metrics.spacingLarge
            Layout.rightMargin: Metrics.spacingLarge
            orientation: ListView.Horizontal
            spacing: Metrics.spacingSmall
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            
            model: {
                if (emojiPickerRoot.searchQuery === "") return emojiPickerRoot.mainCategories;
                return emojiPickerRoot.mainCategories.filter(cat => 
                    cat === "All" || cat.toLowerCase().includes(emojiPickerRoot.searchQuery)
                );
            }

            delegate: ThemeButton {
                required property int index
                required property string modelData

                width: tabText.implicitWidth + (Metrics.spacingLarge * 2)
                height: mainCategoryTabs.height
                
                color: emojiPickerRoot.selectedMainCategory === modelData ? Theme.main : Theme.bridge
                border.width: 0
                border.color: "transparent"

                Text {
                    id: tabText
                    anchors.centerIn: parent
                    text: modelData
                    color: emojiPickerRoot.selectedMainCategory === modelData ? Theme.base : Theme.text
                    font.family: Theme.fontMain
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    Behavior on color { ColorAnimation { duration: Metrics.animBase } }
                }

                onClicked: {
                    emojiPickerRoot.selectedMainCategory = modelData
                    emojiPickerRoot.selectedSubCategory = "All" 
                    emojiList.currentIndex = -1
                    searchInput.forceActiveFocus()
                }
            }
        }

        // --- SUB CATEGORY TABS (NESTED LAYER) ---
        ListView {
            id: subCategoryTabs
            visible: emojiPickerRoot.selectedMainCategory !== "All"
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 35 : 0 
            Layout.leftMargin: Metrics.spacingLarge
            Layout.rightMargin: Metrics.spacingLarge
            orientation: ListView.Horizontal
            spacing: Metrics.spacingSmall
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            
            model: {
                let baseList = emojiPickerRoot.selectedMainCategory !== "All" ? emojiPickerRoot.categoryTree[emojiPickerRoot.selectedMainCategory] : [];
                if (emojiPickerRoot.searchQuery === "") return baseList;
                return baseList.filter(sub => 
                    sub === "All" || sub.replace(/-/g, ' ').toLowerCase().includes(emojiPickerRoot.searchQuery)
                );
            }

            delegate: ThemeButton {
                required property int index
                required property string modelData

                width: subTabText.implicitWidth + (Metrics.spacingLarge * 2)
                height: subCategoryTabs.height
                
                color: emojiPickerRoot.selectedSubCategory === modelData ? Qt.darker(Theme.main, 1.2) : Qt.darker(Theme.bridge, 1.2)
                border.width: 0
                border.color: "transparent"

                Text {
                    id: subTabText
                    anchors.centerIn: parent
                    text: modelData.replace(/-/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
                    color: emojiPickerRoot.selectedSubCategory === modelData ? Theme.base : Theme.text
                    font.family: Theme.fontMain
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    Behavior on color { ColorAnimation { duration: Metrics.animBase } }
                }

                onClicked: {
                    emojiPickerRoot.selectedSubCategory = modelData
                    emojiList.currentIndex = -1
                    searchInput.forceActiveFocus()
                }
            }
        }

        // --- EMOJI LIST VIEW ---
        FadedList {
            id: emojiList
            Layout.fillWidth: true
            Layout.fillHeight: true 
            spacing: Metrics.spacingSmall
            Layout.leftMargin: Metrics.spacingLarge
            Layout.rightMargin: Metrics.spacingLarge
            Layout.topMargin: 10
            Layout.bottomMargin: 20
            
            model: {
                let filteredData = emojiPickerRoot.emojiDatabase;
                
                if (emojiPickerRoot.selectedMainCategory !== "All") {
                    filteredData = filteredData.filter(item => item.mainCategory === emojiPickerRoot.selectedMainCategory);
                    
                    if (emojiPickerRoot.selectedSubCategory !== "All") {
                        filteredData = filteredData.filter(item => item.subCategory === emojiPickerRoot.selectedSubCategory);
                    }
                }
                
                if (emojiPickerRoot.searchQuery !== "") {
                    filteredData = filteredData.filter(item => item.searchStr.includes(emojiPickerRoot.searchQuery));
                }
                
                return filteredData;
            }
            
            delegate: ThemeButton {
                id: delegateRoot 
                required property int index
                required property var modelData
                
                width: emojiList.width - (Metrics.spacingBase * 2)
                height: 80 
                selected: emojiList.currentIndex === index
                
                color: delegateRoot.isActive ? Theme.main : "transparent"
                border.width: 0
                border.color: "transparent"
                
                onClicked: { emojiPickerRoot.copyEmoji(modelData.emoji) }
                
                HoverHandler {
                    id: delegateHover
                    onHoveredChanged: { if (hovered) emojiList.currentIndex = index }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Metrics.spacingBase
                    spacing: Metrics.spacingLarge

                    Text {
                        text: modelData.emoji
                        font.family: Theme.fontMain
                        font.pixelSize: 32
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 45 
                        horizontalAlignment: Text.AlignHCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2
                        clip: true 

                        Text {
                            text: modelData.description.charAt(0).toUpperCase() + modelData.description.slice(1) 
                            color: delegateRoot.isActive ? Theme.base : Theme.text
                            font.family: Theme.fontMain   
                            font.pixelSize: 22   
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Behavior on color { ColorAnimation { duration: Metrics.animBase } }
                        }

                        Text {
                            text: modelData.tags
                            color: delegateRoot.isActive ? Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.7) : Qt.lighter(Theme.text, 1.5)
                            font.family: Theme.fontMain   
                            font.pixelSize: 16   
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            visible: modelData.tags !== ""
                            Behavior on color { ColorAnimation { duration: Metrics.animBase } }
                        }
                    }
                }
            }
        }
    }
}
