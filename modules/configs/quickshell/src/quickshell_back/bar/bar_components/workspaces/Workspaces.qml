import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../" 

RowLayout {
    spacing: 15

    property int highestActive: {
        let _focus = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0;
        let _wsCount = Hyprland.workspaces ? Hyprland.workspaces.count : 0;
        
        let max = 1;

        if (Hyprland.workspaces && Hyprland.workspaces.values) {
            for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
                let ws = Hyprland.workspaces.values[i];
                if (ws.id > max) {
                    max = ws.id;
                }
            }
        }
        
        if (_focus > max) {
            max = _focus;
        }

        return max;
    }

    Repeater {
        model: parent.highestActive + 1

        Item {
            id: wsContainer
            width: 32 
            height: 32

            property var worksp: Hyprland.workspaces.values.find(w => w.id === index + 1)
            property bool act_worksp: Hyprland.focusedWorkspace?.id === (index + 1)
            property var allToplevels: Hyprland.toplevels.values

            property int winCount: {
                let count = 0;
                if (allToplevels) {
                    for (let i = 0; i < allToplevels.length; i++) {
                        let toplevel = allToplevels[i];
                        if (toplevel.workspace && toplevel.workspace.id === (index + 1)) {
                            count++;
                        }
                    }
                }
                return count;
            }

            property int displayCount: Math.min(winCount, 30)

            onAct_workspChanged: {
                if (act_worksp) {
                    returnAnim.stop()
                    spinAnim.from = dotGroup.rotation
                    spinAnim.to = dotGroup.rotation + 360
                    spinAnim.start()
                } else {
                    spinAnim.stop()
                    dotGroup.rotation = dotGroup.rotation % 360
                    returnAnim.start()
                }
            }

            Text {
                anchors.centerIn: parent
                text: "◦"
                color: act_worksp ? Theme.main : (wsContainer.worksp ? Theme.text : Theme.inactive)
                font { pixelSize: 30; bold: true }
                
                opacity: wsContainer.winCount === 0 ? 1 : 0
                scale: wsContainer.winCount === 0 ? 1 : 0.5
                
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
            }

            Item {
                id: dotGroup
                anchors.fill: parent

                RotationAnimation {
                    id: spinAnim
                    target: dotGroup
                    property: "rotation"
                    duration: 3000 
                    loops: Animation.Infinite
                    direction: RotationAnimation.Clockwise
                }

                RotationAnimation {
                    id: returnAnim
                    target: dotGroup
                    property: "rotation"
                    to: 0
                    duration: 1500 
                    direction: RotationAnimation.Shortest 
                    easing.type: Easing.OutQuart 
                }

                Repeater {
                    model: 30 

                    Text {
                        text: "•"
                        color: act_worksp ? Theme.main : (wsContainer.worksp ? Theme.text : Theme.inactive)
                        
                        property real dotSize: {
                            if (wsContainer.displayCount <= 1) return 30;
                            if (wsContainer.displayCount >= 20) return 10;
                            return 30 - ((wsContainer.displayCount - 1) * (20.0 / 19.0));
                        }
                        
                        Behavior on dotSize { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        font { pixelSize: Math.round(dotSize); bold: true }
                        
                        property bool isActive: index < wsContainer.displayCount
                        
                        opacity: isActive ? 1 : 0
                        scale: isActive ? 1 : 0.2
                        
                        property real angle: wsContainer.displayCount > 0 
                            ? (Math.PI * 2 / wsContainer.displayCount) * index - (Math.PI / 2) 
                            : 0
                            
                        property real radius: {
                            if (wsContainer.displayCount <= 1) return 0;
                            if (wsContainer.displayCount >= 20) return 11;
                            return 8 + ((wsContainer.displayCount - 2) * (3.0 / 18.0));
                        }

                        x: (wsContainer.width / 2) - (contentWidth / 2) + (Math.cos(angle) * radius)
                        y: (wsContainer.height / 2) - (contentHeight / 2) + (Math.sin(angle) * radius)
                        
                        Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        
                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (index + 1) + " })")
            }
        }
    }
}
