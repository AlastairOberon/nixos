import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io

import "../../../theme" 
import "../../../theme/components" 

Item {
    id: dashboardRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    // --- SYSTEM DATA PROPERTIES ---
    property string sysOs: "Loading..."
    property string sysKernel: "Loading..."
    property string sysUptime: "Loading..."
    property string sysWm: "Loading..."
    property string sysWallpaper: ""

    // ==========================================
    // BACKEND: FETCH SYSTEM INFO
    // ==========================================
    Process {
        id: sysInfoPoller
        command: [
            "bash", "-c",
            "fastfetch --logo none; echo '---WP---'; hyprctl hyprpaper listactive 2>/dev/null | grep -o '/.*' | head -n 1 | tr -d '\n'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parts = this.text.split("---WP---");
                    let fetchOutput = parts[0].trim().split('\n');
                    let wpOutput = parts.length > 1 ? parts[1].trim() : "";

                    for (let i = 0; i < fetchOutput.length; i++) {
                        let line = fetchOutput[i];
                        if (line.match(/OS\s*➜/)) dashboardRoot.sysOs = line.split("➜")[1].trim();
                        else if (line.match(/Kernel\s*➜/)) dashboardRoot.sysKernel = line.split("➜")[1].trim();
                        else if (line.match(/Uptime\s*➜/)) dashboardRoot.sysUptime = line.split("➜")[1].trim();
                        else if (line.match(/WM\s*➜/)) dashboardRoot.sysWm = line.split("➜")[1].trim();
                    }

                    if (wpOutput !== "") dashboardRoot.sysWallpaper = "file://" + wpOutput;
                } catch(e) {
                    console.log("Fastfetch Parse Error: " + e.message);
                }
            }
        }
    }

    Timer {
        interval: 60000 
        running: dashboardRoot.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: sysInfoPoller.running = true
    }
    
    onVisibleChanged: {
        if (visible) sysInfoPoller.running = true;
    }

    // ==========================================
    // UI LAYOUT
    // ==========================================
    GridLayout {
        anchors.fill: parent
        anchors.margins: Metrics.spacingLarge
        columns: 6
        rows: 4
        columnSpacing: Metrics.spacingLarge
        rowSpacing: Metrics.spacingLarge

        // ==========================================
        // TOP HALF 
        // ==========================================
        
        // 1. SYSTEM INFO CARD
        Rectangle {
            Layout.column: 0
            Layout.row: 0
            Layout.columnSpan: 4
            Layout.rowSpan: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 160 
            Layout.preferredHeight: 90 
            color: Theme.base
            radius: Metrics.radiusBase
            clip: true

            Image {
                id: sysBg
                source: dashboardRoot.sysWallpaper
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                visible: false 
                cache: false
            }

            MultiEffect {
                anchors.fill: parent
                source: sysBg
                blurEnabled: true
                blurMax: 64
                blur: 1.0
                colorizationColor: "#000000"
                colorization: 0.65 
                visible: dashboardRoot.sysWallpaper !== ""
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.darker(Theme.main, 2.5)
                visible: dashboardRoot.sysWallpaper === ""
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: Metrics.spacingLarge * 3
                spacing: Metrics.spacingLarge * 3

                // NIXOS NERD FONT ICON
                Text {
                    text: "\uf313" 
                    color: "white" 
                    font.family: Theme.fontIcon
                    font.pixelSize: 130 
                    Layout.alignment: Qt.AlignVCenter
                    opacity: 0.95
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 10

                    Text {
                        text: "System Information"
                        color: "white"
                        font.family: Theme.fontMain
                        font.pixelSize: 26
                        font.weight: Font.Bold
                        Layout.bottomMargin: 8
                    }

                    RowLayout {
                        spacing: 16
                        Text { text: "\uf108"; color: "white"; font.family: Theme.fontIcon; font.pixelSize: 16; opacity: 0.7 }
                        Text { text: dashboardRoot.sysOs; color: "white"; font.family: Theme.fontMain; font.pixelSize: 16; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                    
                    RowLayout {
                        spacing: 16
                        Text { text: "\uf013"; color: "white"; font.family: Theme.fontIcon; font.pixelSize: 16; opacity: 0.7 }
                        Text { text: dashboardRoot.sysKernel; color: "white"; font.family: Theme.fontMain; font.pixelSize: 16; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                    }

                    RowLayout {
                        spacing: 16
                        Text { text: "\uf2d0"; color: "white"; font.family: Theme.fontIcon; font.pixelSize: 16; opacity: 0.7 }
                        Text { text: dashboardRoot.sysWm; color: "white"; font.family: Theme.fontMain; font.pixelSize: 16; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                    }

                    RowLayout {
                        spacing: 16
                        Text { text: "\uf017"; color: "white"; font.family: Theme.fontIcon; font.pixelSize: 16; opacity: 0.7 }
                        Text { text: dashboardRoot.sysUptime; color: "white"; font.family: Theme.fontMain; font.pixelSize: 16; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                }
            }
        }

        // 2. Tall Orange Box
        Rectangle {
            Layout.column: 4
            Layout.row: 0
            Layout.columnSpan: 1
            Layout.rowSpan: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            Layout.preferredHeight: 90
            color: "#FF6600"
            radius: Metrics.radiusBase
        }

        // 3. Tall Yellow Box
        Rectangle {
            Layout.column: 5
            Layout.row: 0
            Layout.columnSpan: 1
            Layout.rowSpan: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            Layout.preferredHeight: 90
            color: "#FFFF00"
            radius: Metrics.radiusBase
        }

        // ==========================================
        // BOTTOM HALF 
        // ==========================================
        
        // 4. WEATHER WIDGET
        Rectangle {
            id: weatherWidget
            Layout.column: 0
            Layout.row: 2
            Layout.columnSpan: 2
            Layout.rowSpan: 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 80
            Layout.preferredHeight: 80
            color: Qt.darker(Theme.base, 1.2)
            radius: Metrics.radiusBase
            clip: true

            property int currentTemp: 0
            property int feelsLike: 0
            property int dayTemp: 0
            property int nightTemp: 0
            property string weatherDesc: "Loading..."
            property string weatherIcon: "\uf0c2"
            property bool isFahrenheit: false

            function getTemp(celsius) {
                return isFahrenheit ? Math.round((celsius * 9/5) + 32) : celsius;
            }

            function getFaIconFromWmo(code, isDay) {
                if (code === 0) return isDay ? "\uf185" : "\uf186";
                if (code === 1 || code === 2) return isDay ? "\uf185" : "\uf0c2";
                if (code === 3 || (code >= 45 && code <= 48)) return "\uf0c2";
                if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return "\uf043";
                if (code >= 71 && code <= 77) return "\uf2dc";
                if (code >= 95) return "\uf0e7";
                return isDay ? "\uf185" : "\uf0c2";
            }

            function fetchOpenMeteoData() {
                var lat = 10.0158;
                var lon = 76.3418;
                var url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon +
                          "&current=temperature_2m,apparent_temperature,is_day,weather_code" +
                          "&daily=temperature_2m_max,temperature_2m_min" +
                          "&timezone=auto";

                var xhr = new XMLHttpRequest();
                xhr.open("GET", url);
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                        try {
                            var data = JSON.parse(xhr.responseText);
                            weatherWidget.currentTemp = Math.round(data.current.temperature_2m);
                            weatherWidget.feelsLike = Math.round(data.current.apparent_temperature);
                            weatherWidget.dayTemp = Math.round(data.daily.temperature_2m_max[0]);
                            weatherWidget.nightTemp = Math.round(data.daily.temperature_2m_min[0]);
                            weatherWidget.weatherDesc = (data.current.weather_code === 0) ? "Clear Sky" : ((data.current.weather_code <= 3) ? "Partly Cloudy" : "Overcast");
                            weatherWidget.weatherIcon = weatherWidget.getFaIconFromWmo(data.current.weather_code, data.current.is_day);
                        } catch (e) {
                            console.log("Mini Weather Error: " + e);
                        }
                    }
                }
                xhr.send();
            }

            Timer {
                interval: 300000 
                running: dashboardRoot.visible
                repeat: true
                triggeredOnStart: true
                onTriggered: weatherWidget.fetchOpenMeteoData()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Metrics.spacingLarge
                spacing: 0

                Item { Layout.fillHeight: true } // Flexible top padding

                // TOP HALF: Icon & Status
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    Text {
                        text: weatherWidget.weatherIcon
                        color: Theme.main
                        font.family: Theme.fontIcon
                        font.pixelSize: 48 
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: weatherWidget.weatherDesc
                        color: Theme.text
                        font.family: Theme.fontMain
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: weatherWidget.getTemp(weatherWidget.currentTemp) + "°"
                        color: Theme.text
                        font.family: Theme.fontMain
                        font.pixelSize: 28
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                Item { Layout.fillHeight: true } // Flexible middle padding

                // CENTERED SEPARATOR
                Rectangle {
                    Layout.preferredWidth: parent.width * 0.85
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 1
                    color: Theme.bridge
                    opacity: 0.5
                }

                Item { Layout.preferredHeight: Metrics.spacingLarge }

                // BOTTOM HALF: Auxiliary Temps (Perfectly Centered)
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 24 

                    ColumnLayout {
                        spacing: 4
                        Text { text: "Feels Like"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6); font.family: Theme.fontMain; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter }
                        Text { text: weatherWidget.getTemp(weatherWidget.feelsLike) + "°"; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 18; font.weight: Font.Bold; Layout.alignment: Qt.AlignHCenter }
                    }
                    ColumnLayout {
                        spacing: 4
                        Text { text: "Max"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6); font.family: Theme.fontMain; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter }
                        Text { text: weatherWidget.getTemp(weatherWidget.dayTemp) + "°"; color: Theme.main; font.family: Theme.fontMain; font.pixelSize: 18; font.weight: Font.Bold; Layout.alignment: Qt.AlignHCenter }
                    }
                    ColumnLayout {
                        spacing: 4
                        Text { text: "Min"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6); font.family: Theme.fontMain; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter }
                        Text { text: weatherWidget.getTemp(weatherWidget.nightTemp) + "°"; color: Theme.secondary; font.family: Theme.fontMain; font.pixelSize: 18; font.weight: Font.Bold; Layout.alignment: Qt.AlignHCenter }
                    }
                }

                Item { Layout.fillHeight: true } // Flexible bottom padding
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: weatherWidget.isFahrenheit = !weatherWidget.isFahrenheit
                cursorShape: Qt.PointingHandCursor
            }
        }

        // 5. CLOCK & CALENDAR WIDGET (Formerly Green Box)
        Rectangle {
            id: clockWidget
            Layout.column: 2
            Layout.row: 2
            Layout.columnSpan: 2
            Layout.rowSpan: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 80
            Layout.preferredHeight: 40
            color: Qt.darker(Theme.base, 1.2)
            radius: Metrics.radiusBase
            clip: true

            property string timeStr: "00:00"
            property string secStr: "00"
            property string amPmStr: "AM"
            property string dayStr: "Monday"
            property string dateStr: "Jan 1, 1970"
            property string eventStr: "No upcoming events" // Placeholder for CLI calendar fetch

            function updateTime() {
                let d = new Date();
                
                let hours = d.getHours();
                let mins = d.getMinutes();
                let secs = d.getSeconds();
                
                clockWidget.amPmStr = hours >= 12 ? "PM" : "AM";
                
                hours = hours % 12;
                hours = hours ? hours : 12; 
                
                let minsStr = mins < 10 ? '0' + mins : mins;
                let secsStr = secs < 10 ? '0' + secs : secs;
                
                clockWidget.timeStr = hours + ":" + minsStr;
                clockWidget.secStr = secsStr;
                
                const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
                const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
                
                clockWidget.dayStr = days[d.getDay()];
                clockWidget.dateStr = months[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear();
            }

            Timer {
                interval: 1000
                running: dashboardRoot.visible
                repeat: true
                triggeredOnStart: true
                onTriggered: clockWidget.updateTime()
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: Metrics.spacingLarge * 2
                spacing: Metrics.spacingLarge

                // LEFT: Time
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 12
                    
                    Text {
                        text: "\uf017" 
                        color: Theme.main
                        font.family: Theme.fontIcon
                        font.pixelSize: 46
                        opacity: 0.8
                    }

                    Text {
                        text: clockWidget.timeStr
                        color: Theme.text
                        font.family: Theme.fontMain
                        font.pixelSize: 58
                        font.weight: Font.Bold
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: 8
                        spacing: -4
                        
                        Text {
                            text: clockWidget.amPmStr
                            color: Theme.secondary
                            font.family: Theme.fontMain
                            font.pixelSize: 18
                            font.weight: Font.Bold
                        }
                        Text {
                            text: clockWidget.secStr
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                            font.family: Theme.fontMain
                            font.pixelSize: 18
                        }
                    }
                }

                Item { Layout.fillWidth: true } 

                // RIGHT: Date & Notifier
                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    spacing: 4
                    
                    Text {
                        text: clockWidget.dayStr
                        color: Theme.main
                        font.family: Theme.fontMain
                        font.pixelSize: 26
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignRight
                    }
                    Text {
                        text: clockWidget.dateStr
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                        font.family: Theme.fontMain
                        font.pixelSize: 18
                        font.weight: Font.Medium
                        Layout.alignment: Qt.AlignRight
                    }
                    
                    // NEW: Date Notifier Row
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        Layout.topMargin: 4
                        spacing: 6
                        
                        Text {
                            text: "\uf073" 
                            color: Theme.secondary
                            font.family: Theme.fontIcon
                            font.pixelSize: 12
                        }
                        Text {
                            text: clockWidget.eventStr
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                            font.family: Theme.fontMain
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }

        // 6. Blue Box (Bottom Middle-Bottom)
        Rectangle {
            Layout.column: 2
            Layout.row: 3
            Layout.columnSpan: 2
            Layout.rowSpan: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 80
            Layout.preferredHeight: 40
            color: "#0000FF"
            radius: Metrics.radiusBase
        }

        // 7. Magenta Box (Bottom Right - Top Left)
        Rectangle {
            Layout.column: 4
            Layout.row: 2
            Layout.columnSpan: 1
            Layout.rowSpan: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            color: "#CC00FF"
            radius: Metrics.radiusBase
        }

        // 8. Dark Green Box (Bottom Right - Top Right)
        Rectangle {
            Layout.column: 5
            Layout.row: 2
            Layout.columnSpan: 1
            Layout.rowSpan: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            color: "#006633"
            radius: Metrics.radiusBase
        }

        // 9. Dark Blue Box (Bottom Right - Bottom Left)
        Rectangle {
            Layout.column: 4
            Layout.row: 3
            Layout.columnSpan: 1
            Layout.rowSpan: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            color: "#000099"
            radius: Metrics.radiusBase
        }

        // 10. Brown Box (Bottom Right - Bottom Right)
        Rectangle {
            Layout.column: 5
            Layout.row: 3
            Layout.columnSpan: 1
            Layout.rowSpan: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            color: "#993300"
            radius: Metrics.radiusBase
        }
    }
}
