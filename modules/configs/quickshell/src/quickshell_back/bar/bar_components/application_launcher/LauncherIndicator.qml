import QtQuick
import Quickshell
import "../" 

Item {
    id: launcherRoot

    property var parentWindow

    Text {
        anchors.centerIn: parent
        text: "󰣇" 
        color: mouseArea.containsMouse ? Theme.main : Theme.text
        font.pixelSize: 22
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: launcherPopup.toggle()
    }

    LauncherPopup {
        id: launcherPopup
        parentWindow: launcherRoot.parentWindow
        
        // THE FIX: Using the safe sub-surface anchor that we know works!
        anchorTarget: launcherRoot 
    }
}
