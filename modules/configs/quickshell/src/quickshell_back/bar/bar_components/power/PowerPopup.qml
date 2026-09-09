 import QtQuick

import QtQuick.Layouts

import Quickshell

import Quickshell.Io

import Quickshell.Wayland 

import ".." 


PanelWindow {

    id: root

    visible: false

    color: "transparent"


    property var parentWindow: null

    screen: parentWindow ? parentWindow.screen : null


    anchors {

        top: true

        bottom: true

        left: true

        right: true

    }

    

    WlrLayershell.layer: WlrLayer.Overlay

    WlrLayershell.namespace: "power-menu" 

    exclusiveZone: -1 


    function toggle() {

        if (visible) {

            closeAnim.start();

        } else {

            visible = true;

            openAnim.start();

        }

    }


    function runPowerCommand(cmd) {

        // 1. INSTANT HIDE: Skip the fade-out animation so the menu doesn't get stuck 

        // when the compositor suspends rendering for sleep/lock!

        root.visible = false;

        backdrop.bgAlpha = 0.0;

        island.opacity = 0.0;


        // 2. RUN COMMAND: Reverted to standard execution. 

        // Since the menu is already hidden, we don't need dangerous shell hacks!

        execProcess.command = ["bash", "-c", cmd];

        execProcess.running = true;

    }


    Process { id: execProcess }


    // ==========================================

    // --- 1. THE BLURRED BACKDROP ---

    // ==========================================

    Rectangle {

        id: backdrop

        anchors.fill: parent

        

        property real bgAlpha: 0.0 

        color: Qt.rgba(0, 0, 0, bgAlpha) 


        MouseArea {

            anchors.fill: parent

            // Clicking the background still fades out smoothly

            onClicked: root.toggle()

        }

    }


    // ==========================================

    // --- 2. THE FLOATING ISLAND ---

    // ==========================================

    Rectangle {

        id: island

        width: contentRow.implicitWidth + 100

        height: contentRow.implicitHeight + 80

        anchors.centerIn: parent

        

        radius: 36

        color: Theme.base

        border.color: Theme.bridge

        border.width: 1

        

        opacity: 0.0


        MouseArea { anchors.fill: parent }


        RowLayout {

            id: contentRow

            anchors.centerIn: parent

            spacing: 40 


            Repeater {

                model: [

                    { name: "Lock", icon: "", color: Theme.secondary, cmd: "pidof hyprlock || hyprlock" },

                    { name: "Screen Off", icon: "󰤄", color: Theme.secondary, cmd: "sleep 1 && hyprctl dispatch \"hl.dsp.dpms({ action = 'disable' })\"" },

                    { name: "Log Out", icon: "󰍃", color: Theme.secondary, cmd: "hyprctl dispatch \"hl.dsp.exit()\"" },

                    { name: "Restart", icon: "", color: Theme.urgent, cmd: "systemctl reboot" },

                    { name: "Shut Down", icon: "", color: Theme.urgent, cmd: "systemctl poweroff" }

                ]


                delegate: Rectangle {

                    Layout.preferredWidth: 180

                    Layout.preferredHeight: 180

                    radius: 24

                    

                    color: btnMouse.containsMouse ? modelData.color : "transparent"

                    border.color: btnMouse.containsMouse ? modelData.color : Theme.bridge

                    border.width: 2


                    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuint } }

                    Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutQuint } }


                    ColumnLayout {

                        anchors.centerIn: parent

                        spacing: 16 


                        Text {

                            text: modelData.icon

                            Layout.alignment: Qt.AlignHCenter

                            color: btnMouse.containsMouse ? Theme.base : modelData.color

                            font.pixelSize: 64 

                            Behavior on color { ColorAnimation { duration: 150 } }

                        }


                        Text {

                            text: modelData.name

                            Layout.alignment: Qt.AlignHCenter

                            color: btnMouse.containsMouse ? Theme.base : Theme.text

                            font.pixelSize: 18 

                            font.bold: true

                            Behavior on color { ColorAnimation { duration: 150 } }

                        }

                    }


                    MouseArea {

                        id: btnMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        onClicked: root.runPowerCommand(modelData.cmd)

                    }

                }

            }

        }

    }


    // ==========================================

    // --- 3. CINEMATIC ANIMATIONS ---

    // ==========================================

    ParallelAnimation {

        id: openAnim

        NumberAnimation { target: backdrop; property: "bgAlpha"; from: 0.0; to: 0.4; duration: 250; easing.type: Easing.OutCubic }

        NumberAnimation { target: island; property: "opacity"; from: 0.0; to: 1.0; duration: 250; easing.type: Easing.OutCubic }

    }


    ParallelAnimation {

        id: closeAnim

        NumberAnimation { target: backdrop; property: "bgAlpha"; from: 0.4; to: 0.0; duration: 200; easing.type: Easing.InCubic }

        NumberAnimation { target: island; property: "opacity"; from: 1.0; to: 0.0; duration: 200; easing.type: Easing.InCubic }

        onFinished: root.visible = false

    }

} 
