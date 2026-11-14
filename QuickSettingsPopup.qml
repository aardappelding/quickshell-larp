import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PopupWindow {
    id: root
    width: 380; height: 420
    anchor.window: topBar
    anchor.rect.x: topBar.width - width - 20
    anchor.rect.y: topBar.height
    visible: false
    color: "transparent"

    // --- Write-Only Setter Processes ---
    Process { id: toggleWifi; command: ["sh", "-c", "nmcli radio wifi | grep -q 'enabled' && nmcli radio wifi off || nmcli radio wifi on"] }
    Process { id: openWifi; command: ["nm-connection-editor"] }
    Process { id: toggleBt; command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && bluetoothctl power off || bluetoothctl power on"] }
    Process { id: openBt; command: ["blueman-manager"] }
    Process { id: cmdSleep; command: ["loginctl", "suspend"] }
    Process { id: cmdReboot; command: ["loginctl", "reboot"] }
    Process { id: cmdPoweroff; command: ["loginctl", "poweroff"] }
    Process { id: setVol }
    Process { id: setBri }

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Theme.surface
        border.color: Theme.surfaceContainer
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // Network & Bluetooth Row
            RowLayout {
                spacing: 15; Layout.fillWidth: true

                Rectangle {
                    Layout.fillWidth: true; height: 60; radius: 12
                    color: topBar.isWifiOn ? Theme.primary : Theme.surfaceContainer
                    Text { anchors.centerIn: parent; text: "  Wi-Fi"; font.bold: true; color: topBar.isWifiOn ? Theme.onPrimaryColor : Theme.onSurfaceColor; font.family: "Symbols Nerd Font" }
                    MouseArea {
                        anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.LeftButton) { toggleWifi.running = true; }
                            else if (mouse.button === Qt.RightButton) { openWifi.running = true; root.visible = false; }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 60; radius: 12
                    color: topBar.isBtOn ? Theme.primary : Theme.surfaceContainer
                    Text { anchors.centerIn: parent; text: "  Bluetooth"; font.bold: true; color: topBar.isBtOn ? Theme.onPrimaryColor : Theme.onSurfaceColor; font.family: "Symbols Nerd Font" }
                    MouseArea {
                        anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.LeftButton) { toggleBt.running = true; }
                            else if (mouse.button === Qt.RightButton) { openBt.running = true; root.visible = false; }
                        }
                    }
                }
            }

            // Sliders Row
            RowLayout {
                Text { text: "󰃠"; color: Theme.onSurfaceColor; font.family: "Symbols Nerd Font" }
                Slider {
                    id: briSlider
                    Layout.fillWidth: true; from: 0; to: 100

                    Binding { target: briSlider; property: "value"; value: topBar.briVal; when: !briSlider.pressed }

                    onMoved: {
                        setBri.command = ["brightnessctl", "set", Math.round(value) + "%"];
                        setBri.running = false;
                        Qt.callLater(() => { setBri.running = true; });
                    }
                }
            }
            RowLayout {
                Text {
                    text: topBar.isMuted ? "" : ""
                    color: topBar.isMuted ? "#ff5555" : Theme.onSurfaceColor
                    font.family: "Symbols Nerd Font"
                }
                Slider {
                    id: volSlider
                    Layout.fillWidth: true; from: 0; to: 100

                    Binding { target: volSlider; property: "value"; value: topBar.volVal; when: !volSlider.pressed }

                    onMoved: {
                        setVol.command = ["pactl", "set-sink-volume", "@DEFAULT_SINK@", Math.round(value) + "%"];
                        setVol.running = false;
                        Qt.callLater(() => { setVol.running = true; });
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // Power Buttons
            RowLayout {
                Layout.fillWidth: true; Layout.alignment: Qt.AlignHCenter; spacing: 20
                Pill {
                    icon: "󰒲"
                    onClicked: { cmdSleep.running = true }
                }
                Pill {
                    icon: "󰜉"
                    onClicked: {
                        confirmOverlay.actionType = "reboot"
                        confirmOverlay.actionName = "Reboot"
                        confirmOverlay.visible = true
                    }
                }
                Pill {
                    icon: ""
                    iconColor: "#ff5555"
                    onClicked: {
                        confirmOverlay.actionType = "poweroff"
                        confirmOverlay.actionName = "Power Off"
                        confirmOverlay.visible = true
                    }
                }
            }
        }

        // --- Confirmation Overlay ---
        Rectangle {
            id: confirmOverlay
            anchors.fill: parent
            radius: 20
            color: Theme.surfaceContainer
            visible: false

            property string actionType: ""
            property string actionName: ""

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "Confirm " + confirmOverlay.actionName + "?"
                    color: Theme.onSurfaceColor
                    font.family: "Fira Code"
                    font.pointSize: 14
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20

                    Pill {
                        text: "Cancel"
                        onClicked: confirmOverlay.visible = false
                    }
                    Pill {
                        text: confirmOverlay.actionName
                        iconColor: "#ff5555"
                        onClicked: {
                            if (confirmOverlay.actionType === "reboot") cmdReboot.running = true;
                            if (confirmOverlay.actionType === "poweroff") cmdPoweroff.running = true;
                            confirmOverlay.visible = false;
                        }
                    }
                }
            }
        }
    }
}
