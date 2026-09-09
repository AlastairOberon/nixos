import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire 
import "../" 

Row {
    id: audioContainer
    spacing: 8
    anchors.verticalCenter: parent.verticalCenter

    // ==========================================
    // 1. PIPEWIRE TRACKING
    // ==========================================
    property var activeSink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [ audioContainer.activeSink ] }

    property bool isMuted: activeSink?.audio?.muted ?? false
    property int volume: Math.round((activeSink?.audio?.volume ?? 0) * 100)
    
    // Safely combine name and description to accurately identify the hardware
    property string sinkString: activeSink ? (activeSink.name + " " + (activeSink.description || "")).toLowerCase() : ""
    
    // Check if it's wireless
    property bool isBluetooth: sinkString.includes("bluez") || sinkString.includes("bluetooth")
    
    // Catch headphones, headsets, and earbuds (both wired and bluetooth)
    property bool isHeadphone: sinkString.match(/headphone|headset|ear|buds/i) !== null

    property string currentIcon: {
        if (isMuted) return "󰖁";          
        
        // Show standard headphones if identified as such
        if (isHeadphone) return "󰋋";     
        
        // Default Speaker volume icons
        if (volume === 0) return "󰝟";
        if (volume < 30) return "󰕿";
        if (volume < 70) return "󰖀";
        return "󰕾";                        
    }

    // ==========================================
    // 2. SCROLL CONTROL (Non-blocking)
    // ==========================================
    WheelHandler {
        onWheel: (event) => {
            if (!activeSink?.audio) return;
            let newVol = volume;
            
            // Limit scroll maximum to 150% so you don't accidentally blow out your speakers
            if (event.angleDelta.y > 0) newVol = Math.min(150, volume + 5); 
            else if (event.angleDelta.y < 0) newVol = Math.max(0, volume - 5);   
            
            activeSink.audio.volume = newVol / 100.0;
            if (activeSink.audio.muted && newVol > 0) activeSink.audio.muted = false;
        }
    }

    // ==========================================
    // 3. UI EXPORT
    // ==========================================
    
    // Icon Group
    Row {
        spacing: 2
        anchors.verticalCenter: parent.verticalCenter

        // Main Icon (Speaker or Headphone)
        Text { 
            anchors.verticalCenter: parent.verticalCenter
            text: audioContainer.currentIcon
            color: audioContainer.isMuted ? Theme.urgent : Theme.main 
            font.pixelSize: 20 
            Behavior on color { ColorAnimation { duration: 300 } }
        }
        
        // Tiny Bluetooth Badge
        Text {
            visible: audioContainer.isBluetooth
            anchors.verticalCenter: parent.verticalCenter
            // Drops the icon down slightly so it anchors to the bottom-right of the main icon
            anchors.verticalCenterOffset: 4 
            text: "󰂯"
            color: Theme.secondary 
            font.pixelSize: 10
            font.bold: true
            Behavior on color { ColorAnimation { duration: 300 } }
        }
    }
    
    // Volume Percentage
    Text { 
        anchors.verticalCenter: parent.verticalCenter
        text: audioContainer.volume + "%"
        
        // Standard text color below 100%, secondary color for overdrive!
        color: audioContainer.isMuted ? Theme.inactive : (audioContainer.volume > 100 ? Theme.secondary : Theme.text) 
        
        font.pixelSize: 15
        font.bold: true
        
        width: 34 
        horizontalAlignment: Text.AlignRight 
        Behavior on color { ColorAnimation { duration: 300 } }
    }
}
