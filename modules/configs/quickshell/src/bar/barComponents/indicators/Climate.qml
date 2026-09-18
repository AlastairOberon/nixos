import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "../../../theme"

Item {
    id: weatherRoot
    
    Layout.preferredWidth: contentLayout.implicitWidth + 16
    Layout.preferredHeight: 30
    Layout.fillHeight: true

    property bool isActive: typeof myLauncher !== "undefined" && 
                            myLauncher.window && 
                            myLauncher.window.visible && 
                            myLauncher.window.currentTabIndex === 9

    property string condition: "Loading"
    property string temperature: "--°C"

    // Maps the text-based weather condition to Nerd Font icons
    function getWeatherIcon(cond) {
        let c = cond.toLowerCase();
        if (c.includes("sunny") || c.includes("clear")) return "󰖙"; // nf-md-weather_sunny
        if (c.includes("partly")) return "󰖕"; // nf-md-weather_partly_cloudy
        if (c.includes("cloud") || c.includes("overcast")) return "󰖐"; // nf-md-weather_cloudy
        if (c.includes("rain") || c.includes("drizzle") || c.includes("shower")) return "󰖖"; // nf-md-weather_rainy
        if (c.includes("thunder") || c.includes("storm")) return "󰖓"; // nf-md-weather_lightning
        if (c.includes("fog") || c.includes("mist") || c.includes("haze")) return "󰖑"; // nf-md-weather_fog
        if (c.includes("snow") || c.includes("ice") || c.includes("blizzard")) return "󰖘"; // nf-md-weather_snowy
        
        return "󰖙"; // Default fallback
    }

    // 1. The Updater Timer
    Timer {
        interval: 1800000 // 30 minutes in milliseconds
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherRoot.fetchWeather()
    }

    Connections {
        target: Settings
        function onSettingsSaved() { weatherRoot.fetchWeather() }
    }

    function fetchWeather() {
        let city = (Settings.weatherLocation || "Kakkanad").split(",")[0].trim().replace(/\s*\(Home\)/i, "");
        let url = Settings.weatherIsFahrenheit 
            ? ("wttr.in/" + encodeURIComponent(city) + "?u&format=%C|%t") 
            : ("wttr.in/" + encodeURIComponent(city) + "?format=%C|%t");
        weatherProcess.running = false;
        weatherProcess.command = ["bash", "-c", "curl -s --max-time 10 '" + url + "'"];
        weatherProcess.running = true;
    }

    // 2. The Weather Fetcher
    Process {
        id: weatherProcess
        running: false 
        
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split('|');
                if (parts.length >= 2) {
                    weatherRoot.condition = parts[0].trim();
                    weatherRoot.temperature = parts[1].trim().replace("+", ""); 
                }
            }
        }
        
        stderr: SplitParser {
            onRead: data => console.log("[Weather Error]:", data)
        }
    }

    // The Highlight Pill Background
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: weatherRoot.isActive ? Theme.secondary : (weatherMouseArea.containsMouse ? Theme.urgent : "transparent")
        
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }

    // 3. The UI
    RowLayout {
        id: contentLayout
        anchors.centerIn: parent
        spacing: 8

        Text {
            id: weatherIcon
            text: weatherRoot.getWeatherIcon(weatherRoot.condition)
            
            font.family: Theme.fontIcon
            font.pixelSize: 18
            
            color: (weatherRoot.isActive || weatherMouseArea.containsMouse) ? Theme.base : Theme.text
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            id: weatherTemp
            text: weatherRoot.temperature
            
            font.family: Theme.fontMain
            font.pixelSize: 16
            font.bold: true
            
            color: (weatherRoot.isActive || weatherMouseArea.containsMouse) ? Theme.base : Theme.text
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: weatherMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            if (typeof myLauncher !== "undefined" && myLauncher.window) {
                if (weatherRoot.isActive) {
                    myLauncher.window.visible = false;
                } else {
                    myLauncher.window.visible = true;
                    myLauncher.window.currentTabIndex = 9;
                }
            }
        }
    }
}
