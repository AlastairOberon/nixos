import QtQuick
import QtQuick.Layouts
import ".." 

Item {
    id: indicatorRoot
    Layout.preferredWidth: 35
    Layout.fillHeight: true

    property var parentWindow

    Text {
        anchors.centerIn: parent
        text: "" 
        color: shortcutsMouse.containsMouse ? Theme.secondary : Theme.main 
        font.pixelSize: 18
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: shortcutsMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!popupLoader.active) {
                popupLoader.active = true;
            } else if (popupLoader.status === Loader.Ready) {
                popupLoader.item.parentWindow = indicatorRoot.parentWindow;
                // Deleted anchorTarget here!
                popupLoader.item.toggle();
            }
        }
    }

    Loader {
        id: popupLoader
        active: false 
        asynchronous: true 
        
        sourceComponent: Component {
            ShortcutsPopup {}
        }

        onLoaded: {
            item.parentWindow = indicatorRoot.parentWindow;
            // Deleted anchorTarget here!
            item.toggle();
        }
    }
}
