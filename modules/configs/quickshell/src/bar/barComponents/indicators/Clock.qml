import QtQuick
import QtQuick.Layouts

import "../../../theme"

Item {
    id: clockContainer
    
    Layout.preferredWidth: contentLayout.implicitWidth + 16
    Layout.preferredHeight: 30
    Layout.fillHeight: true

    property bool isActive: typeof myLauncher !== "undefined" && 
                            myLauncher.window && 
                            myLauncher.window.visible && 
                            myLauncher.window.currentTabIndex === 8

    // The Highlight Pill Background
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: clockContainer.isActive ? Theme.secondary : (clockMouseArea.containsMouse ? Theme.urgent : "transparent")
        
        Behavior on color { 
            ColorAnimation { duration: 200 } 
        }
    }

    RowLayout {
        id: contentLayout
        anchors.centerIn: parent
        spacing: 10

        Text {
            id: timeDisplay
            font.family: Theme.fontMain
            font.pixelSize: 16
            font.bold: true
            
            color: (clockContainer.isActive || clockMouseArea.containsMouse) ? Theme.base : Theme.text
            
            Behavior on color { 
                ColorAnimation { duration: 150 } 
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

    MouseArea {
        id: clockMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            if (typeof myLauncher !== "undefined" && myLauncher.window) {
                if (clockContainer.isActive) {
                    myLauncher.window.visible = false;
                } else {
                    myLauncher.window.visible = true;
                    myLauncher.window.currentTabIndex = 8;
                }
            }
        }
    }
}
