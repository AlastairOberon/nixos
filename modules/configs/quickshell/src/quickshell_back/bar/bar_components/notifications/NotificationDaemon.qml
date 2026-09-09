pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

NotificationServer {
    bodySupported: true
    imageSupported: true
    actionsSupported: true
    persistenceSupported: true

    // --- NEW: The Megaphone ---
    // This signal will broadcast the raw notification data to anyone listening
    signal showToast(var notif)

    onNotification: (notif) => {
        notif.tracked = true;
        
        // Trigger the megaphone!
        showToast(notif);
    }
}
