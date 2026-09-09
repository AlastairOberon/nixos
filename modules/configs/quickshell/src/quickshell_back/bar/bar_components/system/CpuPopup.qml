import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 
import Quickshell
import "../" 

BlueprintPopup {
    id: cpuPopup
    
    // --- 1. CONFIGURE THE BLUEPRINT ---
    popupWidth: 460
    popupHeight: Math.min(800, 320 + Math.ceil(coreModel.length / 4) * 45)
    
    isTopBar: false
    timeoutDuration: 3000 
    
    // --- 2. DATA PROPERTIES ---
    property var parentController
    property var coreModel: [] 
    property int ramUsage: 0 
    property string cpuRam: "0M/0.0G" 
    property int totalCpuUsage: 0
    property int cpuTemp: 0
    property int gpuUsage: 0
    property int gpuTemp: 0
    property string gpuVram: "0M/0.0G"

    // ==========================================
    // --- 3. UI CONTENT ---
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        spacing: 15

        // ==========================================
        // --- DASHBOARD GAUGES ---
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 35 

            // --- RAM GAUGE ---
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                
                Text { 
                    text: "RAM"
                    color: Theme.text
                    font.pixelSize: 14
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter 
                }
                
                Item {
                    width: 70
                    height: 70
                    Layout.alignment: Qt.AlignHCenter
                    
                    property int pct: cpuPopup.ramUsage
                    property color gColor: pct >= 80 ? Theme.secondary : Theme.main
                    property real animVal: pct / 100.0
                    
                    Behavior on animVal { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                    onAnimValChanged: ramCanvas.requestPaint() 
                    
                    Canvas {
                        id: ramCanvas
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d"); 
                            ctx.clearRect(0, 0, width, height);
                            ctx.lineWidth = 6; 
                            ctx.lineCap = "round";
                            var x = width / 2; 
                            var y = height / 2; 
                            var r = width / 2 - 4;
                            
                            ctx.beginPath(); 
                            ctx.arc(x, y, r, 0, 2 * Math.PI); 
                            ctx.strokeStyle = Theme.secondaryBase.toString(); 
                            ctx.stroke();
                            
                            if (parent.animVal > 0) { 
                                ctx.beginPath(); 
                                ctx.arc(x, y, r, -Math.PI/2, -Math.PI/2 + (2 * Math.PI * parent.animVal)); 
                                ctx.strokeStyle = parent.gColor.toString(); 
                                ctx.stroke(); 
                            }
                        }
                    }
                    Text { 
                        anchors.centerIn: parent
                        text: parent.pct + "%"
                        color: Theme.text
                        font.pixelSize: 14
                        font.bold: true 
                    }
                }
                Text { 
                    text: cpuPopup.cpuRam
                    color: Theme.inactive
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter 
                }
                
                // Clear Cache Button
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                    width: 80
                    height: 24
                    radius: 12
                    color: clearMouse.containsMouse ? Theme.secondaryBase : "transparent"
                    border.color: Theme.bridge
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
                    Text { 
                        anchors.centerIn: parent
                        text: "Clear Cache"
                        color: Theme.inactive
                        font.pixelSize: 10
                        font.bold: true 
                    }
                    MouseArea { 
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parentController.dropRamCaches() 
                    }
                }
            }

            // --- CPU GAUGE ---
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop 
                spacing: 8
                
                Text { 
                    text: "CPU"
                    color: Theme.text
                    font.pixelSize: 14
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter 
                }
                
                Item {
                    width: 70
                    height: 70
                    Layout.alignment: Qt.AlignHCenter
                    
                    property int pct: cpuPopup.totalCpuUsage
                    property color gColor: pct >= 80 ? Theme.secondary : Theme.main
                    property real animVal: pct / 100.0
                    
                    Behavior on animVal { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                    onAnimValChanged: cpuCanvas.requestPaint()
                    
                    Canvas {
                        id: cpuCanvas
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d"); 
                            ctx.clearRect(0, 0, width, height);
                            ctx.lineWidth = 6; 
                            ctx.lineCap = "round";
                            var x = width / 2; 
                            var y = height / 2; 
                            var r = width / 2 - 4;
                            
                            ctx.beginPath(); 
                            ctx.arc(x, y, r, 0, 2 * Math.PI); 
                            ctx.strokeStyle = Theme.secondaryBase.toString(); 
                            ctx.stroke();
                            
                            if (parent.animVal > 0) { 
                                ctx.beginPath(); 
                                ctx.arc(x, y, r, -Math.PI/2, -Math.PI/2 + (2 * Math.PI * parent.animVal)); 
                                ctx.strokeStyle = parent.gColor.toString(); 
                                ctx.stroke(); 
                            }
                        }
                    }
                    Text { 
                        anchors.centerIn: parent
                        text: parent.pct + "%"
                        color: Theme.text
                        font.pixelSize: 14
                        font.bold: true 
                    }
                }
                Text { 
                    text: cpuPopup.cpuTemp + "°C"
                    color: cpuPopup.cpuTemp >= 80 ? Theme.secondary : Theme.inactive
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter 
                }
            }

            // --- GPU GAUGE ---
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                spacing: 8
                
                Text { 
                    text: "GPU"
                    color: Theme.text
                    font.pixelSize: 14
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter 
                }
                
                Item {
                    width: 70
                    height: 70
                    Layout.alignment: Qt.AlignHCenter
                    
                    property int pct: cpuPopup.gpuUsage
                    property color gColor: pct >= 80 ? Theme.secondary : Theme.main
                    property real animVal: pct / 100.0
                    
                    Behavior on animVal { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                    onAnimValChanged: gpuCanvas.requestPaint()
                    
                    Canvas {
                        id: gpuCanvas
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d"); 
                            ctx.clearRect(0, 0, width, height);
                            ctx.lineWidth = 6; 
                            ctx.lineCap = "round";
                            var x = width / 2; 
                            var y = height / 2; 
                            var r = width / 2 - 4;
                            
                            ctx.beginPath(); 
                            ctx.arc(x, y, r, 0, 2 * Math.PI); 
                            ctx.strokeStyle = Theme.secondaryBase.toString(); 
                            ctx.stroke();
                            
                            if (parent.animVal > 0) { 
                                ctx.beginPath(); 
                                ctx.arc(x, y, r, -Math.PI/2, -Math.PI/2 + (2 * Math.PI * parent.animVal)); 
                                ctx.strokeStyle = parent.gColor.toString(); 
                                ctx.stroke(); 
                            }
                        }
                    }
                    Text { 
                        anchors.centerIn: parent
                        text: parent.pct + "%"
                        color: Theme.text
                        font.pixelSize: 14
                        font.bold: true 
                    }
                }
                Text { 
                    text: cpuPopup.gpuTemp + "°C | " + cpuPopup.gpuVram
                    color: cpuPopup.gpuTemp >= 80 ? Theme.secondary : Theme.inactive
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter 
                }
            }
        }
        
        Rectangle { 
            Layout.fillWidth: true
            height: 2
            color: Theme.secondaryBase
            radius: 1 
        }

        // ==========================================
        // --- CPU CORES GRID ---
        // ==========================================
        Text { 
            text: "CPU Cores"
            color: Theme.text
            font.pixelSize: 14
            font.bold: true 
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            contentWidth: availableWidth

            GridLayout {
                width: parent.width
                columns: 4 
                columnSpacing: 15
                rowSpacing: 15

                Repeater {
                    model: cpuPopup.coreModel
                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        
                        RowLayout {
                            Layout.fillWidth: true
                            Text { 
                                text: modelData.name
                                color: Theme.inactive
                                font.pixelSize: 12
                                Layout.fillWidth: true 
                            }
                            Text { 
                                text: modelData.usage + "%"
                                color: Theme.inactive
                                font.pixelSize: 12
                                font.bold: true 
                            }
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: Theme.secondaryBase
                            
                            Rectangle {
                                width: Math.max(0, Math.min(parent.width, parent.width * modelData.rawUsage))
                                height: parent.height
                                radius: 3
                                color: modelData.usage >= 80 ? Theme.secondary : Theme.main
                                Behavior on color { ColorAnimation { duration: 300 } }
                                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }
            }
        }
    }
}
