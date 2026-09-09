import QtQuick
import Quickshell
import Quickshell.Hyprland 
import "." 

PopupWindow {
    id: root
    visible: false
    color: "transparent"

    // ==========================================
    // THE WAYLAND KEYBOARD FIX
    // By using HyprlandFocusGrab exclusively, we get full keyboard control 
    // WITHOUT Hyprland forcing its own coordinate offsets!
    // ==========================================
    HyprlandFocusGrab {
        id: hGrab
        active: root.visible
        windows: [ root ]
        // Emits when clicking outside the window, acting as a perfect auto-close!
        onCleared: root.closeSilently() 
    }

    // ==========================================
    // --- 1. GLOBAL CONTROLS (Your Style API) ---
    // ==========================================
    property int popupWidth: 300
    property int popupHeight: 400
    property bool isTopBar: true 
    property int timeoutDuration: 5000 
    property int borderRadius: 15
    property int barOverlap: -20 
    property real popupScale: 1.0
    property real bgOpacity: 0.7

    property var parentWindow: null
    property var anchorTarget: null
    property int edgeOffset: 0
    property bool isSubMenu: false
    
    implicitWidth: popupWidth
    implicitHeight: popupHeight

    // ==========================================
    // --- 2. DYNAMIC WAYLAND ANCHORING ---
    // ==========================================
    
    // A fully reactive binding! 
    property real absoluteTargetX: anchorTarget ? (anchorTarget.x + (anchorTarget.parent ? anchorTarget.parent.x : 0)) : 0

    anchor {
        window: parentWindow || null
        rect.x: anchorTarget ? (absoluteTargetX - (implicitWidth / 2) + (anchorTarget.width / 2) + edgeOffset) : edgeOffset
        rect.y: isTopBar ? (parentWindow ? parentWindow.height - barOverlap : -barOverlap) 
                         : (-implicitHeight + barOverlap)
    }

    signal aboutToOpen()
    signal aboutToClose()

    // ==========================================
    // --- 3. UNIVERSAL TIMERS & LOGIC ---
    // ==========================================
    Timer {
        id: autoCloseTimer
        interval: root.timeoutDuration
        running: false; repeat: false
        onTriggered: if (root.visible) root.toggle()
    }

    Connections {
        target: PopupManager
        function onCloseAllPopupsExcept(exceptionPopup) {
            if (root.visible && root !== exceptionPopup) {
                root.closeSilently();
            }
        }
    }

    function toggle() {
        if (!visible) {
            if (!root.isSubMenu) {
                PopupManager.closeAllPopupsExcept(root); 
            }
            
            aboutToOpen();
            visible = true;
            openAnimation.start();
            if (timeoutDuration > 0) autoCloseTimer.restart();
        } else {
            closeSilently();
        }
    }

    function closeSilently() {
        if (visible) {
            aboutToClose();
            closeAnimation.start();
            autoCloseTimer.stop();
        }
    }

    default property alias content: container.data

    // ==========================================
    // --- 4. THE SHAPE & ANIMATION ENGINE ---
    // ==========================================
    Item {
        id: internalMenu
        width: parent.width
        height: parent.height
        
        transformOrigin: root.isTopBar ? Item.Top : Item.Bottom
        
        scale: root.popupScale - 0.1
        opacity: 0.0

        // --- ZOOM & FADE IN ---
        ParallelAnimation {
            id: openAnimation
            NumberAnimation { 
                target: internalMenu; 
                property: "scale"; 
                from: root.popupScale - 0.1; 
                to: root.popupScale; 
                duration: 300; 
                easing.type: Easing.OutQuint 
            }
            NumberAnimation { 
                target: internalMenu; property: "opacity"; from: 0.0; to: 1.0; 
                duration: 250; easing.type: Easing.OutCubic 
            }
        }

        // --- ZOOM & FADE OUT ---
        ParallelAnimation {
            id: closeAnimation
            NumberAnimation { 
                target: internalMenu; 
                property: "scale"; 
                from: root.popupScale; 
                to: root.popupScale - 0.1; 
                duration: 250; 
                easing.type: Easing.InQuint 
            }
            NumberAnimation { 
                target: internalMenu; property: "opacity"; from: 1.0; to: 0.0; 
                duration: 200; easing.type: Easing.InCubic 
            }
            onFinished: root.visible = false
        }

        // UNIVERSAL BODY
        Rectangle {
            anchors.fill: parent
            color: Theme.base
            
            opacity: root.bgOpacity 
            
            border.color: Theme.bridge 
            border.width: 1
            radius: root.borderRadius
        }

        // CONTENT INJECTOR
        Item {
            id: container
            anchors.fill: parent
            anchors.margins: 20

            HoverHandler {
                onHoveredChanged: hovered ? autoCloseTimer.stop() : (root.timeoutDuration > 0 && root.visible ? autoCloseTimer.restart() : null)
            }
        }
    }
}
