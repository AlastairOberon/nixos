import QtQuick
import QtQuick.Layouts
import QtCore 
import Quickshell
import Quickshell.Wayland 
import ".." 
import "SharedState.js" as GlobalState

PanelWindow {
    id: root
    visible: false
    color: "transparent"

    property var parentWindow
    
    // --- THE GAP FIX ---
    // Tweak this negative number to pull the clipping mask up through your bar's shadow/padding!
    property int gapAdjust: -20 
    
    screen: parentWindow ? parentWindow.screen : null

    anchors {
        top: true 
    }
    
    margins {
        // Calculates the bar height, then applies your manual adjustment
        top: (parentWindow ? parentWindow.height : 0) + gapAdjust
    }

    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay 

    // THE FIX: Using implicit sizing for Wayland windows to remove the deprecation warning
    implicitWidth: 350
    implicitHeight: clipper.implicitHeight

    property var currentNotif: null

    // --- LOGIC ---
    Timer {
        id: hideTimer
        interval: 3000 
        onTriggered: closeAnim.start()
    }

    Connections {
        target: NotificationDaemon
        function onShowToast(notif) {
            if (GlobalState.isMuted) return;

            root.currentNotif = notif;
            root.visible = true;
            openAnim.start();
            hideTimer.restart();
        }
    }

    // --- THE CLIPPING MASK ---
    Item {
        id: clipper
        width: parent.width
        implicitHeight: toastContainer.implicitHeight
        clip: true 

        // --- THE ANIMATION WRAPPER ---
        Item {
            id: toastContainer
            width: parent.width
            implicitHeight: card.height
            
            y: -height

            ParallelAnimation {
                id: openAnim
                NumberAnimation { 
                    target: toastContainer; 
                    property: "y"; 
                    from: -toastContainer.height; 
                    to: 0; 
                    duration: 350; 
                    easing.type: Easing.OutQuint 
                }
            }

            ParallelAnimation {
                id: closeAnim
                NumberAnimation { 
                    target: toastContainer; 
                    property: "y"; 
                    from: 0; 
                    to: -toastContainer.height; 
                    duration: 300; 
                    easing.type: Easing.InQuint 
                }
                onFinished: {
                    root.visible = false;
                    root.currentNotif = null;
                }
            }

            // --- UI CONTENT ---
            Rectangle {
                id: card
                width: parent.width
                height: content.implicitHeight + 20
                
                // Optional: You can set the top-left/top-right radius to 0 if you want it completely flush with the bar
                radius: 8 
                color: Theme.base
                
                visible: root.currentNotif !== null

                ColumnLayout {
                    id: content
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    // Top Row
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: root.currentNotif ? (root.currentNotif.appName || "System") : ""
                            color: Theme.secondary
                            font.pixelSize: 11
                            font.bold: true
                        }
                        
                        MouseArea {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            hoverEnabled: true
                            onEntered: hideTimer.stop()
                            onExited: hideTimer.restart()
                            onClicked: closeAnim.start()
                            
                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: parent.containsMouse ? Theme.urgent : Theme.inactive
                                font.pixelSize: 14
                            }
                        }
                    }

                    // Body Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Layout.alignment: Qt.AlignTop

                        Image {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            Layout.alignment: Qt.AlignTop
                            cache: false 
                            
                            source: {
                                if (!root.currentNotif) return "";
                                
                                let img = root.currentNotif.image ? root.currentNotif.image.toString() : "";
                                let icon = root.currentNotif.appIcon ? root.currentNotif.appIcon.toString() : "";
                                let path = img !== "" ? img : icon;
                                
                                if (path === "") return "";

                                try {
                                    let homeUri = StandardPaths.standardLocations(StandardPaths.HomeLocation)[0];

                                    if (path.startsWith("image://icon/")) {
                                        path = path.substring(13); 
                                    }

                                    if (path.includes("/") && (path.endsWith(".png") || path.endsWith(".jpg"))) {
                                        if (!path.startsWith("/") && !path.startsWith("file://") && !path.startsWith("~/")) {
                                            return homeUri + "/" + path;
                                        }
                                    }

                                    if (path.startsWith("~/")) {
                                        return homeUri + "/" + path.substring(2);
                                    }

                                    if (path.startsWith("/")) {
                                        return "file://" + path;
                                    }

                                    if (path.includes("://")) {
                                        return path;
                                    }

                                    let resolved = Quickshell.iconPath(path);
                                    if (resolved && (resolved.includes("checkerboard") || resolved.includes("missing"))) {
                                        return "";
                                    }
                                    
                                    return resolved;
                                    
                                } catch (e) {
                                    return "";
                                }
                            }
                            
                            visible: source.toString() !== "" && status !== Image.Error
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                text: root.currentNotif ? root.currentNotif.summary : ""
                                color: Theme.secondary
                                font.pixelSize: 13
                                font.bold: true
                                wrapMode: Text.Wrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.currentNotif ? root.currentNotif.body : ""
                                visible: text !== ""
                                color: Theme.text
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }
        }
    }
}
