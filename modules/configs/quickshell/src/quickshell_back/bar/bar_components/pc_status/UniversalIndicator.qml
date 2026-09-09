import QtQuick
import QtQuick.Layouts
import "../" 
import "./status_submenus" 

Item {
    id: indicatorRoot

    implicitWidth: pillBg.width
    width: implicitWidth
    height: parent.height

    property var parentWindow

    property bool showNet: true
    property bool showBluetooth: true 
    property bool showAudio: true
    property bool showBrightness: true
    property bool showPower: true

    function toggleExclusive(targetPopup) {
        if (targetPopup !== connectivityPopup) connectivityPopup.closeSilently();
        if (targetPopup !== audioPopup) audioPopup.closeSilently();
        if (targetPopup !== brightPopup) brightPopup.closeSilently();
        if (targetPopup !== btPopup) btPopup.closeSilently();
        if (targetPopup !== pwrPopup) pwrPopup.closeSilently();
        targetPopup.toggle();
    }

    UniversalPopup {
        id: universalPopup
        parentWindow: indicatorRoot.parentWindow
        anchorTarget: indicatorRoot 

        isNetActive: connectivityPopup.visible
        isAudioActive: audioPopup.visible
        isBrightnessActive: brightPopup.visible
        isBluetoothActive: btPopup.visible 
        isPowerActive: pwrPopup.visible

        onToggleNetwork: indicatorRoot.toggleExclusive(connectivityPopup)
        onToggleAudio: indicatorRoot.toggleExclusive(audioPopup)
        onToggleBrightness: indicatorRoot.toggleExclusive(brightPopup)
        onToggleBluetooth: indicatorRoot.toggleExclusive(btPopup)
        onTogglePower: indicatorRoot.toggleExclusive(pwrPopup)

        onAboutToClose: {
            connectivityPopup.closeSilently()
            audioPopup.closeSilently()
            brightPopup.closeSilently()
            btPopup.closeSilently()
            pwrPopup.closeSilently()
        }
    }

    ConnectivityPopup {
        id: connectivityPopup
        parentWindow: indicatorRoot.parentWindow
        anchorTarget: indicatorRoot 
        property var networkData: liveNetworkData 
        showInBar: indicatorRoot.showNet
        onToggleShowInBar: indicatorRoot.showNet = !indicatorRoot.showNet
    }

    AudioPopup {
        id: audioPopup
        parentWindow: indicatorRoot.parentWindow
        anchorTarget: indicatorRoot 
        showInBar: indicatorRoot.showAudio
        onToggleShowInBar: indicatorRoot.showAudio = !indicatorRoot.showAudio
    }

    BrightnessPopup {
        id: brightPopup
        parentWindow: indicatorRoot.parentWindow
        anchorTarget: indicatorRoot 
        showInBar: indicatorRoot.showBrightness
        onToggleShowInBar: indicatorRoot.showBrightness = !indicatorRoot.showBrightness
    }

    BluetoothPopup {
        id: btPopup
        parentWindow: indicatorRoot.parentWindow
        anchorTarget: indicatorRoot 
        showInBar: indicatorRoot.showBluetooth
        onToggleShowInBar: indicatorRoot.showBluetooth = !indicatorRoot.showBluetooth
    }

    PowerPopup {
        id: pwrPopup
        parentWindow: indicatorRoot.parentWindow
        anchorTarget: indicatorRoot 
        showInBar: indicatorRoot.showPower
        onToggleShowInBar: indicatorRoot.showPower = !indicatorRoot.showPower
    }

    Rectangle {
        id: pillBg
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right 

        width: Math.max(indicatorRow.implicitWidth + 24, 48)
        height: 32 
        radius: height / 2

        color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
        // REMOVED border.color and border.width to make it borderless

        Row {
            id: indicatorRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 12
            spacing: 12

            // --- 1. NETWORK (WIFI) ---
            Item {
                anchors.verticalCenter: parent.verticalCenter
                property bool active: indicatorRoot.showNet
                property bool spaceAllocated: active; property bool contentVisible: active
                onActiveChanged: { if (active) { spaceAllocated = true; netShowTimer.restart(); } else { contentVisible = false; netHideTimer.restart(); } }
                Timer { id: netShowTimer; interval: 300; onTriggered: parent.contentVisible = true }
                Timer { id: netHideTimer; interval: 150; onTriggered: parent.spaceAllocated = false }

                width: spaceAllocated ? liveNetworkData.implicitWidth : 0; height: liveNetworkData.implicitHeight
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                clip: true; visible: width > 0

                NetworkStatusIndicator { id: liveNetworkData; anchors.verticalCenter: parent.verticalCenter; opacity: parent.contentVisible ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 150 } } }
            }

            // --- 2. BRIGHTNESS ---
            Item {
                anchors.verticalCenter: parent.verticalCenter
                property bool active: indicatorRoot.showBrightness
                property bool spaceAllocated: active; property bool contentVisible: active
                onActiveChanged: { if (active) { spaceAllocated = true; brightShowTimer.restart(); } else { contentVisible = false; brightHideTimer.restart(); } }
                Timer { id: brightShowTimer; interval: 300; onTriggered: parent.contentVisible = true }
                Timer { id: brightHideTimer; interval: 150; onTriggered: parent.spaceAllocated = false }

                width: spaceAllocated ? liveBrightData.implicitWidth : 0; height: liveBrightData.implicitHeight
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                clip: true; visible: width > 0

                BrightnessStatusIndicator { id: liveBrightData; anchors.verticalCenter: parent.verticalCenter; opacity: parent.contentVisible ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 150 } } }
            }

            // --- 3. AUDIO ---
            Item {
                anchors.verticalCenter: parent.verticalCenter
                property bool active: indicatorRoot.showAudio
                property bool spaceAllocated: active; property bool contentVisible: active
                onActiveChanged: { if (active) { spaceAllocated = true; audioShowTimer.restart(); } else { contentVisible = false; audioHideTimer.restart(); } }
                Timer { id: audioShowTimer; interval: 300; onTriggered: parent.contentVisible = true }
                Timer { id: audioHideTimer; interval: 150; onTriggered: parent.spaceAllocated = false }

                width: spaceAllocated ? liveAudioData.implicitWidth : 0; height: liveAudioData.implicitHeight
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                clip: true; visible: width > 0

                AudioStatusIndicator { id: liveAudioData; anchors.verticalCenter: parent.verticalCenter; opacity: parent.contentVisible ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 150 } } }
            }
            
            // --- 4. BLUETOOTH ---
            Item {
                anchors.verticalCenter: parent.verticalCenter
                property bool active: indicatorRoot.showBluetooth
                property bool spaceAllocated: active; property bool contentVisible: active
                onActiveChanged: { if (active) { spaceAllocated = true; btShowTimer.restart(); } else { contentVisible = false; btHideTimer.restart(); } }
                Timer { id: btShowTimer; interval: 300; onTriggered: parent.contentVisible = true }
                Timer { id: btHideTimer; interval: 150; onTriggered: parent.spaceAllocated = false }

                width: spaceAllocated ? liveBluetoothData.implicitWidth : 0; height: liveBluetoothData.implicitHeight
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                clip: true; visible: width > 0

                BluetoothStatusIndicator { id: liveBluetoothData; anchors.verticalCenter: parent.verticalCenter; opacity: parent.contentVisible ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 150 } } }
            }

            // --- 5. POWER (BATTERY) ---
            Item {
                anchors.verticalCenter: parent.verticalCenter
                property bool active: indicatorRoot.showPower
                property bool spaceAllocated: active; property bool contentVisible: active
                onActiveChanged: { if (active) { spaceAllocated = true; pwrShowTimer.restart(); } else { contentVisible = false; pwrHideTimer.restart(); } }
                Timer { id: pwrShowTimer; interval: 300; onTriggered: parent.contentVisible = true }
                Timer { id: pwrHideTimer; interval: 150; onTriggered: parent.spaceAllocated = false }

                width: spaceAllocated ? livePowerData.implicitWidth : 0; height: livePowerData.implicitHeight
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                clip: true; visible: width > 0

                PowerStatusIndicator { id: livePowerData; anchors.verticalCenter: parent.verticalCenter; opacity: parent.contentVisible ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 150 } } }
            }

            // --- 6. MINIMALIST DOT ---
            Item {
                anchors.verticalCenter: parent.verticalCenter
                property bool active: !indicatorRoot.showNet && !indicatorRoot.showBluetooth && !indicatorRoot.showAudio && !indicatorRoot.showBrightness && !indicatorRoot.showPower
                property bool spaceAllocated: active; property bool contentVisible: active
                onActiveChanged: { if (active) { spaceAllocated = true; dotShowTimer.restart(); } else { contentVisible = false; dotHideTimer.restart(); } }
                Timer { id: dotShowTimer; interval: 300; onTriggered: parent.contentVisible = true }
                Timer { id: dotHideTimer; interval: 150; onTriggered: parent.spaceAllocated = false }

                width: spaceAllocated ? dotContent.implicitWidth : 0; height: dotContent.implicitHeight
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                clip: true; visible: width > 0

                Text { id: dotContent; anchors.verticalCenter: parent.verticalCenter; text: "●"; color: Theme.text; font.pixelSize: 12; opacity: parent.contentVisible ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 150 } } }
            }
        }

        MouseArea { 
            id: mouseArea 
            anchors.fill: parent
            hoverEnabled: true
            onClicked: universalPopup.toggle() 
        }
    }
}
