import QtQuick
import QtQuick.Layouts
import "../" 

BlueprintPopup {
    id: rootPopup

    popupWidth: 560
    popupHeight: 80 
    isTopBar: true 
    timeoutDuration: 0

    property bool isNetActive: false
    property bool isAudioActive: false
    property bool isBrightnessActive: false
    property bool isPowerActive: false
    property bool isBluetoothActive: false 

    // THE FIX: Reordered to match your new layout priority!
    property int activeMenu: {
        if (isNetActive) return 1;
        if (isBrightnessActive) return 2;
        if (isAudioActive) return 3;
        if (isBluetoothActive) return 4; 
        if (isPowerActive) return 5;
        return 0;
    }

    signal toggleNetwork()
    signal toggleAudio()
    signal toggleBrightness()
    signal togglePower()
    signal toggleBluetooth() 

    HoverHandler { id: menuHover }
    Timer {
        id: decayTimer
        interval: 2500 
        running: rootPopup.visible && !menuHover.hovered && rootPopup.activeMenu === 0
        onTriggered: rootPopup.closeSilently() 
    }

    Item {
        id: container
        anchors.fill: parent
        anchors.margins: 15

        Rectangle {
            id: slidingPill
            
            // THE FIX: Made the pill slightly shorter than the container and centered it perfectly
            height: parent.height - 10
            y: 5 
            radius: height / 2
            
            color: Theme.main
            opacity: rootPopup.activeMenu !== 0 ? 1 : 0
            
            x: {
                if (rootPopup.activeMenu === 1) return rowLayout.x + btnNet.x;
                if (rootPopup.activeMenu === 2) return rowLayout.x + btnBrightness.x;
                if (rootPopup.activeMenu === 3) return rowLayout.x + btnAudio.x;
                if (rootPopup.activeMenu === 4) return rowLayout.x + btnBluetooth.x; 
                if (rootPopup.activeMenu === 5) return rowLayout.x + btnPower.x;
                return 0;
            }
            
            width: {
                if (rootPopup.activeMenu === 1) return btnNet.width;
                if (rootPopup.activeMenu === 2) return btnBrightness.width;
                if (rootPopup.activeMenu === 3) return btnAudio.width;
                if (rootPopup.activeMenu === 4) return btnBluetooth.width; 
                if (rootPopup.activeMenu === 5) return btnPower.width;
                return 0;
            }
            
            Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        RowLayout {
            id: rowLayout
            anchors.fill: parent
            spacing: 12

            // --- 1. NET ---
            Item {
                id: btnNet
                // THE FIX: Forces every button to be exactly the same width!
                Layout.preferredWidth: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Text { 
                    anchors.centerIn: parent
                    text: "󰤨 Net"
                    font.bold: true
                    font.pixelSize: 14
                    color: rootPopup.isNetActive ? Theme.base : "#FFFFFF"
                    opacity: (!rootPopup.isNetActive && mouseNet.containsMouse) ? 0.6 : 1.0
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                MouseArea { 
                    id: mouseNet
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rootPopup.toggleNetwork() 
                }
            }

            // --- 2. BRIGHTNESS ---
            Item {
                id: btnBrightness
                Layout.preferredWidth: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Text { 
                    anchors.centerIn: parent
                    text: "󰃠 Display"
                    font.bold: true
                    font.pixelSize: 14
                    color: rootPopup.isBrightnessActive ? Theme.base : "#FFFFFF"
                    opacity: (!rootPopup.isBrightnessActive && mouseBrightness.containsMouse) ? 0.6 : 1.0
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                MouseArea { 
                    id: mouseBrightness
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rootPopup.toggleBrightness() 
                }
            }

            // --- 3. AUDIO ---
            Item {
                id: btnAudio
                Layout.preferredWidth: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Text { 
                    anchors.centerIn: parent
                    text: "󰕾 Audio"
                    font.bold: true
                    font.pixelSize: 14
                    color: rootPopup.isAudioActive ? Theme.base : "#FFFFFF"
                    opacity: (!rootPopup.isAudioActive && mouseAudio.containsMouse) ? 0.6 : 1.0
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                MouseArea { 
                    id: mouseAudio
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rootPopup.toggleAudio() 
                }
            }

            // --- 4. BLUETOOTH ---
            Item {
                id: btnBluetooth
                Layout.preferredWidth: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Text { 
                    anchors.centerIn: parent
                    text: "󰂯 Bluetooth"
                    font.bold: true
                    font.pixelSize: 14
                    color: rootPopup.isBluetoothActive ? Theme.base : "#FFFFFF"
                    opacity: (!rootPopup.isBluetoothActive && mouseBluetooth.containsMouse) ? 0.6 : 1.0
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                MouseArea { 
                    id: mouseBluetooth
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rootPopup.toggleBluetooth() 
                }
            }

            // --- 5. POWER ---
            Item {
                id: btnPower
                Layout.preferredWidth: 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Text { 
                    anchors.centerIn: parent
                    text: "󰁹 Power"
                    font.bold: true
                    font.pixelSize: 14
                    color: rootPopup.isPowerActive ? Theme.base : "#FFFFFF"
                    opacity: (!rootPopup.isPowerActive && mousePower.containsMouse) ? 0.6 : 1.0
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                MouseArea { 
                    id: mousePower
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rootPopup.togglePower() 
                }
            }
        }
    }
}
