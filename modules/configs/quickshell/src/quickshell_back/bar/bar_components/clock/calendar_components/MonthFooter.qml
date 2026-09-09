import QtQuick
import QtQuick.Layouts
import "../.." // <-- Crucial: Tells QML to look two folders up for Theme.qml

RowLayout {
    property int currentYear
    property int currentMonth
    property bool isActive
    
    signal prevClicked()
    signal nextClicked()
    signal footerClicked()

    Layout.fillWidth: true
    
    // --- PREVIOUS ARROW ---
    Rectangle {
        Layout.preferredWidth: 35
        Layout.preferredHeight: 35
        radius: 6
        color: prevMouse.containsMouse ? Theme.main : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } } // Smooth background fade
        
        Text { 
            anchors.centerIn: parent
            text: "‹"
            color: prevMouse.containsMouse ? Theme.base : Theme.text
            font.pixelSize: 26 
            Behavior on color { ColorAnimation { duration: 150 } } // Smooth text color fade
        }
        MouseArea {
            id: prevMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: prevClicked()
        }
    }

    // --- MONTH SELECTOR BUTTON ---
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 35
        radius: 6
        color: monthMouseArea.containsMouse || isActive ? Theme.main : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: new Date(currentYear, currentMonth, 1).toLocaleString(Qt.locale(), "MMMM")
            color: monthMouseArea.containsMouse || isActive ? Theme.base : Theme.main
            font.bold: true
            font.pixelSize: 18 
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            id: monthMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: footerClicked()
        }
    }

    // --- NEXT ARROW ---
    Rectangle {
        Layout.preferredWidth: 35
        Layout.preferredHeight: 35
        radius: 6
        color: nextMouse.containsMouse ? Theme.main : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
        
        Text { 
            anchors.centerIn: parent
            text: "›"
            color: nextMouse.containsMouse ? Theme.base : Theme.text
            font.pixelSize: 26 
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        MouseArea {
            id: nextMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: nextClicked()
        }
    }
}
