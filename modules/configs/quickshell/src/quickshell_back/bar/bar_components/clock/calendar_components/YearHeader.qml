import QtQuick
import QtQuick.Layouts
import "../.." // <-- Crucial: Tells QML to look two folders up for Theme.qml

RowLayout {
    property int currentYear
    property bool isActive
    
    signal prevClicked()
    signal nextClicked()
    signal headerClicked()

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

    // --- YEAR SELECTOR BUTTON ---
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 35
        radius: 6
        color: yearMouseArea.containsMouse || isActive ? Theme.main : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: currentYear.toString()
            color: yearMouseArea.containsMouse || isActive ? Theme.base : Theme.main
            font.bold: true
            font.pixelSize: 18 
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            id: yearMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: headerClicked()
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
