import QtQuick
import QtQuick.Layouts
import Quickshell
import ".." // Imports BlueprintPopup and Theme from bar_components
import "./calendar_components" // Imports your header/body/footer components

BlueprintPopup {
    id: root

    // --- LINK TO BLUEPRINT ---
    // These aliases allow Clock.qml to pass data directly into the Blueprint
    property alias parentWindow: root.parentWindow
    property alias anchorTarget: root.anchorTarget

    // --- 1. CONFIGURE THE BLUEPRINT ---
    // Width set to 300 to clip the 6th row bleed-over
    popupWidth: 300 
    popupHeight: 380 
    isTopBar: true
    //barOverlap: 0
    //timeoutDuration: 5000
    edgeOffset: 15 

    // --- 2. DATA PROPERTIES ---
    property int currentYear: new Date().getFullYear()
    property int currentMonth: new Date().getMonth()
    property bool selectingYear: false
    property bool selectingMonth: false

    onAboutToOpen: {
        currentYear = new Date().getFullYear();
        currentMonth = new Date().getMonth();
        selectingYear = false;
        selectingMonth = false;
    }

    // ==========================================
    // --- 3. UI CONTENT ---
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        spacing: 10 

        YearHeader {
            currentYear: root.currentYear
            isActive: root.selectingYear
            onPrevClicked: body.shiftYear("prev")
            onNextClicked: body.shiftYear("next")
            onHeaderClicked: {
                root.selectingYear = !root.selectingYear;
                root.selectingMonth = false;
            }
        }

        CalendarBody {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            currentYear: root.currentYear
            currentMonth: root.currentMonth
            selectingYear: root.selectingYear
            selectingMonth: root.selectingMonth
            
            onUpdateState: (year, month) => {
                root.currentYear = year;
                root.currentMonth = month;
            }
            onCloseYearSelect: root.selectingYear = false
            onCloseMonthSelect: root.selectingMonth = false
        }

        MonthFooter {
            currentYear: root.currentYear
            currentMonth: root.currentMonth
            isActive: root.selectingMonth
            onPrevClicked: body.shiftMonth("prev")
            onNextClicked: body.shiftMonth("next")
            onFooterClicked: {
                root.selectingMonth = !root.selectingMonth;
                root.selectingYear = false;
            }
        }
    } 
}
