import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "../../../theme"

Item {
    id: weatherRoot
    
    // Allows the Bar's RowLayout to size this component correctly
    Layout.preferredWidth: contentLayout.implicitWidth
    Layout.fillHeight: true

    property string condition: "Loading"
    property string temperature: "--°C"

    // Maps the text-based weather condition to your Nerd Font icons
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
    // Triggers immediately on start, then updates every 30 minutes
    Timer {
        interval: 1800000 // 30 minutes in milliseconds
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            weatherProcess.running = true;
        }
    }

    // 2. The Weather Fetcher
    Process {
        id: weatherProcess
        running: false
        
        // Asks for format: "Condition|Temperature" (e.g., "Partly cloudy|+29°C")
        // --max-time 10 ensures the process dies gracefully if your internet drops
        command: ["bash", "-c", "curl -s --max-time 10 'wttr.in/Thiruvananthapuram?format=%C|%t'"]
        
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split('|');
                if (parts.length >= 2) {
                    weatherRoot.condition = parts[0].trim();
                    // Clean up the output (removes the explicit '+' sign on positive temperatures)
                    weatherRoot.temperature = parts[1].trim().replace("+", ""); 
                }
            }
        }
        
        stderr: SplitParser {
            onRead: data => console.log("[Weather Error]:", data)
        }
    }

    // 3. The UI
    RowLayout {
        id: contentLayout
        anchors.right: parent.right 
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Text {
            id: weatherIcon
            text: weatherRoot.getWeatherIcon(weatherRoot.condition)
            
            font.family: Theme.fontIcon
            font.pixelSize: 18
            
            color: weatherMouseArea.containsMouse ? Theme.main : Theme.text
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            id: weatherTemp
            text: weatherRoot.temperature
            
            font.family: Theme.fontMain
            font.pixelSize: 16
            font.bold: true
            
            color: weatherMouseArea.containsMouse ? Theme.main : Theme.text
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    // Hover effect
    MouseArea {
        id: weatherMouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
