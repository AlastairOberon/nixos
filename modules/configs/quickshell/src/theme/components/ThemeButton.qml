import QtQuick
import "../" 

Rectangle {
    id      : root
    width   : 100
    height  : 60
    radius  : Metrics.radiusBase

    property bool selected : false
    property bool isActive : hoverArea.containsMouse || selected
    
    signal clicked()

    z: isActive ?
        10 : 0

    color: isActive         ? Theme.main        : Theme.base
    border.color: isActive  ? Theme.secondary   : Theme.bridge
    scale: isActive         ? 1.03              : 1.0
    border.width: 2

    Behavior on color {
        ColorAnimation {
            duration        : Metrics.animBase;
            easing.type     : Easing.OutQuint
        }
    }
    Behavior on border.color {
        ColorAnimation {
            duration        : Metrics.animBase;
            easing.type     : Easing.OutQuint
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration        : Metrics.animBase;
            easing.type     : Easing.OutCubic
        }
    }

    default property alias content: contentItem.data
    Item {
        id              : contentItem
        anchors.fill    : parent
    }

    MouseArea {
        id              : hoverArea
        anchors.fill    : parent
        hoverEnabled    : true
        onClicked       : root.clicked()
    }
}
