import QtQuick
import "../../../theme"

Item {
    id: root
    
    implicitWidth: 30
    implicitHeight: 30

    property bool isActive: typeof myLauncher !== "undefined" && 
                            myLauncher.window && 
                            myLauncher.window.visible && 
                            myLauncher.window.currentTabIndex === 13

    // The highlight circle/pill background
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        // Active = Secondary, Hover = Urgent, Default = Transparent
        color: root.isActive ? Theme.secondary : (powerMouse.containsMouse ? Theme.urgent : "transparent")
        
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }

    Text {
        anchors.centerIn: parent
        text: ""
        font.pixelSize: 24
        // Use the dark base color for the icon whenever the background is filled
        color: (root.isActive || powerMouse.containsMouse) ? Theme.base : Theme.text

        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }

    MouseArea {
        id: powerMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (typeof myLauncher !== "undefined" && myLauncher.window) {
                if (root.isActive) {
                    myLauncher.window.visible = false;
                } else {
                    myLauncher.window.visible = true;
                    myLauncher.window.currentTabIndex = 14;
                }
            } else {
                console.log("Could not find myLauncher.window. Check Launcher.qml aliases!");
            }
        }
    }
}
