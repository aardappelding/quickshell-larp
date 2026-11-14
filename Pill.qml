import QtQuick
import QtQuick.Layouts
import QtQuick.Controls // Required for ToolTip

Rectangle {
    id: root
    property string icon: ""
    property string text: ""
    property color iconColor: Theme.primary
    property string tooltipText: "" // New property for hover text
    signal clicked()

    height: 36
    width: layout.implicitWidth + 24
    radius: height / 2
    color: Theme.surfaceContainer
    
    border.color: mouseArea.containsMouse ? Theme.primary : "transparent"
    border.width: 2

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        Text {
            visible: root.icon !== ""
            text: root.icon
            font.family: "Symbols Nerd Font"
            font.pointSize: 14
            color: root.iconColor
        }

        Text {
            visible: root.text !== ""
            text: root.text
            font.family: "Fira Code" 
            font.pointSize: 12
            color: Theme.onSurfaceColor
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true 
        onClicked: root.clicked()
    }

    // Themed Hover Tooltip
    ToolTip {
        visible: root.tooltipText !== "" && mouseArea.containsMouse
        delay: 300 // Slight delay prevents flashing when moving mouse quickly
        contentItem: Text {
            text: root.tooltipText
            color: Theme.onSurfaceColor
            font.family: "Fira Code"
        }
        background: Rectangle {
            color: Theme.surface
            border.color: Theme.surfaceContainer
            border.width: 2
            radius: 8
        }
    }
}
