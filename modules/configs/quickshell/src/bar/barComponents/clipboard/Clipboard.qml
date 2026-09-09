import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../theme" as Theme
import "../../../theme/components" as Components

Item {
    id: clipboardWidget
    
    // Adjust these to match the standard sizing of your bar modules
    width: 40 
    height: parent.height

    // The clickable indicator on your top bar
    // The clickable indicator on your top bar
    Components.ThemeButton {
        id: clipboardButton
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        
        Text {
            anchors.centerIn: parent
            text: "📋"
            font.pixelSize: 16
        }
        
        onClicked: {
            clipWindow.visible = !clipWindow.visible
        }
    }

    // Instantiating the window, but keeping it hidden until clicked
    ClipboardWindow {
        id: clipWindow
        visible: false 
    }
}
