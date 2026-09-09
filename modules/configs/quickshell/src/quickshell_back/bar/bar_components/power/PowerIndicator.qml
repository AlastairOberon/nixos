import QtQuick
import QtQuick.Layouts
import ".." // <-- Makes sure it can see Theme.qml!

Item {
    id: indicatorRoot
    Layout.preferredWidth: 35
    Layout.fillHeight: true

    property var parentWindow

    Text {
        anchors.centerIn: parent
        text: "" 
        // THE FIX: Dynamic urgent color that highlights on hover!
        color: powerMouse.containsMouse ? Theme.secondary : Theme.main 
        font.pixelSize: 18
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: powerMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: powerPopup.toggle()
    }

    PowerPopup {
        id: powerPopup
        parentWindow: indicatorRoot.parentWindow
        // THE FIX: Deleted anchorTarget since the popup is now a centered fullscreen overlay!
    }
}
