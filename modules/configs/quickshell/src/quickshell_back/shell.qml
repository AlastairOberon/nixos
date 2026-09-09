import QtQuick
import Quickshell
import Quickshell.Wayland

import "./bar" as Components


ShellRoot {
    // Your Top Bar
    PanelWindow {
        id: topWindow 
        
        anchors.top: true
        anchors.left: true
        anchors.right: true
        implicitHeight: 40 
        
        WlrLayershell.namespace: "quickshell"
        color: "transparent"

        Components.Bar_t {
            parentWindow: topWindow 
        }
    }

    // Your Bottom Bar
    PanelWindow {
        id: bottomWindow 
        
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        implicitHeight: 40 
        
        WlrLayershell.namespace: "quickshell"
        color: "transparent"

        Components.Bar_b {
            parentWindow: bottomWindow 
        }
    }
}
