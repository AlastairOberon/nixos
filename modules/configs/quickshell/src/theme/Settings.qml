pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string configPath: Quickshell.env("HOME") + "/.cache/quickshell_JellyfishDungeon.json"

    // Default configuration object
    readonly property var defaultSettings: ({
        monitorScales: {},
        timeDate: {
            is24HourFormat: true,
            activeZones: [
                { name: "Kakkanad", country: "India", lat: 10.0158, lon: 76.3418, offset: 5.5 },
                { name: "London", country: "United Kingdom", lat: 51.5085, lon: -0.1257, offset: 0 },
                { name: "New York", country: "United States", lat: 40.7143, lon: -74.006, offset: -5 },
                { name: "Tokyo", country: "Japan", lat: 35.6895, lon: 139.6917, offset: 9 },
                { name: "Sydney", country: "Australia", lat: -33.8688, lon: 151.2093, offset: 10 }
            ]
        },
        weather: {
            source: "Open-Meteo",
            location: "Kakkanad, India",
            lat: 10.0158,
            lon: 76.3418,
            isFahrenheit: false
        }
    })

    // Active parsed state
    property var settings: JSON.parse(JSON.stringify(defaultSettings))

    // Convenience Reactive Properties
    property var monitorScales: settings.monitorScales || ({})
    property bool is24HourFormat: (settings.timeDate && settings.timeDate.is24HourFormat !== undefined) ? settings.timeDate.is24HourFormat : true
    property var activeZones: (settings.timeDate && settings.timeDate.activeZones) ? settings.timeDate.activeZones : defaultSettings.timeDate.activeZones
    
    property string weatherSource: (settings.weather && settings.weather.source) ? settings.weather.source : "Open-Meteo"
    property string weatherLocation: (settings.weather && settings.weather.location) ? settings.weather.location : "Kakkanad, India"
    property real weatherLat: (settings.weather && settings.weather.lat !== undefined) ? settings.weather.lat : 10.0158
    property real weatherLon: (settings.weather && settings.weather.lon !== undefined) ? settings.weather.lon : 76.3418
    property bool weatherIsFahrenheit: (settings.weather && settings.weather.isFahrenheit !== undefined) ? settings.weather.isFahrenheit : false

    // Signals for components to react
    signal settingsLoaded()
    signal settingsSaved()

    // File watcher
    property var jsonFile: FileView {
        path: root.configPath
        watchChanges: true
        onFileChanged: root.debounceTimer.restart()
        onLoaded: root.loadConfig()
    }

    property var debounceTimer: Timer {
        interval: 50
        onTriggered: root.jsonFile.reload()
    }

    // Startup & Auto-creation process
    property var initProcess: Process {
        id: initProcess
        command: [
            "bash", "-c",
            "if [ ! -f '" + root.configPath + "' ]; then " +
            "  echo '" + JSON.stringify(root.defaultSettings).replace(/'/g, "'\\''") + "' > '" + root.configPath + "'; " +
            "fi"
        ]
        onExited: {
            root.jsonFile.reload();
        }
    }

    property bool _isSaving: false
    property bool _pendingSave: false

    property var writeProcess: Process {
        id: writeProcess
        onExited: {
            root._isSaving = false;
            root.settingsSaved();
            if (root._pendingSave) {
                root._pendingSave = false;
                root.executeSave();
            }
        }
    }

    Component.onCompleted: {
        initProcess.running = true;
    }

    function loadConfig() {
        if (root._isSaving || root._pendingSave) return;
        try {
            let raw = jsonFile.text();
            if (!raw || raw.trim() === "") return;
            let parsed = JSON.parse(raw);

            // Merge with defaults to ensure all keys exist
            let merged = JSON.parse(JSON.stringify(defaultSettings));
            if (parsed.monitorScales) merged.monitorScales = parsed.monitorScales;
            if (parsed.timeDate) {
                if (parsed.timeDate.is24HourFormat !== undefined) merged.timeDate.is24HourFormat = parsed.timeDate.is24HourFormat;
                if (parsed.timeDate.activeZones) merged.timeDate.activeZones = parsed.timeDate.activeZones;
            }
            if (parsed.weather) {
                if (parsed.weather.source) merged.weather.source = parsed.weather.source;
                if (parsed.weather.location) merged.weather.location = parsed.weather.location;
                if (parsed.weather.lat !== undefined) merged.weather.lat = parsed.weather.lat;
                if (parsed.weather.lon !== undefined) merged.weather.lon = parsed.weather.lon;
                if (parsed.weather.isFahrenheit !== undefined) merged.weather.isFahrenheit = parsed.weather.isFahrenheit;
            }

            root.settings = merged;
            root.settingsLoaded();
        } catch(e) {
            console.log("[Settings] Error loading config: " + e.message);
        }
    }

    function saveConfig() {
        root.executeSave();
    }

    function executeSave() {
        if (root._isSaving) {
            root._pendingSave = true;
            return;
        }
        root._isSaving = true;
        root._pendingSave = false;

        let jsonStr = JSON.stringify(root.settings, null, 2);
        let script = "cat << 'EOF' > '" + root.configPath + ".tmp'\n" + jsonStr + "\nEOF\nmv '" + root.configPath + ".tmp' '" + root.configPath + "'";
        
        writeProcess.command = ["bash", "-c", script];
        writeProcess.running = true;
    }

    // --- Mutators ---

    function setMonitorScale(monName, scaleValue) {
        let newScales = Object.assign({}, root.monitorScales);
        newScales[monName] = scaleValue;
        
        let newSettings = JSON.parse(JSON.stringify(root.settings));
        newSettings.monitorScales = newScales;
        root.settings = newSettings;
        saveConfig();
    }

    function setTime24Hour(is24) {
        let newSettings = JSON.parse(JSON.stringify(root.settings));
        if (!newSettings.timeDate) newSettings.timeDate = {};
        newSettings.timeDate.is24HourFormat = is24;
        root.settings = newSettings;
        saveConfig();
    }

    function setActiveZones(zones) {
        let newSettings = JSON.parse(JSON.stringify(root.settings));
        if (!newSettings.timeDate) newSettings.timeDate = {};
        newSettings.timeDate.activeZones = zones;
        root.settings = newSettings;
        saveConfig();
    }

    function setTimeDateSettings(is24, zones) {
        let newSettings = JSON.parse(JSON.stringify(root.settings));
        if (!newSettings.timeDate) newSettings.timeDate = {};
        if (is24 !== undefined) newSettings.timeDate.is24HourFormat = is24;
        if (zones !== undefined) newSettings.timeDate.activeZones = zones;
        root.settings = newSettings;
        saveConfig();
    }

    function setWeather(source, location, lat, lon, isFahrenheit) {
        let newSettings = JSON.parse(JSON.stringify(root.settings));
        newSettings.weather = {
            source: source,
            location: location,
            lat: lat,
            lon: lon,
            isFahrenheit: isFahrenheit
        };
        root.settings = newSettings;
        saveConfig();
    }
}
