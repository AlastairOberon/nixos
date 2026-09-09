pragma Singleton
import QtQuick

QtObject {
    // The global broadcast megaphone
    signal closeAllPopupsExcept(var exceptionPopup)
}
