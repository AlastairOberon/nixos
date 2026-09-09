import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // THE FIX: Tells Clock.qml where to find the Blueprint properties!

MouseArea {
    id: clockContainer
    Layout.preferredWidth: contentLayout.implicitWidth
    Layout.fillHeight: true

    // !!! THIS IS THE MISSING CATCHER !!!
    property var parentWindow

    // Click to toggle the sliding dropdown panel
    onClicked: calendarModule.toggle()

    RowLayout {
        id: contentLayout
        anchors.right: parent.right 
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        // The Time Display
        Text {
            id: timeDisplay
            color: Theme.main // (Optional) You can theme this too!
            font.pixelSize: 16
            font.bold: true
            
            function updateTime() {
                text = new Date().toLocaleString(Qt.locale(), "HH:mm:ss");
            }

            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: timeDisplay.updateTime()
            }
            Component.onCompleted: updateTime()
        }
    }

    // Call your newly renamed CalendarPopup wrapper
    CalendarPopup {
        id: calendarModule
        parentWindow: clockContainer.parentWindow           // Passes down the PanelWindow reference
        anchorTarget: clockContainer // Tells the calendar to align itself right under this clock
    }
}
