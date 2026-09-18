pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property var themeData          : null

    // Alpha Multiplier
    property real baseAlpha         : 0.8
    property real bridgeAlpha       : 1.0
    property real textAlpha         : 1.0
    property real mainAlpha         : 1.0
    property real secondaryAlpha    : 1.0
    property real urgentAlpha       : 1.0
    property real inactiveAlpha     : 1.0

    // Pywal Links
    property color base         : Qt.alpha(themeData ? themeData.special.background     : "#181926", baseAlpha)
    property color bridge       : Qt.alpha(themeData ? themeData.colors.color8          : "#24273a", bridgeAlpha)
    property color text         : Qt.alpha(themeData ? themeData.special.foreground     : "#cdd6f4", textAlpha)
    property color main         : Qt.alpha(themeData ? themeData.colors.color4          : "#c6a0f6", mainAlpha)
    property color secondary    : Qt.alpha(themeData ? themeData.colors.color6          : "#7dc4e4", secondaryAlpha)
    property color urgent       : Qt.alpha(themeData ? themeData.colors.color1          : "#ed8796", urgentAlpha)
    property color inactive     : Qt.alpha(themeData ? themeData.colors.color8          : "#6e738d", inactiveAlpha)

    // Semantic Border Colors
    property color borderNormal : base 
    property color borderHover  : main
    
    // Font Properties
    property string fontMain: "Monofur Nerd Font Mono"
    property string fontIcon: "Symbols Nerd Font"

    // --- MONITOR SCALING STATE ---
    property var monitorScales: Settings.monitorScales

    // Read the current scales from the system environment on first boot if not yet in settings
    Component.onCompleted: {
        let envString = Quickshell.env("QT_SCREEN_SCALE_FACTORS");
        if (envString && Object.keys(Settings.monitorScales).length === 0) {
            let parts = envString.split(";");
            for (let i = 0; i < parts.length; i++) {
                if (parts[i].indexOf("=") !== -1) {
                    let kv = parts[i].split("=");
                    Settings.setMonitorScale(kv[0], parseFloat(kv[1]));
                }
            }
        }
    }

    function setMonitorScale(monName, scale) {
        Settings.setMonitorScale(monName, scale);
    }

    function getMonitorScale(monName) {
        return (Settings.monitorScales && Settings.monitorScales[monName] !== undefined) 
            ? Settings.monitorScales[monName] : 1.0;
    }

    // Pywall Loader
    property var jsonFile : FileView {
        path            : Quickshell.env("HOME") + "/.cache/wal/colors.json"
        watchChanges    : true
        onFileChanged   : debounceTimer.restart()
        onLoaded        : updateTheme()
    }

    property var timer : Timer {
        id              : debounceTimer
        interval        : 50 
        onTriggered     : jsonFile.reload()
    }

    function updateTheme() {
        try {
            let rawText = jsonFile.text();
            if (!rawText || rawText.trim() === "") return;
            root.themeData = JSON.parse(rawText);
        } catch (e) {
            console.log("Theme Error: " + e.message);
        }
    }
}
