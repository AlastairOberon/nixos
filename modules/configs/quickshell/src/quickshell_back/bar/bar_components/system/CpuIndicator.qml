import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io 
import "../" 

Item {
    id: cpuContainer
    Layout.preferredWidth: cpuIndicator.implicitWidth
    Layout.fillHeight: true

    property var parentWindow 

    // --- SHARED DATA STATE ---
    property int totalCpuUsage: 0
    property int cpuTemp: 0
    property int ramUsage: 0
    property string cpuRam: "0M/0.0G" 
    property int gpuUsage: 0
    property int gpuTemp: 0
    property string gpuVram: "0M/0.0G" 
    property var coreData: [] 
    property var tempCoreData: [] 
    property var prevStats: ({}) 

    // --- EXECUTE ACTIONS ---
    Process { id: actionProc }
    
    function dropRamCaches() {
        actionProc.command = ["pkexec", "bash", "-c", "sync; echo 3 > /proc/sys/vm/drop_caches"];
        actionProc.running = true;
    }

    // --- CPU LOAD MATHER ---
    Process {
        id: cpuLoadFetch
        command: ["bash", "-c", "cat /proc/stat | grep '^cpu'"]
        stdout: SplitParser {
            onRead: function(data) {
                let parts = data.trim().split(/\s+/);
                if (parts.length < 5) return;
                let name = parts[0]; 
                
                let active = (parseInt(parts[1])||0) + (parseInt(parts[2])||0) + (parseInt(parts[3])||0) + (parseInt(parts[6])||0) + (parseInt(parts[7])||0);
                let total = active + (parseInt(parts[4])||0) + (parseInt(parts[5])||0);

                if (cpuContainer.prevStats[name]) {
                    let diffActive = active - cpuContainer.prevStats[name].active;
                    let diffTotal = total - cpuContainer.prevStats[name].total;
                    let usage = diffTotal > 0 ? (diffActive / diffTotal) * 100 : 0;

                    if (name === "cpu") {
                        cpuContainer.totalCpuUsage = Math.round(usage);
                    } else {
                        cpuContainer.tempCoreData.push({
                            name: name.replace("cpu", "Core "), 
                            usage: Math.round(usage),
                            rawUsage: usage / 100.0 
                        });
                    }
                }
                cpuContainer.prevStats[name] = { active: active, total: total };
            }
        }
        onExited: {
            if (cpuContainer.tempCoreData.length > 0) {
                cpuContainer.coreData = cpuContainer.tempCoreData;
                cpuContainer.tempCoreData = []; 
            }
        }
    }

    // --- CPU TEMP & RAM MATH ---
    Process {
        id: cpuHardwareFetch
        command: [
            "bash", "-c", 
            "H=$(dirname $(grep -l -E 'k10temp|zenpower|coretemp' /sys/class/hwmon/hwmon*/name 2>/dev/null | head -n 1) 2>/dev/null); " +
            "T=$(cat $H/temp1_input 2>/dev/null || cat $H/temp2_input 2>/dev/null || cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0); " +
            "R=$(free -m | awk '/^Mem:/ {print $3\",\"$2}'); " +
            "echo \"$T,$R\""
        ]
        stdout: SplitParser {
            onRead: function(data) {
                let parts = data.trim().split(',');
                if (parts.length >= 3) {
                    let temp = parseInt(parts[0]);
                    if (!isNaN(temp)) cpuContainer.cpuTemp = Math.round(temp / 1000);
                    
                    let usedM = parseInt(parts[1]);
                    let totalM = parseInt(parts[2]);
                    
                    if (totalM > 0) cpuContainer.ramUsage = Math.round((usedM / totalM) * 100);
                    
                    let usedStr = usedM < 1024 ? usedM + "M" : (usedM / 1024).toFixed(1) + "G";
                    let totalStr = (totalM / 1024).toFixed(1) + "G";
                    cpuContainer.cpuRam = usedStr + "/" + totalStr;
                }
            }
        }
    }

    // --- NVIDIA GPU DATA ---
    Process {
        id: gpuHardwareFetch
        command: ["bash", "-c", "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null || echo '0, 0, 0, 0'"]
        stdout: SplitParser {
            onRead: function(data) {
                let parts = data.trim().split(',');
                if (parts.length >= 4) {
                    cpuContainer.gpuUsage = parseInt(parts[0]);
                    cpuContainer.gpuTemp = parseInt(parts[1]);
                    
                    let usedM = parseInt(parts[2]);
                    let totalM = parseInt(parts[3]);
                    
                    let usedStr = usedM < 1024 ? usedM + "M" : (usedM / 1024).toFixed(1) + "G";
                    let totalStr = (totalM / 1024).toFixed(1) + "G";
                    cpuContainer.gpuVram = usedStr + "/" + totalStr;
                }
            }
        }
    }

    Timer {
        interval: 2000 
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuLoadFetch.running = true;
            cpuHardwareFetch.running = true;
            gpuHardwareFetch.running = true;
        }
    }

    // --- BAR INDICATOR ---
    RowLayout {
        id: cpuIndicator
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        
        // THE FIX: Tertiary on hover, Secondary on heavy load, Main otherwise!
        property color iconColor: cpuMouseArea.containsMouse ? Theme.text : 
                                  (cpuContainer.totalCpuUsage >= 80 ? Theme.secondary : Theme.main)
                                  
        Text { 
            text: ""
            color: cpuIndicator.iconColor
            font.pixelSize: 18
            Behavior on color { ColorAnimation { duration: 200 } } 
        }
    }

    MouseArea { 
        id: cpuMouseArea
        anchors.fill: parent
        hoverEnabled: true 
        cursorShape: Qt.PointingHandCursor
        onClicked: cpuPopup.toggle() 
    }

    // --- POPUP MENU ---
    CpuPopup {
        id: cpuPopup
        parentWindow: cpuContainer.parentWindow 
        anchorTarget: cpuContainer
        
        parentController: cpuContainer
        coreModel: cpuContainer.coreData
        ramUsage: cpuContainer.ramUsage
        cpuRam: cpuContainer.cpuRam 
        totalCpuUsage: cpuContainer.totalCpuUsage
        cpuTemp: cpuContainer.cpuTemp
        gpuUsage: cpuContainer.gpuUsage
        gpuTemp: cpuContainer.gpuTemp
        gpuVram: cpuContainer.gpuVram
    }
}
