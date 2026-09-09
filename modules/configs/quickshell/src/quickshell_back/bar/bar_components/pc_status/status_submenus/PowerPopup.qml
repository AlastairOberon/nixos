import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 
import Quickshell
import Quickshell.Io
import "../../" 
import "../" 

BlueprintPopup {
    id: pwrPopup
    
    popupWidth: 560 
    // THE FIX: Bumped up to 480 to guarantee the bottom buttons are never cut off!
    popupHeight: 480 
    isTopBar: true
    isSubMenu: true
    barOverlap: -120 
    timeoutDuration: 0 

    property bool showInBar: true
    signal toggleShowInBar()

    HoverHandler { id: submenuHover }
    Timer {
        id: decayTimer
        interval: 2500 
        running: pwrPopup.visible && !submenuHover.hovered
        onTriggered: pwrPopup.closeSilently() 
    }

    // --- POWER STATE PROPERTIES ---
    property string pwrType: "BATTERY"
    property int pwrCapacity: 0
    property string pwrStatus: "Unknown"
    property string pwrTimeStr: "Calculating..."
    property string activeProfile: "balanced"
    property bool isPluggedIn: false

    onIsPluggedInChanged: {
        if (!isPluggedIn) hugeIcon.opacity = 1.0;
    }

    Process {
        id: pwrPoller
        command: ["bash", "-c", "
            # 1. Grab the current Power Profile
            profile=$(powerprofilesctl get 2>/dev/null || echo 'balanced')
            
            # 2. Check for physical AC adapter
            ac_online=0
            for ac in /sys/class/power_supply/AC* /sys/class/power_supply/ADP* /sys/class/power_supply/macsmc-ac*; do
                if [ -f \"$ac/online\" ] && [ \"$(cat $ac/online 2>/dev/null)\" = \"1\" ]; then
                    ac_online=1
                    break
                fi
            done
            
            # 3. Check for a Battery
            bat_path=$(ls -1d /sys/class/power_supply/BAT* 2>/dev/null | head -n 1)
            if [ -z \"$bat_path\" ]; then
                echo \"DESKTOP|100|AC||$profile|1\"
            else
                capacity=$(cat \"$bat_path/capacity\" 2>/dev/null || echo \"0\")
                status=$(cat \"$bat_path/status\" 2>/dev/null || echo \"Unknown\")
                
                # 4. THE FIX: Smart Time Calculation & Battery Protection Detection
                time_str=\"\"
                
                # Try upower first
                if command -v upower >/dev/null 2>&1; then
                    bat_dev=$(upower -e 2>/dev/null | grep -i -E 'bat|macsmc' | head -n 1)
                    if [ -n \"$bat_dev\" ]; then
                        time_str=$(upower -i \"$bat_dev\" 2>/dev/null | grep -E 'time to' | cut -d: -f2 | xargs)
                        if [ -n \"$time_str\" ]; then
                            if [ \"$ac_online\" = \"1\" ]; then
                                time_str=\"$time_str until full\"
                            else
                                time_str=\"$time_str remaining\"
                            fi
                        fi
                    fi
                fi
                
                # Fallback to acpi if upower fails or returns blank
                if [ -z \"$time_str\" ] && command -v acpi >/dev/null 2>&1; then
                    time_str=$(acpi -b 2>/dev/null | grep -o -E '[0-9]+:[0-9]+:[0-9]+.*')
                fi
                
                # If STILL blank, dynamically evaluate the battery's context!
                if [ -z \"$time_str\" ]; then
                    if [ \"$capacity\" -ge 95 ] && [ \"$ac_online\" = \"1\" ]; then
                        time_str=\"Fully Charged\"
                    elif [ \"$status\" = \"Not charging\" ] || [ \"$status\" = \"Full\" ]; then
                        time_str=\"Connected, Not Charging\"
                    else
                        time_str=\"Calculating...\"
                    fi
                fi
                
                echo \"BATTERY|$capacity|$status|$time_str|$profile|$ac_online\"
            fi
        "]
        stdout: SplitParser {
            onRead: function(data) {
                let parts = data.trim().split('|');
                if (parts.length >= 6) {
                    pwrPopup.pwrType = parts[0];
                    pwrPopup.pwrCapacity = parseInt(parts[1]) || 0;
                    pwrPopup.pwrStatus = parts[2];
                    pwrPopup.pwrTimeStr = parts[3];
                    pwrPopup.activeProfile = parts[4];
                    pwrPopup.isPluggedIn = (parts[5] === "1");
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: pwrPopup.visible
        repeat: true
        onTriggered: pwrPoller.running = true
        triggeredOnStart: true
    }

    // --- POWER PROFILE CHANGER ---
    Process { id: actionProcess }
    
    function setProfile(prof) {
        pwrPopup.activeProfile = prof;
        actionProcess.command = ["bash", "-c", `powerprofilesctl set ${prof}`];
        actionProcess.running = true;
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
            color: pwrPopup.showInBar ? Theme.main : Theme.secondaryBase
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: pwrPopup.showInBar ? "󰈈 Shown in Bar" : "󰈉 Hidden from Bar"
                font.bold: true; font.pixelSize: 16 
                color: pwrPopup.showInBar ? Theme.base : Theme.main
            }

            MouseArea {
                id: showInBarMouse
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: pwrPopup.toggleShowInBar()
            }
            Rectangle { 
                anchors.fill: parent; radius: height / 2; color: "#FFFFFF" 
                opacity: showInBarMouse.containsMouse ? 0.15 : 0 
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.secondaryBase }

        // --- LARGE STATUS HEADER ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            
            Text {
                id: hugeIcon
                Layout.alignment: Qt.AlignHCenter
                text: pwrPopup.pwrType === "DESKTOP" ? "󱐋" : (pwrPopup.isPluggedIn ? "󰂄" : "󰁹")
                color: Theme.main 
                font.pixelSize: 64
                opacity: 1.0
                
                SequentialAnimation {
                    running: pwrPopup.isPluggedIn
                    loops: Animation.Infinite
                    NumberAnimation { target: hugeIcon; property: "opacity"; to: 0.4; duration: 1200; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: hugeIcon; property: "opacity"; to: 1.0; duration: 1200; easing.type: Easing.InOutQuad }
                }
            }
            
            Text {
                visible: pwrPopup.pwrType === "BATTERY"
                Layout.alignment: Qt.AlignHCenter
                text: pwrPopup.pwrCapacity + "%"
                color: {
                    if (pwrPopup.pwrType === "BATTERY" && pwrPopup.pwrCapacity <= 20 && !pwrPopup.isPluggedIn) {
                        return Theme.secondaryBase; 
                    }
                    return Theme.text;
                }
                font.pixelSize: 32
                font.bold: true
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: pwrPopup.pwrType === "DESKTOP" ? "Connected to AC Power" : pwrPopup.pwrTimeStr
                color: Theme.inactive
                font.pixelSize: 14
                font.italic: true
            }
        }

        Item { Layout.fillHeight: true } // Pushes the controls perfectly to the bottom

        // --- POWER PROFILES ---
        Text { 
            text: "System Performance"
            color: Theme.text; font.bold: true; font.pixelSize: 15
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // 1. Power Saver Button
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 74; radius: 8
                
                property bool isActive: pwrPopup.activeProfile === "power-saver"
                color: isActive ? Theme.main : Theme.secondaryBase
                border.color: isActive ? "transparent" : Theme.bridge; border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
                
                Column { 
                    anchors.centerIn: parent; spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰌪"; color: parent.parent.isActive ? Theme.base : Theme.main; font.pixelSize: 24; Behavior on color { ColorAnimation { duration: 150 } } }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Power Saver"; color: parent.parent.isActive ? Theme.base : Theme.text; font.bold: true; font.pixelSize: 12; Behavior on color { ColorAnimation { duration: 150 } } }
                }
                
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pwrPopup.setProfile("power-saver") }
            }

            // 2. Balanced Button
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 74; radius: 8
                
                property bool isActive: pwrPopup.activeProfile === "balanced"
                color: isActive ? Theme.main : Theme.secondaryBase
                border.color: isActive ? "transparent" : Theme.bridge; border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
                
                Column { 
                    anchors.centerIn: parent; spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰾆"; color: parent.parent.isActive ? Theme.base : Theme.main; font.pixelSize: 24; Behavior on color { ColorAnimation { duration: 150 } } }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Balanced"; color: parent.parent.isActive ? Theme.base : Theme.text; font.bold: true; font.pixelSize: 12; Behavior on color { ColorAnimation { duration: 150 } } }
                }
                
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pwrPopup.setProfile("balanced") }
            }
            
            // 3. Performance Button
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 74; radius: 8
                
                property bool isActive: pwrPopup.activeProfile === "performance"
                color: isActive ? Theme.main : Theme.secondaryBase
                border.color: isActive ? "transparent" : Theme.bridge; border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
                
                Column { 
                    anchors.centerIn: parent; spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰓅"; color: parent.parent.isActive ? Theme.base : Theme.urgent; font.pixelSize: 24; Behavior on color { ColorAnimation { duration: 150 } } }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Performance"; color: parent.parent.isActive ? Theme.base : Theme.text; font.bold: true; font.pixelSize: 12; Behavior on color { ColorAnimation { duration: 150 } } }
                }
                
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pwrPopup.setProfile("performance") }
            }
        }
    }
}
