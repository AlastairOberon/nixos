import QtQuick
import QtQuick.Layouts
import "../.." // <-- Tells QML to look two folders up for Theme.qml

ColumnLayout {
    id: root
    
    property int currentYear
    property int currentMonth
    property bool selectingYear
    property bool selectingMonth

    // --- THE FIX: Reactive Date Property & Midnight Timer ---
    property var currentDate: new Date()

    Timer {
        id: midnightTimer
        interval: 60000 // Checks the time every 60 seconds
        running: true
        repeat: true
        onTriggered: {
            let now = new Date();
            // Only force QML to update if the actual calendar day has changed
            if (now.getDate() !== root.currentDate.getDate() || 
                now.getMonth() !== root.currentDate.getMonth() || 
                now.getFullYear() !== root.currentDate.getFullYear()) {
                root.currentDate = now;
            }
        }
    }
    // --------------------------------------------------------

    signal updateState(int year, int month)
    signal closeYearSelect()
    signal closeMonthSelect()

    spacing: 10

    function shiftMonth(direction) {
        if (slideLeftAnimation.running || slideRightAnimation.running) return;
        if (direction === "next") {
            if (currentMonth === 11) { transCal.targetMonth = 0; transCal.targetYear = currentYear + 1; } 
            else { transCal.targetMonth = currentMonth + 1; transCal.targetYear = currentYear; }
            slideLeftAnimation.start();
        } else {
            if (currentMonth === 0) { transCal.targetMonth = 11; transCal.targetYear = currentYear - 1; } 
            else { transCal.targetMonth = currentMonth - 1; transCal.targetYear = currentYear; }
            slideRightAnimation.start();
        }
    }

    function shiftYear(direction) {
        if (slideLeftAnimation.running || slideRightAnimation.running) return;
        if (direction === "next") { transCal.targetMonth = currentMonth; transCal.targetYear = currentYear + 1; slideLeftAnimation.start(); } 
        else { transCal.targetMonth = currentMonth; transCal.targetYear = currentYear - 1; slideRightAnimation.start(); }
    }

    // --- DAYS OF THE WEEK (FADES OUT) ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 6 
        
        opacity: (root.selectingYear || root.selectingMonth) ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Repeater {
            model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
            Text { 
                Layout.fillWidth: true; 
                horizontalAlignment: Text.AlignHCenter; 
                text: modelData; 
                color: Theme.inactive; 
                font.pixelSize: 14; 
                font.bold: true 
                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }
    }

    // --- VIEWPORT & OVERLAYS ---
    Item {
        id: gridViewport
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true 

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton 
            onWheel: (wheel) => {
                if (root.selectingMonth || root.selectingYear) return;
                if (wheel.angleDelta.y > 0) root.shiftMonth("prev");
                else if (wheel.angleDelta.y < 0) root.shiftMonth("next");
            }
        }

        ParallelAnimation {
            id: slideLeftAnimation
            NumberAnimation { target: primaryGrid; property: "x"; from: 0; to: -280; duration: 350; easing.type: Easing.OutExpo }
            NumberAnimation { target: transGrid; property: "x"; from: 280; to: 0; duration: 350; easing.type: Easing.OutExpo }
            onFinished: {
                root.updateState(transCal.targetYear, transCal.targetMonth);
                primaryGrid.x = 0;
                transGrid.x = 280;
            }
        }

        ParallelAnimation {
            id: slideRightAnimation
            NumberAnimation { target: primaryGrid; property: "x"; from: 0; to: 280; duration: 350; easing.type: Easing.OutExpo }
            NumberAnimation { target: transGrid; property: "x"; from: -280; to: 0; duration: 350; easing.type: Easing.OutExpo }
            onFinished: {
                root.updateState(transCal.targetYear, transCal.targetMonth);
                primaryGrid.x = 0;
                transGrid.x = 280;
            }
        }

        QtObject {
            id: transCal
            property int targetMonth: 0
            property int targetYear: 0
        }

        GridLayout {
            id: primaryGrid
            width: parent.width; height: parent.height
            x: 0; columns: 7; rowSpacing: 6; columnSpacing: 6
            Repeater {
                model: 42 
                delegate: Rectangle {
                    id: pCell
                    Layout.fillWidth: true; Layout.fillHeight: true
                    property int firstDay: new Date(root.currentYear, root.currentMonth, 1).getDay()
                    property int totalDays: new Date(root.currentYear, root.currentMonth + 1, 0).getDate()
                    property int dayOffset: index - firstDay + 1
                    property bool isCurrentMonth: dayOffset > 0 && dayOffset <= totalDays
                    
                    property bool isToday: isCurrentMonth && dayOffset === root.currentDate.getDate() && root.currentMonth === root.currentDate.getMonth() && root.currentYear === root.currentDate.getFullYear()

                    color: isToday ? Theme.main : "transparent"
                    radius: 6 
                    Behavior on color { ColorAnimation { duration: 300 } }

                    Text { 
                        anchors.centerIn: parent
                        text: {
                            if (pCell.isCurrentMonth) return pCell.dayOffset;
                            if (pCell.dayOffset <= 0) return new Date(root.currentYear, root.currentMonth, 0).getDate() + pCell.dayOffset;
                            return pCell.dayOffset - pCell.totalDays; 
                        }
                        color: pCell.isToday ? Theme.base : (pCell.isCurrentMonth ? Theme.text : Theme.inactive) 
                        font.pixelSize: 14; font.bold: pCell.isToday 
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }
            }
        }

        GridLayout {
            id: transGrid
            width: parent.width; height: parent.height
            x: 280; columns: 7; rowSpacing: 6; columnSpacing: 6
            Repeater {
                model: 42
                delegate: Rectangle {
                    id: tCell
                    Layout.fillWidth: true; Layout.fillHeight: true
                    property int firstDay: new Date(transCal.targetYear, transCal.targetMonth, 1).getDay()
                    property int totalDays: new Date(transCal.targetYear, transCal.targetMonth + 1, 0).getDate()
                    property int dayOffset: index - firstDay + 1
                    property bool isCurrentMonth: dayOffset > 0 && dayOffset <= totalDays
                    
                    property bool isToday: isCurrentMonth && dayOffset === root.currentDate.getDate() && transCal.targetMonth === root.currentDate.getMonth() && transCal.targetYear === root.currentDate.getFullYear()

                    color: isToday ? Theme.main : "transparent"
                    radius: 6
                    Behavior on color { ColorAnimation { duration: 300 } }

                    Text { 
                        anchors.centerIn: parent
                        text: {
                            if (tCell.isCurrentMonth) return tCell.dayOffset;
                            if (tCell.dayOffset <= 0) return new Date(transCal.targetYear, transCal.targetMonth, 0).getDate() + tCell.dayOffset;
                            return tCell.dayOffset - tCell.totalDays;
                        }
                        color: tCell.isToday ? Theme.base : (tCell.isCurrentMonth ? Theme.text : Theme.inactive)
                        font.pixelSize: 14; font.bold: tCell.isToday 
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }
            }
        }

        // --- MONTH SELECTOR OVERLAY ---
        Rectangle {
            anchors.fill: parent
            color: Theme.base 
            radius: 12 
            opacity: root.selectingMonth ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            z: 2 

            GridLayout {
                anchors.fill: parent
                anchors.margins: 10 
                columns: 3
                rowSpacing: 10
                columnSpacing: 10
                Repeater {
                    model: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
                    delegate: Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        color: root.currentMonth === index ? Theme.main : (monthHover.containsMouse ? Theme.secondaryBase : "transparent")
                        radius: 8
                        Behavior on color { ColorAnimation { duration: 150 } } 

                        Text { 
                            anchors.centerIn: parent
                            text: modelData
                            color: root.currentMonth === index ? Theme.base : Theme.text
                            font.pixelSize: 14
                            font.bold: root.currentMonth === index
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea {
                            id: monthHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: { root.updateState(root.currentYear, index); root.closeMonthSelect(); }
                        }
                    }
                }
            }
        }

        // --- YEAR SELECTOR OVERLAY ---
        Rectangle {
            anchors.fill: parent
            color: Theme.base 
            radius: 12 
            opacity: root.selectingYear ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            z: 3 

            ListView {
                id: yearListView
                anchors.fill: parent
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                clip: true
                property int baseYear: 1950
                model: 200 

                delegate: Item {
                    width: yearListView.width
                    height: 40

                    Rectangle {
                        width: 120 
                        height: 36 
                        anchors.centerIn: parent
                        color: root.currentYear === (yearListView.baseYear + index) ? Theme.main : (yearHover.containsMouse ? Theme.secondaryBase : "transparent")
                        radius: 8
                        Behavior on color { ColorAnimation { duration: 150 } } 

                        Text { 
                            anchors.centerIn: parent
                            text: yearListView.baseYear + index
                            color: root.currentYear === (yearListView.baseYear + index) ? Theme.base : Theme.text
                            font.pixelSize: 16
                            font.bold: root.currentYear === (yearListView.baseYear + index) 
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: yearHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: { root.updateState(yearListView.baseYear + index, root.currentMonth); root.closeYearSelect(); }
                        }
                    }
                }

                onVisibleChanged: {
                    if (visible) {
                        let targetIndex = root.currentYear - baseYear;
                        if (targetIndex >= 0 && targetIndex < count) positionViewAtIndex(targetIndex, ListView.Center);
                    }
                }
            }
        }
    } 
}
