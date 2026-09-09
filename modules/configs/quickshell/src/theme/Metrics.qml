pragma Singleton
import QtQuick

QtObject {
    // Rounding & Border
    property int radiusBase     : 12
    property int radiusLarge    : 25
    property int borderWidth    : 2

    // Spacing
    property int spacingSmall   : 5
    property int spacingBase    : 15
    property int spacingLarge   : 20

    // Animation Duration
    property int animFast       : 150
    property int animBase       : 250
    property int animSlow       : 400
}
