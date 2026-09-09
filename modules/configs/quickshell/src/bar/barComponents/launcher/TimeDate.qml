import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

import "../../../theme" 
import "../../../theme/components" 

Item {
    id: timeDateRoot
    
    // --- TIME & FORMAT STATE ---
    property var currentTime: new Date()
    property string activeDateString: currentTime.toLocaleDateString(Qt.locale(), "dddd, MMMM d, yyyy")
    property int tick: 0 
    property bool is24HourFormat: true 
    
    // Declarative Rotation Math for GPU Acceleration
    property real hourRotation: ((currentTime.getHours() % 12) + currentTime.getMinutes() / 60) * 30
    property real minuteRotation: (currentTime.getMinutes() + currentTime.getSeconds() / 60) * 6
    property real secondRotation: currentTime.getSeconds() * 6

    property int clockTicks: 0 

    // --- CALENDAR STATE ---
    property int dispMonth: currentTime.getMonth()
    property int dispYear: currentTime.getFullYear()
    property int selectedDay: currentTime.getDate()
    property int selectedMonth: currentTime.getMonth()
    property int selectedYear: currentTime.getFullYear()
    property string selectedHoliday: getHoliday(selectedDay, selectedMonth, selectedYear)

    property bool isMonthPickerOpen: false
    property bool isYearPickerOpen: false

    // --- TIMEZONE PICKER STATE ---
    property bool isZonePickerOpen: false
    property string zoneSearchQuery: ""
    
    property var defaultZones: [
        { name: "Kakkanad", country: "India", lat: 10.0158, lon: 76.3418 },
        { name: "London", country: "United Kingdom", lat: 51.5085, lon: -0.1257 },
        { name: "New York", country: "United States", lat: 40.7143, lon: -74.006 },
        { name: "Tokyo", country: "Japan", lat: 35.6895, lon: 139.6917 },
        { name: "Sydney", country: "Australia", lat: -33.8688, lon: 151.2093 }
    ]
    
    property var filteredZones: defaultZones
    ListModel { id: activeZonesModel } 

    // ==========================================
    // DEFERRED INITIALIZATION & PERSISTENCE
    // ==========================================
    Process {
        id: readSettingsProcess
        command: ["bash", "-c", "cat ~/.cache/quickshell_time.json 2>/dev/null || echo 'NOT_FOUND'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt === "NOT_FOUND" || txt === "") {
                    // Fallback to defaults on the very first boot
                    activeZonesModel.append({name: "Kakkanad", offset: 5.5});
                    activeZonesModel.append({name: "London", offset: 0});
                    timeDateRoot.saveSettings();
                    return;
                }
                try {
                    let data = JSON.parse(txt);
                    if (data.is24Hour !== undefined) timeDateRoot.is24HourFormat = data.is24Hour;
                    if (data.zones) {
                        activeZonesModel.clear();
                        for(let i = 0; i < data.zones.length; i++) {
                            activeZonesModel.append(data.zones[i]);
                        }
                    }
                } catch(e) {
                    console.log("Time Settings Parse Error: " + e);
                }
            }
        }
    }

    Process { id: saveSettingsProcess }

    function saveSettings() {
        let zonesArr = [];
        for (let i = 0; i < activeZonesModel.count; i++) {
            let z = activeZonesModel.get(i);
            zonesArr.push({ name: z.name, offset: z.offset });
        }
        let data = {
            is24Hour: timeDateRoot.is24HourFormat,
            zones: zonesArr
        };
        let jsonString = JSON.stringify(data).replace(/'/g, "'\\''");
        let cmd = "echo '" + jsonString + "' > ~/.cache/quickshell_time.json";
        
        saveSettingsProcess.command = ["bash", "-c", cmd];
        saveSettingsProcess.running = true;
    }

    Timer {
        id: startupTimer
        interval: 150 
        running: true
        repeat: false
        onTriggered: {
            timeDateRoot.clockTicks = 60;
            generateCalendar();
            readSettingsProcess.running = true; 
        }
    }

    Timer {
        id: clockTimer
        interval: 1000 
        running: true
        repeat: true
        onTriggered: {
            timeDateRoot.currentTime = new Date();
            timeDateRoot.tick++; 
        }
    }

    Timer {
        id: searchDebounce
        interval: 350
        onTriggered: {
            if (timeDateRoot.zoneSearchQuery.trim().length > 1) {
                timeDateRoot.fetchGeocoding(timeDateRoot.zoneSearchQuery);
            } else {
                timeDateRoot.filteredZones = timeDateRoot.defaultZones;
            }
        }
    }

    // --- HOLIDAY ENGINE ---
    function getHoliday(day, month, year) {
        if (month === 0 && day === 1) return "New Year's Day \uf1fa";
        if (month === 1 && day === 14) return "Valentine's Day \uf004";
        if (month === 2 && day === 17) return "St. Patrick's Day \uf0fc";
        if (month === 3 && day === 22) return "Earth Day \uf0ac";
        if (month === 9 && day === 31) return "Halloween \uf0fb";
        if (month === 11 && day === 25) return "Christmas Day \uf06b";
        if (month === 11 && day === 31) return "New Year's Eve \uf000";

        let date = new Date(year, month, day);
        let dayOfWeek = date.getDay(); 
        let nthWeek = Math.floor((day - 1) / 7) + 1;

        if (month === 4 && dayOfWeek === 0 && nthWeek === 2) return "Mother's Day \uf004";
        if (month === 5 && dayOfWeek === 0 && nthWeek === 3) return "Father's Day \uf004";
        if (month === 10 && dayOfWeek === 4 && nthWeek === 4) return "Thanksgiving \uf0f5";

        return "";
    }

    ListModel { id: calendarModel }

    function generateCalendar() {
        calendarModel.clear();
        let firstDay = new Date(dispYear, dispMonth, 1).getDay();
        let daysInMonth = new Date(dispYear, dispMonth + 1, 0).getDate();
        let daysInPrevMonth = new Date(dispYear, dispMonth, 0).getDate();

        for (let i = firstDay - 1; i >= 0; i--) {
            calendarModel.append({ dayNum: daysInPrevMonth - i, isCurrentMonth: false, isToday: false, hasHoliday: false });
        }

        let today = new Date();
        for (let i = 1; i <= daysInMonth; i++) {
            let isTod = (i === today.getDate() && dispMonth === today.getMonth() && dispYear === today.getFullYear());
            let hol = getHoliday(i, dispMonth, dispYear);
            calendarModel.append({ dayNum: i, isCurrentMonth: true, isToday: isTod, hasHoliday: hol !== "" });
        }

        let remaining = 42 - calendarModel.count; 
        for (let i = 1; i <= remaining; i++) {
            calendarModel.append({ dayNum: i, isCurrentMonth: false, isToday: false, hasHoliday: false });
        }
    }

    function changeMonth(delta) {
        let newMonth = dispMonth + delta;
        let newYear = dispYear;
        if (newMonth > 11) { newMonth = 0; newYear++; }
        else if (newMonth < 0) { newMonth = 11; newYear--; }
        dispMonth = newMonth;
        dispYear = newYear;
        generateCalendar();
    }

    // --- TIMEZONE ENGINE ---
    function fetchGeocoding(query) {
        var url = "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(query) + "&count=15&language=en&format=json";
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                var data = JSON.parse(xhr.responseText);
                var results = data.results || [];
                var newCities = [];
                for (var i = 0; i < results.length; i++) {
                    newCities.push({
                        name: results[i].name,
                        country: results[i].country + (results[i].admin1 ? ", " + results[i].admin1 : ""),
                        lat: results[i].latitude,
                        lon: results[i].longitude
                    });
                }
                timeDateRoot.filteredZones = newCities.length > 0 ? newCities : timeDateRoot.defaultZones;
            }
        }
        xhr.send();
    }

    function fetchZoneOffsetAndAdd(name, lat, lon) {
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + "&current_weather=true&timezone=auto";
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                var data = JSON.parse(xhr.responseText);
                var offsetHours = data.utc_offset_seconds / 3600;
                
                // Prevent duplicate zones from being added
                for (let i = 0; i < activeZonesModel.count; i++) {
                    if (activeZonesModel.get(i).name === name) return;
                }
                
                activeZonesModel.append({ name: name, offset: offsetHours });
                timeDateRoot.saveSettings(); 
            }
        }
        xhr.send();
    }

    function getCityTime(offsetNum, tickTracker) {
        let d = timeDateRoot.currentTime;
        let utc = d.getTime() + (d.getTimezoneOffset() * 60000);
        let nd = new Date(utc + (3600000 * offsetNum));
        
        return timeDateRoot.is24HourFormat ? 
               nd.toLocaleTimeString(Qt.locale(), "HH:mm") : 
               nd.toLocaleTimeString(Qt.locale(), "hh:mm AP");
    }

    function getCityDayDiff(offsetNum, tickTracker) {
        let d = timeDateRoot.currentTime;
        let utc = d.getTime() + (d.getTimezoneOffset() * 60000);
        let nd = new Date(utc + (3600000 * offsetNum));
        
        let localDay = d.getDate();
        let cityDay = nd.getDate();
        
        if (localDay === cityDay) return "Today";
        if (nd.getTime() > d.getTime()) return "Tomorrow";
        return "Yesterday";
    }

    // ==========================================
    // GLOBAL CLICK-AWAY OVERLAY FOR DROPDOWNS
    // ==========================================
    MouseArea {
        anchors.fill: parent
        enabled: timeDateRoot.isMonthPickerOpen || timeDateRoot.isYearPickerOpen
        z: -1 
        onClicked: {
            timeDateRoot.isMonthPickerOpen = false;
            timeDateRoot.isYearPickerOpen = false;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Metrics.spacingBase
        anchors.margins: Metrics.spacingLarge

        // ==========================================
        // HEADER ROW: TITLE & FORMAT TOGGLE
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            z: 100 

            Text {
                text: "Time & Planner"
                color: Theme.main
                font.family: Theme.fontMain
                font.pixelSize: 18
                font.weight: Font.Bold
            }

            Item { Layout.fillWidth: true } 

            RowLayout {
                spacing: 8
                Text {
                    text: "12h"
                    color: !timeDateRoot.is24HourFormat ? Theme.text : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                    font.family: Theme.fontMain
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                Rectangle {
                    width: 38
                    height: 22
                    radius: 11
                    color: "transparent"
                    border.color: Theme.main
                    border.width: 1

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: Theme.main
                        anchors.verticalCenter: parent.verticalCenter
                        x: timeDateRoot.is24HourFormat ? parent.width - width - 3 : 3
                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            timeDateRoot.is24HourFormat = !timeDateRoot.is24HourFormat;
                            timeDateRoot.saveSettings();
                        }
                    }
                }

                Text {
                    text: "24h"
                    color: timeDateRoot.is24HourFormat ? Theme.text : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                    font.family: Theme.fontMain
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Metrics.spacingLarge * 2

            // ==========================================
            // LEFT COLUMN: CLOCK & TIME ZONES
            // ==========================================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 400 
                Layout.fillHeight: true
                spacing: Metrics.spacingLarge

                // --- CLOCK WIDGET ---
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300
                    color: "transparent"
                    radius: Metrics.radiusBase
                    border.width: clockHover.hovered ? 1 : 0
                    border.color: clockHover.hovered ? Theme.main : "transparent"
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    HoverHandler { id: clockHover }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingLarge
                        spacing: 15

                        Item {
                            id: clockContainer
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Item {
                                id: clockFace
                                width: Math.min(clockContainer.width, clockContainer.height)
                                height: width
                                anchors.centerIn: parent

                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: "transparent" 
                                    border.width: 2
                                    border.color: Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.3)
                                }

                                Repeater {
                                    model: timeDateRoot.clockTicks
                                    Item {
                                        anchors.fill: parent
                                        rotation: index * 6
                                        Rectangle {
                                            anchors.top: parent.top
                                            anchors.topMargin: index % 5 === 0 ? 5 : 8
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: index % 5 === 0 ? 3 : 1
                                            height: index % 5 === 0 ? 12 : 5
                                            color: index % 5 === 0 ? Theme.text : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
                                            radius: 1
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 6
                                    height: parent.height * 0.25
                                    color: Theme.main
                                    radius: 3
                                    anchors.bottom: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    transformOrigin: Item.Bottom
                                    rotation: timeDateRoot.hourRotation
                                    antialiasing: true
                                }

                                Rectangle {
                                    width: 4
                                    height: parent.height * 0.35
                                    color: Theme.secondary
                                    radius: 2
                                    anchors.bottom: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    transformOrigin: Item.Bottom
                                    rotation: timeDateRoot.minuteRotation
                                    antialiasing: true
                                }

                                Rectangle {
                                    width: 2
                                    height: parent.height * 0.42
                                    color: Theme.bridge
                                    anchors.bottom: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    transformOrigin: Item.Bottom
                                    rotation: timeDateRoot.secondRotation
                                    antialiasing: true
                                }

                                Rectangle {
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: Theme.bridge
                                    anchors.centerIn: parent
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: -4

                            Text {
                                text: timeDateRoot.is24HourFormat ? 
                                      timeDateRoot.currentTime.toLocaleTimeString(Qt.locale(), "HH:mm:ss") : 
                                      timeDateRoot.currentTime.toLocaleTimeString(Qt.locale(), "hh:mm:ss AP")
                                color: Theme.text
                                font.family: Theme.fontMain
                                font.pixelSize: 28
                                font.weight: Font.Bold
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: timeDateRoot.activeDateString
                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                                font.family: Theme.fontMain
                                font.pixelSize: 14
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }

                // --- TIME ZONE WIDGET ---
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    radius: Metrics.radiusBase
                    border.width: zoneWidgetHover.hovered ? 1 : 0
                    border.color: zoneWidgetHover.hovered ? Theme.main : "transparent"
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    HoverHandler { id: zoneWidgetHover }
                    clip: true
                    z: 50 

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingLarge
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Global Time Zones"
                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                                font.family: Theme.fontMain
                                font.pixelSize: 16
                                font.weight: Font.Bold
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: "transparent"
                                border.color: timeDateRoot.isZonePickerOpen || zoneAddHover.hovered ? Theme.main : "transparent"
                                border.width: 1
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: timeDateRoot.isZonePickerOpen ? "\uf068" : "\uf067" 
                                    color: timeDateRoot.isZonePickerOpen || zoneAddHover.hovered ? Theme.main : Theme.text
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 14
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    id: zoneAddHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        timeDateRoot.isZonePickerOpen = !timeDateRoot.isZonePickerOpen;
                                        if (timeDateRoot.isZonePickerOpen) {
                                            timeDateRoot.isMonthPickerOpen = false;
                                            timeDateRoot.isYearPickerOpen = false;
                                            zoneSearchInput.forceActiveFocus();
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: timeDateRoot.isZonePickerOpen
                            spacing: 8

                            TextField {
                                id: zoneSearchInput
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38
                                placeholderText: "Search city..."
                                font.family: Theme.fontMain
                                font.pixelSize: 14
                                color: Theme.text
                                background: Rectangle {
                                    color: "transparent"
                                    radius: 19
                                    border.width: 1
                                    border.color: zoneSearchInput.activeFocus ? Theme.main : Theme.bridge
                                }
                                leftPadding: 15
                                onTextChanged: {
                                    timeDateRoot.zoneSearchQuery = text;
                                    searchDebounce.restart();
                                }
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 180
                                clip: true
                                model: timeDateRoot.filteredZones
                                ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded }
                                
                                delegate: Rectangle {
                                    // THE FIX: Reduced width creates padding so the border doesn't hit the scrollbar
                                    width: ListView.view.width - 16
                                    height: 42
                                    radius: Metrics.radiusBase
                                    color: "transparent"
                                    border.width: zoneHover.containsMouse ? 1 : 0
                                    border.color: zoneHover.containsMouse ? Theme.main : "transparent"
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 15

                                        Text { 
                                            text: "\uf041"
                                            color: Theme.main
                                            font.family: Theme.fontIcon
                                            font.pixelSize: 14
                                            Layout.preferredWidth: 16 
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                        
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0
                                            Text { 
                                                text: modelData.name
                                                color: Theme.text
                                                font.family: Theme.fontMain
                                                font.pixelSize: 14
                                                font.weight: Font.Bold
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignLeft 
                                                elide: Text.ElideRight 
                                            }
                                            Text { 
                                                text: modelData.country
                                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                                                font.family: Theme.fontMain
                                                font.pixelSize: 12
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignLeft
                                                elide: Text.ElideRight 
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: zoneHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            timeDateRoot.fetchZoneOffsetAndAdd(modelData.name, modelData.lat, modelData.lon);
                                            timeDateRoot.isZonePickerOpen = false;
                                            timeDateRoot.zoneSearchQuery = "";
                                            zoneSearchInput.text = "";
                                        }
                                    }
                                }
                            }
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: !timeDateRoot.isZonePickerOpen
                            clip: true
                            spacing: 8
                            model: activeZonesModel
                            ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded }

                            Item {
                                width: ListView.view ? ListView.view.width : parent.width
                                height: 100
                                visible: activeZonesModel.count === 0
                                anchors.centerIn: parent

                                Text {
                                    anchors.centerIn: parent
                                    text: "No timezones added.\nClick the + icon to add a city."
                                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                                    font.family: Theme.fontMain
                                    font.pixelSize: 14
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            delegate: Rectangle {
                                // THE FIX: Width padding for scrollbar
                                width: ListView.view.width - 16
                                height: 50
                                radius: Metrics.radiusBase
                                color: "transparent"
                                border.width: activeZoneHover.hovered ? 1 : 0
                                border.color: activeZoneHover.hovered ? Theme.main : "transparent"
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                HoverHandler { id: activeZoneHover }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 15

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: model.name
                                            color: Theme.text
                                            font.family: Theme.fontMain
                                            font.pixelSize: 15
                                            font.weight: Font.Bold
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignLeft
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: timeDateRoot.getCityDayDiff(model.offset, timeDateRoot.tick)
                                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                                            font.family: Theme.fontMain
                                            font.pixelSize: 12
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignLeft
                                        }
                                    }

                                    Text {
                                        text: timeDateRoot.getCityTime(model.offset, timeDateRoot.tick)
                                        color: Theme.main
                                        font.family: Theme.fontMain
                                        font.pixelSize: 18
                                        font.weight: Font.Bold
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    Text {
                                        text: "\uf014" 
                                        color: delHover.containsMouse ? Theme.urgent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3)
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 14
                                        Layout.leftMargin: 8

                                        MouseArea {
                                            id: delHover
                                            anchors.fill: parent
                                            anchors.margins: -5
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                activeZonesModel.remove(index);
                                                timeDateRoot.saveSettings(); 
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // RIGHT COLUMN: INTERACTIVE CALENDAR
            // ==========================================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 600
                Layout.fillHeight: true
                color: "transparent"
                radius: Metrics.radiusBase
                border.width: calHover.hovered ? 1 : 0
                border.color: calHover.hovered ? Theme.main : "transparent"
                Behavior on border.color { ColorAnimation { duration: 150 } }
                HoverHandler { id: calHover }
                
                z: (timeDateRoot.isMonthPickerOpen || timeDateRoot.isYearPickerOpen) ? 999 : 40 

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Metrics.spacingLarge
                    spacing: Metrics.spacingLarge

                    // --- CALENDAR HEADER ---
                    RowLayout {
                        Layout.fillWidth: true
                        z: 100 
                        
                        Rectangle {
                            width: 36
                            height: 36
                            radius: 18
                            color: prevHover.containsMouse ? Qt.darker(Theme.base, 1.4) : "transparent"
                            Text { anchors.centerIn: parent; text: "\uf104"; color: Theme.text; font.family: Theme.fontIcon; font.pixelSize: 16 }
                            MouseArea { id: prevHover; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: timeDateRoot.changeMonth(-1) }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12
                            
                            Item { Layout.fillWidth: true } 

                            // Month Dropdown Trigger
                            Rectangle {
                                width: monthText.implicitWidth + 24
                                height: 36
                                radius: 18
                                color: monthDropHover.containsMouse || timeDateRoot.isMonthPickerOpen ? Qt.darker(Theme.base, 1.4) : "transparent"
                                z: 100
                                
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text {
                                        id: monthText
                                        text: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][timeDateRoot.dispMonth]
                                        color: Theme.main
                                        font.family: Theme.fontMain
                                        font.pixelSize: 20
                                        font.weight: Font.Bold
                                    }
                                    Text { text: timeDateRoot.isMonthPickerOpen ? "\uf106" : "\uf107"; color: Theme.main; font.family: Theme.fontIcon; font.pixelSize: 14 }
                                }
                                MouseArea { 
                                    id: monthDropHover
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        timeDateRoot.isMonthPickerOpen = !timeDateRoot.isMonthPickerOpen;
                                        if (timeDateRoot.isMonthPickerOpen) {
                                            timeDateRoot.isYearPickerOpen = false;
                                            timeDateRoot.isZonePickerOpen = false;
                                        }
                                    }
                                }

                                // Month List Popup 
                                Rectangle {
                                    width: 140
                                    height: 280
                                    anchors.top: parent.bottom
                                    anchors.topMargin: 8
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: Qt.darker(Theme.base, 1.1) 
                                    border.color: Theme.bridge
                                    border.width: 1
                                    radius: Metrics.radiusBase
                                    visible: timeDateRoot.isMonthPickerOpen
                                    clip: true
                                    z: 999
                                    
                                    MouseArea { anchors.fill: parent }

                                    ListView {
                                        id: monthListView
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        model: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
                                        boundsBehavior: Flickable.StopAtBounds
                                        WheelHandler { id: monthWheel; target: monthListView }
                                        ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded }

                                        delegate: Rectangle {
                                            // THE FIX: Width padding for scrollbar
                                            width: ListView.view.width - 12
                                            height: 34
                                            radius: 6
                                            color: timeDateRoot.dispMonth === index ? Theme.main : "transparent"
                                            border.width: mHover.containsMouse && timeDateRoot.dispMonth !== index ? 1 : 0
                                            border.color: mHover.containsMouse && timeDateRoot.dispMonth !== index ? Theme.main : "transparent"
                                            Behavior on border.color { ColorAnimation { duration: 150 } }
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData
                                                color: timeDateRoot.dispMonth === index ? Theme.base : Theme.text
                                                font.family: Theme.fontMain
                                                font.pixelSize: 14
                                                font.weight: timeDateRoot.dispMonth === index ? Font.Bold : Font.Normal
                                            }
                                            MouseArea {
                                                id: mHover
                                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    timeDateRoot.dispMonth = index;
                                                    timeDateRoot.generateCalendar();
                                                    timeDateRoot.isMonthPickerOpen = false;
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Year Dropdown Trigger
                            Rectangle {
                                width: yearText.implicitWidth + 24
                                height: 36
                                radius: 18
                                color: yearDropHover.containsMouse || timeDateRoot.isYearPickerOpen ? Qt.darker(Theme.base, 1.4) : "transparent"
                                z: 100
                                
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text {
                                        id: yearText
                                        text: timeDateRoot.dispYear
                                        color: Theme.main
                                        font.family: Theme.fontMain
                                        font.pixelSize: 20
                                        font.weight: Font.Bold
                                    }
                                    Text { text: timeDateRoot.isYearPickerOpen ? "\uf106" : "\uf107"; color: Theme.main; font.family: Theme.fontIcon; font.pixelSize: 14 }
                                }
                                MouseArea { 
                                    id: yearDropHover
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        timeDateRoot.isYearPickerOpen = !timeDateRoot.isYearPickerOpen;
                                        if (timeDateRoot.isYearPickerOpen) {
                                            timeDateRoot.isMonthPickerOpen = false;
                                            timeDateRoot.isZonePickerOpen = false;
                                            yearListView.positionViewAtIndex(timeDateRoot.dispYear - 1950, ListView.Center);
                                        }
                                    }
                                }

                                // Year List Popup 
                                Rectangle {
                                    width: 100
                                    height: 280
                                    anchors.top: parent.bottom
                                    anchors.topMargin: 8
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: Qt.darker(Theme.base, 1.1) 
                                    border.color: Theme.bridge
                                    border.width: 1
                                    radius: Metrics.radiusBase
                                    visible: timeDateRoot.isYearPickerOpen
                                    clip: true
                                    z: 999
                                    
                                    MouseArea { anchors.fill: parent }

                                    ListView {
                                        id: yearListView
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        model: 151 
                                        boundsBehavior: Flickable.StopAtBounds
                                        WheelHandler { id: yearWheel; target: yearListView }
                                        ScrollBar.vertical: ScrollBar { active: true }
                                        
                                        delegate: Rectangle {
                                            // THE FIX: Width padding for scrollbar
                                            width: ListView.view.width - 12
                                            height: 34
                                            radius: 6
                                            property int targetYear: 1950 + index
                                            color: timeDateRoot.dispYear === targetYear ? Theme.main : "transparent"
                                            border.width: yHover.containsMouse && timeDateRoot.dispYear !== targetYear ? 1 : 0
                                            border.color: yHover.containsMouse && timeDateRoot.dispYear !== targetYear ? Theme.main : "transparent"
                                            Behavior on border.color { ColorAnimation { duration: 150 } }
                                            Text {
                                                anchors.centerIn: parent
                                                text: parent.targetYear
                                                color: timeDateRoot.dispYear === parent.targetYear ? Theme.base : Theme.text
                                                font.family: Theme.fontMain
                                                font.pixelSize: 14
                                                font.weight: timeDateRoot.dispYear === parent.targetYear ? Font.Bold : Font.Normal
                                            }
                                            MouseArea {
                                                id: yHover
                                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    timeDateRoot.dispYear = parent.targetYear;
                                                    timeDateRoot.generateCalendar();
                                                    timeDateRoot.isYearPickerOpen = false;
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true } 
                        }

                        Rectangle {
                            width: 36
                            height: 36
                            radius: 18
                            color: nextHover.containsMouse ? Qt.darker(Theme.base, 1.4) : "transparent"
                            Text { anchors.centerIn: parent; text: "\uf105"; color: Theme.text; font.family: Theme.fontIcon; font.pixelSize: 16 }
                            MouseArea { id: nextHover; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: timeDateRoot.changeMonth(1) }
                        }
                    }

                    // --- DAYS OF WEEK HEADER ---
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        z: 1 
                        Repeater {
                            model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                            Text {
                                Layout.fillWidth: true
                                text: modelData
                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                                font.family: Theme.fontMain
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    // --- CALENDAR GRID ---
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 7
                        columnSpacing: 8
                        rowSpacing: 8
                        z: 1 

                        Repeater {
                            model: calendarModel
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 8
                                color: {
                                    if (model.isToday) return Theme.main;
                                    if (timeDateRoot.selectedDay === model.dayNum && timeDateRoot.selectedMonth === timeDateRoot.dispMonth && timeDateRoot.selectedYear === timeDateRoot.dispYear && model.isCurrentMonth) return Qt.darker(Theme.base, 1.4);
                                    if (dayHover.containsMouse) return Qt.rgba(Theme.main.r, Theme.main.g, Theme.main.b, 0.1);
                                    return "transparent";
                                }
                                border.color: model.isToday ? Theme.main : (model.hasHoliday ? Theme.bridge : "transparent")
                                border.width: model.isToday || model.hasHoliday ? 2 : 0

                                Text {
                                    anchors.centerIn: parent
                                    text: model.dayNum
                                    color: model.isToday ? Theme.base : (model.isCurrentMonth ? Theme.text : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.3))
                                    font.family: Theme.fontMain
                                    font.pixelSize: 18
                                    font.weight: model.isToday ? Font.Bold : Font.Normal
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 4
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: model.isToday ? Theme.base : Theme.bridge
                                    visible: model.hasHoliday
                                }

                                MouseArea {
                                    id: dayHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        timeDateRoot.isMonthPickerOpen = false;
                                        timeDateRoot.isYearPickerOpen = false;
                                        
                                        if (model.isCurrentMonth) {
                                            timeDateRoot.selectedDay = model.dayNum;
                                            timeDateRoot.selectedMonth = timeDateRoot.dispMonth;
                                            timeDateRoot.selectedYear = timeDateRoot.dispYear;
                                            timeDateRoot.selectedHoliday = timeDateRoot.getHoliday(model.dayNum, timeDateRoot.dispMonth, timeDateRoot.dispYear);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // --- SELECTED DAY DETAILS / HOLIDAY BAR ---
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        color: "transparent"
                        radius: Metrics.radiusBase
                        border.width: detailsHover.hovered ? 1 : 0
                        border.color: detailsHover.hovered ? Theme.main : "transparent"
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        HoverHandler { id: detailsHover }
                        z: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Metrics.spacingLarge
                            anchors.rightMargin: Metrics.spacingLarge
                            spacing: 15

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 8
                                color: timeDateRoot.selectedHoliday !== "" ? Theme.bridge : Theme.main
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: timeDateRoot.selectedDay
                                    color: Theme.base
                                    font.family: Theme.fontMain
                                    font.pixelSize: 20
                                    font.weight: Font.Bold
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "Events & Details"
                                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                                    font.family: Theme.fontMain
                                    font.pixelSize: 12
                                }
                                Text {
                                    text: timeDateRoot.selectedHoliday !== "" ? timeDateRoot.selectedHoliday : "No specific events today."
                                    color: timeDateRoot.selectedHoliday !== "" ? Theme.bridge : Theme.text
                                    font.family: timeDateRoot.selectedHoliday !== "" ? Theme.fontIcon : Theme.fontMain
                                    font.pixelSize: 15
                                    font.weight: timeDateRoot.selectedHoliday !== "" ? Font.Bold : Font.Normal
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
