import QtQuick
import QtQuick.Layouts

import "../../../theme"

Item {
    id: clockContainer
    
    // Allows the Bar's RowLayout to size this component correctly
    Layout.preferredWidth: contentLayout.implicitWidth
    Layout.fillHeight: true

    RowLayout {
        id: contentLayout
        anchors.right: parent.right 
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Text {
            id: timeDisplay
            font.family: Theme.fontMain // <--- ADDED THIS
            font.pixelSize: 16
            font.bold: true
            
            // Re-use the hover logic to highlight the text with the theme's main color
            color: clockMouseArea.containsMouse ? Theme.main : Theme.text
            
            Behavior on color { 
                ColorAnimation { duration: Metrics.animBase } 
            }
            
            function updateTime() {
                text = new Date().toLocaleString(Qt.locale(), "HH:mm:ss");
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: timeDisplay.updateTime()
            }
            
            Component.onCompleted: updateTime()
        }
    }

    // Still using MouseArea for the nice hover color effect, but no click actions!
    MouseArea {
        id: clockMouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
