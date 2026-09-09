import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 
import Quickshell
import Quickshell.Io
import "../../" 
import "../" 

BlueprintPopup {
    id: brightPopup
    
    popupWidth: 560 
    // THE FIX: Bumped height up to 260 so nothing gets cut off!
    popupHeight: 260 
    isTopBar: true
    isSubMenu: true
    barOverlap: -120 
    timeoutDuration: 0 

    property bool showInBar: true
    signal toggleShowInBar()

    property int brightnessValue: 100
    property int savedBrightness: 100

    HoverHandler { id: submenuHover }
    Timer {
        id: decayTimer
        interval: 2500 
        running: brightPopup.visible && !submenuHover.hovered && !brightSlider.pressed
        onTriggered: brightPopup.closeSilently() 
    }

    Process {
        id: brightPoller
        command: ["bash", "-c", "brightnessctl -m | awk -F, '{print $4}' | tr -d '%'"]
        stdout: SplitParser {
            onRead: function(data) {
                let val = parseInt(data.trim());
                if (!isNaN(val)) brightPopup.brightnessValue = val;
            }
        }
    }

    Timer {
        interval: 2000
        running: brightPopup.visible
        repeat: true
        onTriggered: brightPoller.running = true
        triggeredOnStart: true
    }

    onBrightnessValueChanged: {
        if (!brightSlider.pressed) {
            brightSlider.value = brightnessValue;
        }
    }

    Process { id: actionProcess }
    
    function setBrightness(val) {
        brightPopup.brightnessValue = val;
        actionProcess.command = ["bash", "-c", `brightnessctl set ${val}%`];
        actionProcess.running = true;
    }

    function toggleBacklight() {
        if (brightnessValue > 0) {
            savedBrightness = brightnessValue; 
            setBrightness(0);
        } else {
            setBrightness(savedBrightness > 0 ? savedBrightness : 100);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        // --- VISIBILITY TOGGLE ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42 
            radius: height / 2 
            color: brightPopup.showInBar ? Theme.main : Theme.secondaryBase
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: brightPopup.showInBar ? "󰈈 Shown in Bar" : "󰈉 Hidden from Bar"
                font.bold: true; font.pixelSize: 16 
                color: brightPopup.showInBar ? Theme.base : Theme.main
            }

            MouseArea {
                id: showInBarMouse
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: brightPopup.toggleShowInBar()
            }
            Rectangle { 
                anchors.fill: parent; radius: height / 2; color: "#FFFFFF" 
                opacity: showInBarMouse.containsMouse ? 0.15 : 0 
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.secondaryBase }

        // --- BRIGHTNESS SLIDER ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text { 
                text: brightPopup.brightnessValue === 0 ? "󰃭" : "󰃠"
                color: brightPopup.brightnessValue === 0 ? Theme.inactive : Theme.main
                font.pixelSize: 20 
            }

            Slider {
                id: brightSlider
                Layout.fillWidth: true
                from: 0
                to: 100
                value: brightPopup.brightnessValue
                
                onMoved: brightPopup.setBrightness(Math.round(value))

                background: Rectangle {
                    x: brightSlider.leftPadding
                    y: brightSlider.topPadding + brightSlider.availableHeight / 2 - height / 2
                    implicitWidth: 200; implicitHeight: 8
                    width: brightSlider.availableWidth; height: implicitHeight
                    radius: 4; color: Theme.secondaryBase

                    Rectangle {
                        width: brightSlider.visualPosition * parent.width
                        height: parent.height
                        color: Theme.main; radius: 4
                    }
                }
                
                handle: Rectangle {
                    x: brightSlider.leftPadding + brightSlider.visualPosition * (brightSlider.availableWidth - width)
                    y: brightSlider.topPadding + brightSlider.availableHeight / 2 - height / 2
                    implicitWidth: 20; implicitHeight: 20
                    radius: 10; color: Theme.main
                    border.color: Theme.base; border.width: 2
                }
            }
        }

        Item { Layout.fillHeight: true } // Pusher

        // --- BACKLIGHT TOGGLE ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: 8
            color: brightPopup.brightnessValue > 0 ? Theme.secondaryBase : Theme.main
            border.color: brightPopup.brightnessValue > 0 ? Theme.bridge : "transparent"
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                anchors.centerIn: parent
                spacing: 8
                Text { text: brightPopup.brightnessValue > 0 ? "󰃭" : "󰃠"; color: brightPopup.brightnessValue > 0 ? Theme.text : Theme.base; font.pixelSize: 16 }
                Text { text: brightPopup.brightnessValue > 0 ? "Turn Backlight Off" : "Turn Backlight On"; color: brightPopup.brightnessValue > 0 ? Theme.text : Theme.base; font.bold: true; font.pixelSize: 13 }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: brightPopup.toggleBacklight()
            }
        }
    }
}
