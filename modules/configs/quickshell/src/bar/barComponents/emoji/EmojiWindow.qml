import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io 

import "../../../theme" as Theme
import "../../../theme/components" as Components

Components.Template_Floating {
    id: emojiWindow
    
    windowWidth: 600
    windowHeight: 700
    visible: false
    focusable: true 

    property string searchQuery: ""
    property string selectedMainCategory: "All"
    property string selectedSubCategory: "All"
    WlrLayershell.namespace: "quickshell"

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
                    
                    emojiWindow.emojiDatabase = validEmojis.map(e => {
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
                    
                    emojiWindow.categoryTree = pTree;
                    emojiWindow.mainCategories = mCats;
                    
                } catch (e) {
                    console.log("Emoji JSON Parse Error: " + e.message);
                }
            }
        }
    }

    // ==========================================
    // COPY UTILITY
    // ==========================================
    Process { id: copyProcess }

    function copyEmoji(emojiChar) {
        console.log("Copying emoji: " + emojiChar)
        const safeChar = emojiChar.replace(/'/g, "'\\''")
        copyProcess.command = ["sh", "-c", `printf "%s" '${safeChar}' | wl-copy`]
        copyProcess.running = true
        emojiWindow.visible = false
    }

    onVisibleChanged: {
        if (visible) {
            searchQuery = ""
            searchInput.text = ""
            selectedMainCategory = "All"
            selectedSubCategory = "All"
            searchInput.forceActiveFocus()
            emojiList.currentIndex = -1
        }
    }

    // ==========================================
    // UI LAYOUT
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.Metrics.spacingLarge
        anchors.margins: Theme.Metrics.spacingLarge

        // --- SEARCH BAR ---
        TextField {
            id: searchInput
            Layout.fillWidth: true
            Layout.preferredHeight: 60   
            placeholderText: "Search emojis"
            color: Theme.Theme.text 
            
            font.family: Theme.Theme.fontMain   
            font.pixelSize: 24   
            verticalAlignment: TextInput.AlignVCenter
            
            background: Rectangle {
                color: Theme.Theme.bridge
                radius: Theme.Metrics.radiusBase
                border.width: 0
            }
            
            onTextChanged: {
                emojiWindow.searchQuery = text.toLowerCase().trim()
                emojiList.currentIndex = -1 
            }
            
            Keys.onDownPressed: {
                if (emojiList.currentIndex < 0) emojiList.currentIndex = 0; 
                else emojiList.currentIndex = Math.min(emojiList.currentIndex + 1, emojiList.count - 1);
            }
            Keys.onUpPressed: {
                if (emojiList.currentIndex <= 0) emojiList.currentIndex = emojiList.count - 1; 
                else emojiList.currentIndex = Math.max(emojiList.currentIndex - 1, 0);
            }
            Keys.onReturnPressed: {
                const targetIndex = emojiList.currentIndex >= 0 ? emojiList.currentIndex : 0;
                const currentItem = emojiList.model[targetIndex]
                if (currentItem) emojiWindow.copyEmoji(currentItem.emoji)
            }
            Keys.onEscapePressed: emojiWindow.visible = false
        }

        // --- MAIN CATEGORY TABS ---
        ListView {
            id: mainCategoryTabs
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            orientation: ListView.Horizontal
            spacing: Theme.Metrics.spacingSmall
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            
            model: {
                // Return all if no search query
                if (emojiWindow.searchQuery === "") return emojiWindow.mainCategories;
                
                // Otherwise, filter the tabs that match the query (always keeping "All")
                return emojiWindow.mainCategories.filter(cat => 
                    cat === "All" || cat.toLowerCase().includes(emojiWindow.searchQuery)
                );
            }

            delegate: Components.ThemeButton {
                required property int index
                required property string modelData

                width: tabText.implicitWidth + (Theme.Metrics.spacingLarge * 2)
                height: mainCategoryTabs.height
                
                color: emojiWindow.selectedMainCategory === modelData ? Theme.Theme.main : Theme.Theme.bridge
                border.width: 0
                border.color: "transparent"

                Text {
                    id: tabText
                    anchors.centerIn: parent
                    text: modelData
                    color: emojiWindow.selectedMainCategory === modelData ? Theme.Theme.base : Theme.Theme.text
                    font.family: Theme.Theme.fontMain
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    Behavior on color { ColorAnimation { duration: Theme.Metrics.animBase } }
                }

                onClicked: {
                    emojiWindow.selectedMainCategory = modelData
                    emojiWindow.selectedSubCategory = "All" 
                    emojiList.currentIndex = -1
                    searchInput.forceActiveFocus()
                }
            }
        }

        // --- SUB CATEGORY TABS (NESTED LAYER) ---
        ListView {
            id: subCategoryTabs
            visible: emojiWindow.selectedMainCategory !== "All"
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 35 : 0 
            orientation: ListView.Horizontal
            spacing: Theme.Metrics.spacingSmall
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            
            model: {
                let baseList = emojiWindow.selectedMainCategory !== "All" ? emojiWindow.categoryTree[emojiWindow.selectedMainCategory] : [];
                
                if (emojiWindow.searchQuery === "") return baseList;
                
                // Filter the sub-tabs based on the search query as well
                return baseList.filter(sub => 
                    sub === "All" || sub.replace(/-/g, ' ').toLowerCase().includes(emojiWindow.searchQuery)
                );
            }

            delegate: Components.ThemeButton {
                required property int index
                required property string modelData

                width: subTabText.implicitWidth + (Theme.Metrics.spacingLarge * 2)
                height: subCategoryTabs.height
                
                color: emojiWindow.selectedSubCategory === modelData ? Qt.darker(Theme.Theme.main, 1.2) : Qt.darker(Theme.Theme.bridge, 1.2)
                border.width: 0
                border.color: "transparent"

                Text {
                    id: subTabText
                    anchors.centerIn: parent
                    text: modelData.replace(/-/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
                    color: emojiWindow.selectedSubCategory === modelData ? Theme.Theme.base : Theme.Theme.text
                    font.family: Theme.Theme.fontMain
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    Behavior on color { ColorAnimation { duration: Theme.Metrics.animBase } }
                }

                onClicked: {
                    emojiWindow.selectedSubCategory = modelData
                    emojiList.currentIndex = -1
                    searchInput.forceActiveFocus()
                }
            }
        }

        // --- EMOJI LIST VIEW ---
        Components.FadedList {
            id: emojiList
            Layout.fillWidth: true
            Layout.fillHeight: true 
            spacing: Theme.Metrics.spacingSmall
            
            model: {
                let filteredData = emojiWindow.emojiDatabase;
                
                if (emojiWindow.selectedMainCategory !== "All") {
                    filteredData = filteredData.filter(item => item.mainCategory === emojiWindow.selectedMainCategory);
                    
                    if (emojiWindow.selectedSubCategory !== "All") {
                        filteredData = filteredData.filter(item => item.subCategory === emojiWindow.selectedSubCategory);
                    }
                }
                
                if (emojiWindow.searchQuery !== "") {
                    filteredData = filteredData.filter(item => item.searchStr.includes(emojiWindow.searchQuery));
                }
                
                return filteredData;
            }
            
            delegate: Components.ThemeButton {
                id: delegateRoot 
                required property int index
                required property var modelData
                
                width: emojiList.width - (Theme.Metrics.spacingBase * 2)
                height: 80 
                selected: emojiList.currentIndex === index
                
                color: delegateRoot.isActive ? Theme.Theme.main : "transparent"
                border.width: 0
                border.color: "transparent"
                
                onClicked: { emojiWindow.copyEmoji(modelData.emoji) }
                
                HoverHandler {
                    id: delegateHover
                    onHoveredChanged: { if (hovered) emojiList.currentIndex = index }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.Metrics.spacingBase
                    spacing: Theme.Metrics.spacingLarge

                    Text {
                        text: modelData.emoji
                        font.family: Theme.Theme.fontMain
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
                            color: delegateRoot.isActive ? Theme.Theme.base : Theme.Theme.text
                            font.family: Theme.Theme.fontMain   
                            font.pixelSize: 22   
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Behavior on color { ColorAnimation { duration: Theme.Metrics.animBase } }
                        }

                        Text {
                            text: modelData.tags
                            color: delegateRoot.isActive ? Qt.rgba(Theme.Theme.base.r, Theme.Theme.base.g, Theme.Theme.base.b, 0.7) : Qt.lighter(Theme.Theme.text, 1.5)
                            font.family: Theme.Theme.fontMain   
                            font.pixelSize: 16   
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            visible: modelData.tags !== ""
                            Behavior on color { ColorAnimation { duration: Theme.Metrics.animBase } }
                        }
                    }
                }
            }
        }
    }
}
