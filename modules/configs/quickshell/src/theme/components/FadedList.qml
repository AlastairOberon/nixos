pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "../"

Item {
    id: root

    // Expose all the important ListView properties
    property alias model            : listView.model
    property alias delegate         : listView.delegate
    property alias currentIndex     : listView.currentIndex
    property alias spacing          : listView.spacing
    property alias count            : listView.count

    ListView {
        id              : listView
        anchors.fill    : parent
        clip            : true
        
        // Universal safe zone for scaling buttons so they don't clip
        leftMargin      : Metrics.spacingBase
        rightMargin     : Metrics.spacingBase
        topMargin       : 0
        bottomMargin    : Metrics.spacingLarge

        layer.enabled   : true

        layer.effect    : MultiEffect {
            maskEnabled : true
            maskSource  : fadeMask
        }
    }

   Item {
        id              : fadeMask
        anchors.fill    : listView
        visible         : false 
        layer.enabled   : true 

        // Main Body
        Rectangle {
            anchors.top     : parent.top
            anchors.bottom  : parent.bottom
            anchors.left    : parent.left
            anchors.right   : parent.right
            color           : "white"
        }
    } 
}
