import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"

PanelWindow {
    id                              : template_floating
    color                           : "transparent"
    WlrLayershell.namespace         : "quickshell"
    WlrLayershell.layer             : WlrLayer.Overlay

    // 1. We completely REMOVE the top/bottom/left/right anchors!
    // Without anchors, Wayland automatically floats this perfectly in the center of your screen.

    // 2. We tie the Wayland window size EXACTLY to your floating widget size.
    implicitWidth: floating_window.width
    implicitHeight: floating_window.height

    property alias windowWidth: floating_window.width
    property alias windowHeight: floating_window.height

    default property alias content  : floating_window.data

    // 3. The full-screen dim_Background and MouseArea are DELETED.
    // There is no longer an invisible shield eating your clicks!

    Rectangle {
        id              : floating_window
        color           : Theme.base
        radius          : Metrics.radiusLarge

        border.width: 2
        border.color: hoverHandler.hovered ? Theme.main : Theme.base
        
        Behavior on border.color {
            ColorAnimation { duration: Metrics.animFast }
        }
        
        HoverHandler {
            id: hoverHandler
        }
    }
}
