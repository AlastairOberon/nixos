import QtQuick
import QtQuick.Layouts
import "../../" // <-- THE FIX: Ensures QML can find Theme.main so it stops defaulting to white!
import "../" 

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 32 

    // The maximum limit of the slider (2.0 = 200%)
    property real maxValue: 2.0 
    
    property real value: 0.0
    property real internalValue: 0.0
    property bool isActive: true 
    
    property real displayValue: mouseArea.pressed ? internalValue : value

    signal moved(real newValue) 
    signal applied(real finalValue) 

    // --- 1. THE BACKGROUND TRACK ---
    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 8 
        radius: 4
        
        // A translucent background so the active bar pops out
        color: Qt.rgba(1, 1, 1, 0.15) 

        // --- 1.5 THE 100% MARKER NOTCH ---
        Rectangle {
            // Positions the notch exactly at 1.0 (100%)
            x: (track.width / root.maxValue) - (width / 2)
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: 14 // Slightly taller than the track for a premium "threshold" look
            radius: 1
            color: Theme.base 
            opacity: 0.6
            z: 1 
        }

        // --- 2. THE ACTIVE FILL ---
        Rectangle {
            id: activeFill
            // Scales the physical width based on the 2.0 maxValue
            width: Math.max(0, Math.min(track.width, track.width * (root.displayValue / root.maxValue)))
            height: parent.height
            radius: 4
            z: 2
            
            // THE COLOR FIX: Instantly switches the whole bar to the secondary color past 100%
            color: root.displayValue > 1.00 ? Theme.secondary : Theme.main 
            Behavior on color { ColorAnimation { duration: 250 } }
            
            Behavior on width { 
                enabled: !mouseArea.pressed
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic } 
            }

            // --- 3. THE THUMB / GRABBER ---
            Rectangle {
                width: 14; height: 14; radius: 7
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width - (width / 2) 
                
                // Automatically inherits whatever color the active bar is currently using
                color: activeFill.color 
                
                border.color: Theme.base 
                border.width: 2
                Behavior on border.color { ColorAnimation { duration: 300 } }
                
                scale: mouseArea.pressed ? 1.3 : (mouseArea.containsMouse ? 1.1 : 1.0)
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            }
        }
    }

    // --- 4. THE INTERACTION ZONE ---
    MouseArea {
        id: mouseArea
        anchors.fill: parent 
        hoverEnabled: true 
        cursorShape: Qt.PointingHandCursor

        onPositionChanged: (mouse) => {
            if (pressed) {
                // Scales the mouse position math up to our 2.0 limit
                root.internalValue = Math.max(0, Math.min(root.maxValue, (mouse.x / root.width) * root.maxValue));
                root.moved(root.internalValue);
            }
        }
        
        onPressed: (mouse) => {
            root.internalValue = Math.max(0, Math.min(root.maxValue, (mouse.x / root.width) * root.maxValue));
            root.moved(root.internalValue);
        }

        onReleased: {
            root.applied(root.internalValue);
        }
    }
}
