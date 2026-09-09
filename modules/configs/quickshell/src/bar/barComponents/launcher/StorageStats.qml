import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io 

import "../../../theme" 
import "../../../theme/components" 

Item {
    id: storageRoot
    
    property var diskDatabase: []
    property var categoryDatabase: []
    property var backupDatabase: []
    
    property real rootTotalSize: 1 
    property real rootUsedSize: 0
    
    property bool breakdownLoading: true

    // ==========================================
    // UTILITIES
    // ==========================================
    function formatBytes(bytes) {
        if (bytes === 0) return "0 B";
        const k = 1024;
        const sizes = ["B", "KB", "MB", "GB", "TB"];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i];
    }

    // Creative, distinct colors for the pie chart slices
    property var catColors: [
        Theme.main, 
        Theme.secondary, 
        Theme.urgent, 
        Qt.lighter(Theme.main, 1.5),
        Qt.lighter(Theme.secondary, 1.5)
    ]

    // ==========================================
    // SHELL PROCESSES
    // ==========================================
    Process {
        id: fetchDisks
        command: [
            "sh", "-c", 
            "df -B1 -T -x tmpfs -x devtmpfs -x squashfs -x efivarfs | awk 'NR>1 { printf \"{\\\"mount\\\":\\\"%s\\\",\\\"type\\\":\\\"%s\\\",\\\"total\\\":%s,\\\"used\\\":%s,\\\"avail\\\":%s,\\\"pct\\\":\\\"%s\\\"},\", $7, $2, $3, $4, $5, $6 }' | sed 's/,$//' | awk '{print \"[\" $0 \"]\"}'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text.trim() === "") return;
                    storageRoot.diskDatabase = JSON.parse(this.text);
                } catch (e) {
                    console.log("Disk JSON Parse Error: " + e.message);
                }
            }
        }
    }

    Process {
        id: fetchCategories
        command: [
            "bash", "-c",
            `
            sz() { du -csb "$@" 2>/dev/null | tail -1 | awk '{print $1+0}'; }
            
            # Fetch Root Total and Used
            root_info=($(df -B1 / | awk 'NR==2 {print $2, $3}'))
            root_total=\${root_info[0]}
            root_used=\${root_info[1]}
            
            games=$(sz ~/.local/share/Steam ~/.steam ~/.var/app/com.valvesoftware.Steam ~/.local/share/lutris)
            cache=$(sz ~/.cache)
            apps=$(sz ~/.local/share ~/.config ~/.var/app /var/lib/flatpak)
            
            apps=$((apps - games))
            if [ "$apps" -lt 0 ]; then apps=0; fi
            
            media=$(sz ~/Videos ~/Music ~/Pictures ~/Documents ~/Downloads)
            
            printf "{\\\"rootTotal\\\":%s,\\\"rootUsed\\\":%s,\\\"categories\\\":[{\\\"name\\\":\\\"Games\\\",\\\"size\\\":%s},{\\\"name\\\":\\\"System Cache\\\",\\\"size\\\":%s},{\\\"name\\\":\\\"App Data & Flatpaks\\\",\\\"size\\\":%s},{\\\"name\\\":\\\"Personal Media\\\",\\\"size\\\":%s}]}" "$root_total" "$root_used" "$games" "$cache" "$apps" "$media"
            `
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text.trim() === "") return;
                    let parsed = JSON.parse(this.text);
                    
                    storageRoot.rootTotalSize = parsed.rootTotal || 1;
                    storageRoot.rootUsedSize = parsed.rootUsed || 0;
                    
                    let totalUser = 0;
                    let activeCats = [];
                    let colorIndex = 0;
                    
                    // Populate User Categories
                    for (let i = 0; i < parsed.categories.length; i++) {
                        let cat = parsed.categories[i];
                        if (cat.size > 0) {
                            totalUser += cat.size;
                            cat.color = storageRoot.catColors[colorIndex % storageRoot.catColors.length];
                            activeCats.push(cat);
                            colorIndex++;
                        }
                    }
                    
                    // Calculate Remaining System Size (Root Used - User Data)
                    let systemSize = storageRoot.rootUsedSize - totalUser;
                    if (systemSize > 0) {
                        activeCats.push({
                            name: "System & Other",
                            size: systemSize,
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.25) // Frosted glass look, distinct from 'inactive'
                        });
                    }
                    
                    storageRoot.categoryDatabase = activeCats;
                    storageRoot.breakdownLoading = false;
                    
                    if (pieChartCanvas) pieChartCanvas.requestPaint();
                } catch (e) {
                    console.log("Category JSON Parse Error: " + e.message);
                    storageRoot.breakdownLoading = false;
                }
            }
        }
    }

    Process {
        id: fetchBackups
        command: [
            "bash", "-c",
            `
            sz() { [ -d "$1" ] && du -csb "$1" 2>/dev/null | tail -1 | awk '{print $1+0}' || echo 0; }
            nix=$(sz /nix/store)
            snapper=$(sz /.snapshots)
            timeshift=$(sz /timeshift)
            printf "[{\\\"name\\\":\\\"Nix Generations\\\",\\\"size\\\":%s,\\\"icon\\\":\\\"\uf187\\\"},{\\\"name\\\":\\\"BTRFS Snapshots\\\",\\\"size\\\":%s,\\\"icon\\\":\\\"\uf0c5\\\"},{\\\"name\\\":\\\"Timeshift Backups\\\",\\\"size\\\":%s,\\\"icon\\\":\\\"\uf017\\\"}]" "$nix" "$snapper" "$timeshift"
            `
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text.trim() === "") return;
                    let parsed = JSON.parse(this.text);
                    storageRoot.backupDatabase = parsed.filter(b => b.size > 0);
                } catch (e) {
                    console.log("Backups JSON Parse Error: " + e.message);
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            breakdownLoading = true;
            fetchDisks.running = true;
            fetchCategories.running = true;
            fetchBackups.running = true;
        }
    }

    // ==========================================
    // UI LAYOUT
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        spacing: Metrics.spacingLarge
        anchors.topMargin: Metrics.spacingLarge
        anchors.bottomMargin: Metrics.spacingLarge

        // --- HEADER ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Metrics.spacingLarge
            Layout.rightMargin: Metrics.spacingLarge
            spacing: 8

            Text {
                text: "Storage & Devices"
                color: Theme.main
                font.family: Theme.fontMain
                font.pixelSize: 18
                font.weight: Font.Bold
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentLayout.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height 
            
            ColumnLayout {
                id: contentLayout
                width: parent.width - (Metrics.spacingLarge * 2)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Metrics.spacingLarge

                // ==========================================
                // SECTION 1: CIRCULAR BREAKDOWN CHART (ROOT)
                // ==========================================
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180 
                    
                    Text {
                        visible: storageRoot.breakdownLoading
                        text: "⏳ Scanning Root Partition..."
                        color: Theme.secondary
                        anchors.centerIn: parent
                        font.family: Theme.fontMain
                        font.pixelSize: 16
                    }
                    
                    RowLayout {
                        visible: !storageRoot.breakdownLoading
                        anchors.fill: parent
                        spacing: Metrics.spacingLarge

                        // 1. The Donut Chart
                        Item {
                            Layout.preferredWidth: 140
                            Layout.preferredHeight: 140
                            Layout.alignment: Qt.AlignVCenter
                            
                            Canvas {
                                id: pieChartCanvas
                                anchors.fill: parent
                                
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);
                                    
                                    let centerX = width / 2;
                                    let centerY = height / 2;
                                    let radius = (width / 2) - 12; 
                                    
                                    // Base empty track (represents Total Storage capacity - UNUSED SPACE)
                                    ctx.beginPath();
                                    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                                    ctx.lineWidth = 16;
                                    ctx.strokeStyle = Theme.inactive.toString(); 
                                    ctx.stroke();
                                    
                                    if (storageRoot.categoryDatabase.length === 0) return;
                                    
                                    let currentAngle = -Math.PI / 2; // Start at 12 o'clock
                                    
                                    for (let i = 0; i < storageRoot.categoryDatabase.length; i++) {
                                        let cat = storageRoot.categoryDatabase[i];
                                        // Calculates the slice relative to the ENTIRE partition size
                                        let sliceAngle = (cat.size / storageRoot.rootTotalSize) * 2 * Math.PI;
                                        
                                        ctx.beginPath();
                                        ctx.arc(centerX, centerY, radius, currentAngle, currentAngle + sliceAngle);
                                        ctx.lineWidth = 16; 
                                        ctx.strokeStyle = cat.color.toString();
                                        ctx.stroke();
                                        
                                        currentAngle += sliceAngle;
                                    }
                                }
                            }
                            
                            // Center Text (Usage Ratio)
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    text: storageRoot.formatBytes(storageRoot.rootUsedSize)
                                    color: Theme.main
                                    font.family: Theme.fontMain
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: "Root Partition"
                                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                                    font.family: Theme.fontMain
                                    font.pixelSize: 12
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }

                        // 2. The Legend
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 12
                            
                            Repeater {
                                model: storageRoot.categoryDatabase
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    
                                    Rectangle {
                                        width: 14; height: 14; radius: 7
                                        color: modelData.color
                                    }
                                    Text {
                                        text: modelData.name
                                        color: Theme.text
                                        font.family: Theme.fontMain
                                        font.pixelSize: 16
                                        font.weight: Font.Medium
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: storageRoot.formatBytes(modelData.size)
                                        color: Qt.lighter(Theme.text, 1.2)
                                        font.family: Theme.fontMain
                                        font.pixelSize: 14
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.bridge; opacity: 0.4 }

                // ==========================================
                // SECTION 2: SYSTEM BACKUPS & SNAPSHOTS
                // ==========================================
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Metrics.spacingLarge
                    visible: storageRoot.backupDatabase.length > 0 
                    
                    Text {
                        text: "System Backups & Snapshots"
                        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                        font.family: Theme.fontMain
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                    Repeater {
                        model: storageRoot.backupDatabase
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Metrics.spacingLarge

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40 
                                
                                RowLayout {
                                    anchors.fill: parent
                                    spacing: Metrics.spacingLarge
                                    
                                    Text {
                                        text: modelData.icon
                                        color: Theme.urgent
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 22
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        
                                        Text {
                                            text: modelData.name
                                            color: Theme.text
                                            font.family: Theme.fontMain
                                            font.pixelSize: 16
                                            font.weight: Font.Medium
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                        
                                        Text {
                                            text: storageRoot.formatBytes(modelData.size)
                                            color: Qt.lighter(Theme.text, 1.2)
                                            font.family: Theme.fontMain
                                            font.pixelSize: 14
                                        }
                                    }
                                }
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: Theme.bridge
                                opacity: 0.4
                            }
                        }
                    }
                }

                // ==========================================
                // SECTION 3: MOUNTED DRIVES
                // ==========================================
                Text {
                    text: "Mounted Drives & Partitions"
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                    font.family: Theme.fontMain
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    Layout.topMargin: storageRoot.backupDatabase.length > 0 ? 0 : Metrics.spacingBase
                }

                Repeater {
                    model: storageRoot.diskDatabase
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Metrics.spacingLarge

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 60 
                            
                            RowLayout {
                                anchors.fill: parent
                                spacing: Metrics.spacingLarge
                                
                                Text {
                                    text: modelData.mount === "/" ? "\uf2db" : "\uf0a0"
                                    color: Theme.secondary
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 26
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 6

                                    RowLayout {
                                        Layout.fillWidth: true
                                        
                                        Text {
                                            text: modelData.mount
                                            color: Theme.text
                                            font.family: Theme.fontMain
                                            font.pixelSize: 16
                                            font.weight: Font.Medium
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                        
                                        Text {
                                            text: storageRoot.formatBytes(modelData.used) + " / " + storageRoot.formatBytes(modelData.total)
                                            color: Qt.lighter(Theme.text, 1.2)
                                            font.family: Theme.fontMain
                                            font.pixelSize: 14
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 6
                                        radius: 3
                                        color: Qt.rgba(1, 1, 1, 0.15) 
                                        clip: true
                                        
                                        Rectangle {
                                            height: parent.height
                                            width: (modelData.used / modelData.total) * parent.width
                                            color: (modelData.used / modelData.total) > 0.9 ? Theme.urgent : Theme.main
                                            radius: 3
                                        }
                                    }
                                }
                            }
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Theme.bridge
                            opacity: 0.4
                        }
                    }
                }
            }
        }
    }
}
