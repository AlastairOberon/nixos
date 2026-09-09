pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // --- THE MAGIC: State Object ---
    property var themeData: null

    // --- Backgrounds (Pushed Darker) ---
    // 1.2 means 20% darker. Increase the number to make it even darker.
    property color base: themeData ? Qt.darker(themeData.special.background, 1.0) : "#181926"
    property color secondaryBase: themeData ? Qt.darker(themeData.colors.color8, 4.0) : "#24273a" 
    
    // --- Popup Architecture ---
    property color bridge: base 
    
    // --- Typography ---
    property color text: themeData ? themeData.special.foreground : "#cdd6f4"
    
    // --- Accents & States (Pushed Brighter) ---
    // 1.3 means 30% brighter. Increase the number to make it pop more.
    property color main: themeData ? Qt.lighter(themeData.colors.color4, 1.2) : "#c6a0f6"
    property color secondary: themeData ? Qt.lighter(themeData.colors.color6, 1.2) : "#7dc4e4"
    property color urgent: themeData ? themeData.colors.color1 : "#ed8796"
    property color inactive: themeData ? themeData.colors.color8 : "#6e738d"

    // ==========================================
    // --- DYNAMIC THEME ENGINE (PYWAL) ---
    // ==========================================
    
    property var jsonFile: FileView {
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        watchChanges: true
        
        onFileChanged: {
            // Triggers the timer we stored in the property below
            debounceTimer.restart();
        }
        
        onLoaded: updateTheme()
    }

    // --- THE RACE CONDITION FIX ---
    // We explicitly assign the Timer to a property so QtObject accepts it!
    property var timer: Timer {
        id: debounceTimer
        interval: 50 
        onTriggered: jsonFile.reload()
    }

    function updateTheme() {
        try {
            let rawText = jsonFile.text();
            
            // Protect against empty files during write cycles
            if (!rawText || rawText.trim() === "") {
                console.log("Quickshell Theme: Caught empty file from Pywal. Waiting...");
                return;
            }
            
            let data = JSON.parse(rawText);
            
            // This single assignment triggers QML to repaint EVERY linked color!
            root.themeData = data; 
            console.log("Quickshell Theme: Successfully updated colors from Pywal!");
            
        } catch (e) {
            console.log("Quickshell Theme Error: " + e.message);
        }
    }
}
