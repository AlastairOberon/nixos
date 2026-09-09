import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../../theme" as Theme
import "../../../theme/components" as Components

Item {
    id: emojiRoot
    width: 35
    height: 35

    // Instantiate the floating window tied to this module
    EmojiWindow {
        id: emojiWindow
    }

    Components.ThemeButton {
        anchors.fill: parent
        color: "transparent"
        
        Text {
            anchors.centerIn: parent
            text: "😀" 
            font.pixelSize: 18
        }

        onClicked: {
            emojiWindow.visible = !emojiWindow.visible
            if (emojiWindow.visible) {
                emojiWindow.requestActivate()
            }
        }
    }
}
