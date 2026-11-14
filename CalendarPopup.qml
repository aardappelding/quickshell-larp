import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

PopupWindow {
    id: root
    width: 300
    height: 320
    
    anchor.window: topBar
    anchor.rect.x: topBar.width / 2 - width / 2
    anchor.rect.y: topBar.height
    visible: false
    color: "transparent"

    Rectangle {
        anchors.fill: parent // Replaces manual width/height here
        radius: 16
        color: Theme.surface
        border.color: Theme.surfaceContainer
        border.width: 2

        // Standard QtQuick Calendar component can be embedded here
        // or a custom grid layout reading `cal -m`
        Text {
            anchors.centerIn: parent
            text: "Calendar Widget Placeholder"
            color: Theme.onSurfaceColor
        }
    }
}
