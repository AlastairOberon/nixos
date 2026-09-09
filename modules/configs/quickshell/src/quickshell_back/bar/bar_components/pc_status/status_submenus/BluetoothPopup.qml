import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 
import Quickshell
import Quickshell.Io
import "../../" 
import "../" 

BlueprintPopup {
    id: btPopup
    
    popupWidth: 560 
    popupHeight: 460 
    isTopBar: true
    isSubMenu: true
    barOverlap: -120 
    timeoutDuration: 0 

    property bool showInBar: true
    signal toggleShowInBar()

    property bool isBluetoothOn: false

    HoverHandler { id: submenuHover }
    Timer {
        id: decayTimer
        interval: 2500 
        running: btPopup.visible && !submenuHover.hovered
        onTriggered: btPopup.closeSilently() 
    }

    ListModel { id: deviceModel }
    property var tempList: []

    Process {
        id: btPoller
        command: ["bash", "-c", "
            state=$(bluetoothctl show 2>/dev/null | grep 'Powered: yes' >/dev/null && echo '1' || echo '0')
            echo \"STATE|$state\"
            
            bluetoothctl devices Connected 2>/dev/null | while read -r _ mac name; do
                card=\"bluez_card.${mac//:/_}\"
                card_info=$(pactl list cards 2>/dev/null | awk -v RS='' \"/Name: $card/\")
                
                if [ -n \"$card_info\" ]; then
                    active_prof=$(echo \"$card_info\" | grep 'Active Profile:' | cut -d: -f2- | xargs)
                    profiles=$(echo \"$card_info\" | awk '/Profiles:/{flag=1; next} /Active Profile:/{flag=0} flag' | cut -d: -f1 | xargs | tr ' ' ',')
                else
                    active_prof=\"N/A\"
                    profiles=\"\"
                fi
                
                echo \"DEV|$mac|$name|$active_prof|$profiles\"
            done
        "]
        
        stdout: SplitParser {
            onRead: function(data) {
                let parts = data.trim().split('|');
                
                if (parts[0] === "STATE") {
                    btPopup.isBluetoothOn = (parts[1] === "1");
                } 
                else if (parts[0] === "DEV" && parts.length >= 5) {
                    btPopup.tempList.push({
                        devId: parts[1], 
                        devName: parts[2], 
                        activeProfile: parts[3],
                        profileString: parts[4]
                    });
                }
            }
        }
        
        onExited: {
            deviceModel.clear();
            for(let i=0; i<btPopup.tempList.length; i++) {
                deviceModel.append(btPopup.tempList[i]);
            }
            btPopup.tempList = [];
        }
    }

    Timer {
        interval: 3000
        running: btPopup.visible
        repeat: true
        onTriggered: btPoller.running = true
        triggeredOnStart: true
    }

    Process { 
        id: actionProcess 
        onExited: {
            syncTimer.restart();
        }
    }

    Timer {
        id: syncTimer
        interval: 400
        onTriggered: btPoller.running = true
    }

    function toggleBluetooth() {
        let nextState = !isBluetoothOn;
        isBluetoothOn = nextState;
        
        let action = nextState ? "on" : "off";
        actionProcess.command = ["bash", "-c", `bluetoothctl power ${action}`];
        actionProcess.running = true;
    }

    function disconnectDevice(id) {
        actionProcess.command = ["bash", "-c", `bluetoothctl disconnect ${id}`];
        actionProcess.running = true;
    }

    function setProfile(mac, profile, outerIndex) {
        deviceModel.setProperty(outerIndex, "activeProfile", profile);
        
        let card = "bluez_card." + mac.replace(/:/g, "_");
        actionProcess.command = ["bash", "-c", `pactl set-card-profile ${card} ${profile}`];
        actionProcess.running = true;
    }

    // THE FIX: Smart Codec Parsing!
    // Extracts the specific audio codec to differentiate the buttons.
    function formatProfileName(prof) {
        if (!prof || prof === "N/A") return "Not Available";
        let p = prof.toLowerCase();

        // 1. High Fidelity Music Profiles
        if (p.includes("a2dp")) {
            if (p.includes("aac")) return "High Fidelity (AAC)";
            if (p.includes("aptx_ll")) return "High Fidelity (aptX-LL)";
            if (p.includes("aptx_hd")) return "High Fidelity (aptX-HD)";
            if (p.includes("aptx")) return "High Fidelity (aptX)";
            if (p.includes("ldac")) return "High Fidelity (LDAC)";
            if (p.includes("sbc_xq") || p.includes("sbc-xq")) return "High Fidelity (SBC-XQ)";
            if (p.includes("sbc")) return "High Fidelity (SBC)";
            return "High Fidelity (Auto)";
        }
        
        // 2. Voice Call / Microphone Profiles
        if (p.includes("headset") || p.includes("handsfree") || p.includes("hfp") || p.includes("hsp")) {
            if (p.includes("msbc")) return "Headset (mSBC)";
            if (p.includes("cvsd")) return "Headset (CVSD)";
            return "Headset (Auto)";
        }
        
        if (p === "off") return "Disabled";
        return prof.charAt(0).toUpperCase() + prof.slice(1);
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
            color: btPopup.showInBar ? Theme.main : Theme.secondaryBase
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: btPopup.showInBar ? "󰈈 Shown in Bar" : "󰈉 Hidden from Bar"
                font.bold: true; font.pixelSize: 16 
                color: btPopup.showInBar ? Theme.base : Theme.main
            }

            MouseArea {
                id: showInBarMouse
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: btPopup.toggleShowInBar()
            }
            Rectangle { 
                anchors.fill: parent; radius: height / 2; color: "#FFFFFF" 
                opacity: showInBarMouse.containsMouse ? 0.15 : 0 
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        // --- GLOBAL BLUETOOTH TOGGLE ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44 
            radius: height / 2 
            color: btPopup.isBluetoothOn ? Theme.main : Theme.secondaryBase
            Behavior on color { ColorAnimation { duration: 200 } }

            Text {
                anchors.centerIn: parent
                text: btPopup.isBluetoothOn ? "󰂯 Bluetooth: ON" : "󰂲 Bluetooth: OFF"
                font.bold: true; font.pixelSize: 16 
                color: btPopup.isBluetoothOn ? Theme.base : Theme.inactive
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            MouseArea {
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: btPopup.toggleBluetooth()
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.secondaryBase }

        Text { 
            text: "Connected Devices & Audio Profiles"
            color: Theme.text; font.bold: true; font.pixelSize: 15
        }

        // --- EMPTY STATES ---
        Text {
            visible: !btPopup.isBluetoothOn
            text: "Bluetooth is currently powered off."
            color: Theme.inactive; font.pixelSize: 14; font.italic: true
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
        }

        Text {
            visible: btPopup.isBluetoothOn && deviceModel.count === 0
            text: "No devices connected."
            color: Theme.inactive; font.pixelSize: 14; font.italic: true
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
        }

        // --- CONNECTED DEVICES LIST ---
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: btPopup.isBluetoothOn && deviceModel.count > 0
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            contentWidth: availableWidth 

            ColumnLayout {
                width: parent.width
                spacing: 12

                Repeater {
                    model: deviceModel

                    delegate: Rectangle {
                        id: devDelegate
                        Layout.fillWidth: true
                        height: innerLayout.implicitHeight + 24
                        radius: 8
                        color: Theme.secondaryBase
                        
                        property string devMac: model.devId
                        property string currentProfile: model.activeProfile
                        property int outerIndex: index
                        property var profilesArray: model.profileString !== "" ? model.profileString.split(',') : []

                        ColumnLayout {
                            id: innerLayout
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Text {
                                    text: "󰂯"
                                    color: Theme.main
                                    font.pixelSize: 18
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: model.devName
                                    color: Theme.text
                                    font.pixelSize: 14
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    width: 85; height: 28; radius: 14
                                    color: "transparent"
                                    border.color: Theme.bridge; border.width: 1
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Disconnect"
                                        color: Theme.text
                                        font.pixelSize: 12
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: btPopup.disconnectDevice(devDelegate.devMac)
                                    }
                                }
                            }

                            Text {
                                visible: devDelegate.profilesArray.length > 0
                                text: "Active Profile: " + btPopup.formatProfileName(devDelegate.currentProfile)
                                color: Theme.inactive
                                font.pixelSize: 13
                                font.italic: true
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: devDelegate.profilesArray.length > 0

                                Repeater {
                                    model: devDelegate.profilesArray
                                    
                                    delegate: Rectangle {
                                        height: 28
                                        width: profText.implicitWidth + 24
                                        radius: 14
                                        
                                        property bool isActive: devDelegate.currentProfile === modelData
                                        
                                        color: isActive ? Theme.main : "transparent"
                                        border.color: isActive ? "transparent" : Theme.bridge
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            id: profText
                                            anchors.centerIn: parent
                                            text: btPopup.formatProfileName(modelData)
                                            color: parent.isActive ? Theme.base : Theme.text
                                            font.pixelSize: 11
                                            font.bold: parent.isActive
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: btPopup.setProfile(devDelegate.devMac, modelData, devDelegate.outerIndex)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
