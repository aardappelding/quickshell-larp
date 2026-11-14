import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.I3

PanelWindow {
    id: topBar
    anchors { top: true; left: true; right: true }
    height: 56
    color: "transparent"

    // --- Centralized UI State Backend ---
    property string timeStr: "..."
    property string cpuStr: "0"
    property string tempStr: "0"
    property string memStr: "0"
    property int batVal: 0
    property string batState: ""
    property int volVal: 0
    property bool isMuted: false
    property int wifiSig: 0
    property bool isWifiOn: false
    property bool isBtOn: false
    property int briVal: 50

    function parseOut(out) {
        if (out === null || out === undefined) return "";
        return out.toString().trim();
    }

    // --- Dynamic Icon Logic ---
    function getVolIcon(vol, isMuted) {
        if (isMuted) return "";
        if (vol === 0) return "󰝟";
        if (vol < 33) return "󰕿";
        if (vol < 66) return "󰖀";
        return "󰕾";
    }
    function getWifiIcon(signal) {
        if (signal === 0) return "󰤯";
        if (signal < 25) return "󰤟";
        if (signal < 50) return "󰤢";
        if (signal < 75) return "󰤥";
        return "󰤨";
    }
    function getBatIcon(bat, state) {
        let c = (state === "Charging");
        if (bat >= 95) return c ? "󰂅" : "󰁹";
        if (bat >= 90) return c ? "󰂋" : "󰂂";
        if (bat >= 80) return c ? "󰂊" : "󰂁";
        if (bat >= 70) return c ? "󰢞" : "󰂀";
        if (bat >= 60) return c ? "󰂉" : "󰁿";
        if (bat >= 50) return c ? "󰢝" : "󰁾";
        if (bat >= 40) return c ? "󰂈" : "󰁽";
        if (bat >= 30) return c ? "󰂇" : "󰁼";
        if (bat >= 20) return c ? "󰂆" : "󰁻";
        if (bat >= 10) return c ? "󰢜" : "󰁺";
        return c ? "󰢜" : "󰂎";
    }

    // --- Data Polling via StdioCollector ---

    Process {
        id: timeProc; command: ["date", "+%b %d  %H:%M"]
        stdout: StdioCollector { onStreamFinished: { let t = topBar.parseOut(this.text); if(t) topBar.timeStr = t; } }
    }
    Timer { interval: 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { timeProc.running = false; Qt.callLater(() => { timeProc.running = true; }) } }

    Process {
        id: cpuProc; command: ["sh", "-c", "vmstat 1 2 | tail -1 | awk '{print 100 - $15}'"]
        stdout: StdioCollector { onStreamFinished: { let t = topBar.parseOut(this.text); if(t) topBar.cpuStr = t; } }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { cpuProc.running = false; Qt.callLater(() => { cpuProc.running = true; }) } }

    Process {
        id: tempProc; command: ["sh", "-c", "cat /sys/class/thermal/thermal_zone0/temp | awk '{print $1/1000}' | cut -d. -f1"]
        stdout: StdioCollector { onStreamFinished: { let t = topBar.parseOut(this.text); if(t) topBar.tempStr = t; } }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { tempProc.running = false; Qt.callLater(() => { tempProc.running = true; }) } }

    // Memory output changed to percentage calculation
    Process {
        id: memProc; command: ["sh", "-c", "free | awk '/^Mem/ {printf(\"%.0f\", $3/$2 * 100)}'"]
        stdout: StdioCollector { onStreamFinished: { let t = topBar.parseOut(this.text); if(t) topBar.memStr = t; } }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { memProc.running = false; Qt.callLater(() => { memProc.running = true; }) } }

    Process {
        id: batProc; command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/capacity | head -n1"]
        stdout: StdioCollector { onStreamFinished: { let t = topBar.parseOut(this.text); if(t) { let v = parseInt(t); if(!isNaN(v)) topBar.batVal = v; } } }
    }
    Process {
        id: batStateProc; command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/status | head -n1"]
        stdout: StdioCollector { onStreamFinished: { let t = topBar.parseOut(this.text); if(t) topBar.batState = t; } }
    }
    Timer { interval: 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { batProc.running = false; batStateProc.running = false; Qt.callLater(() => { batProc.running = true; batStateProc.running = true; }) } }

    Process {
        id: volProc; command: ["sh", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | grep -Eo '[0-9]+%' | head -n1 | tr -d '%'"]
        stdout: StdioCollector { onStreamFinished: { let t = topBar.parseOut(this.text); if(t) { let v = parseInt(t); if(!isNaN(v)) topBar.volVal = v; } } }
    }
    Process {
        id: muteProc; command: ["sh", "-c", "pactl get-sink-mute @DEFAULT_SINK@ | grep -q 'yes' && echo yes || echo no"]
        stdout: StdioCollector { onStreamFinished: { let t = topBar.parseOut(this.text); if(t) topBar.isMuted = (t === "yes"); } }
    }
    Process {
        id: wifiProc; command: ["sh", "-c", "nmcli -t -f IN-USE,SIGNAL dev wifi | grep '*' | cut -d: -f2"]
        stdout: StdioCollector { onStreamFinished: { let t = topBar.parseOut(this.text); if(t) { let v = parseInt(t); if(!isNaN(v)) topBar.wifiSig = v; } } }
    }
    Timer { interval: 200; running: true; repeat: true; triggeredOnStart: true; onTriggered: { volProc.running = false; muteProc.running = false; wifiProc.running = false; Qt.callLater(() => { volProc.running = true; muteProc.running = true; wifiProc.running = true; }) } }

    Process {
        id: wifiRadioProc; command: ["sh", "-c", "nmcli radio wifi | tr -d '\n'"]
        stdout: StdioCollector { onStreamFinished: { let t = topBar.parseOut(this.text); if(t) topBar.isWifiOn = (t === "enabled"); } }
    }
    Process {
        id: btProc; command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo yes || echo no"]
        stdout: StdioCollector { onStreamFinished: { let t = topBar.parseOut(this.text); if(t) topBar.isBtOn = (t === "yes"); } }
    }

    // User-requested brightnessctl polling logic
    Process {
        id: briProc; command: ["sh", "-c", "brightnessctl -m | awk -F, '{print $4}' | tr -d '%'"]
        stdout: StdioCollector { onStreamFinished: { let t = topBar.parseOut(this.text); if(t) { let v = parseInt(t); if(!isNaN(v)) topBar.briVal = v; } } }
    }
    Timer { interval: 200; running: true; repeat: true; triggeredOnStart: true; onTriggered: { wifiRadioProc.running = false; btProc.running = false; briProc.running = false; Qt.callLater(() => { wifiRadioProc.running = true; btProc.running = true; briProc.running = true; }) } }

    // --- Main Top Bar Layout ---
    Item {
        anchors.fill: parent
        anchors.topMargin: 10; anchors.leftMargin: 20; anchors.rightMargin: 20

        // Left Row - Now using strict Row instead of RowLayout to prevent elements touching
        Row {
            anchors.left: parent.left
            spacing: 10

            Pill { icon: ""; iconColor: Theme.primary }

            // --- Animated Native IPC Workspaces Module ---
            Rectangle {
                id: wsPill
                height: 36
                width: wsRow.width + 16
                radius: height / 2
                color: Theme.surfaceContainer

                property int activeNum: I3.focusedWorkspace ? I3.focusedWorkspace.number : 1

                Rectangle {
                    width: 28; height: 28; radius: 14; y: 4
                    color: Theme.primary
                    x: 8 + (Math.max(0, Math.min(wsPill.activeNum - 1, 4)) * 36)
                    Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                }

                Row {
                    id: wsRow
                    anchors.centerIn: parent
                    spacing: 8

                    Repeater {
                        model: 5
                        Item {
                            width: 28; height: 28
                            property bool isActive: wsPill.activeNum === (index + 1)

                            Text {
                                anchors.centerIn: parent
                                text: (index + 1).toString()
                                color: parent.isActive ? Theme.onPrimaryColor : Theme.onSurfaceColor
                                font.family: "Fira Code"
                                font.bold: true
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: I3.dispatch("workspace number " + (index + 1).toString())
                            }
                        }
                    }
                }
            }

            Pill { icon: ""; text: topBar.cpuStr + "%" }
            Pill { icon: ""; text: topBar.tempStr + "°C" }
            Pill { icon: ""; text: topBar.memStr + "%" } // Updated to show percentage
        }

        // Center Row - Strictly anchored to horizontalCenter of screen
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            Pill {
                icon: ""
                text: topBar.timeStr
                onClicked: calendarPopup.visible = !calendarPopup.visible
            }
        }

        // Right Row
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Pill {
                icon: topBar.getVolIcon(topBar.volVal, topBar.isMuted)
                iconColor: topBar.isMuted ? "#ff5555" : Theme.onSurfaceColor
            }
            Pill { icon: topBar.getWifiIcon(topBar.wifiSig) }
            Pill {
                icon: topBar.getBatIcon(topBar.batVal, topBar.batState)
                tooltipText: topBar.batVal + "%" + (topBar.batState === "Charging" ? " (Charging)" : "")
            }
            Pill {
                icon: ""
                onClicked: quickSettingsPopup.visible = !quickSettingsPopup.visible
            }
        }
    }

    CalendarPopup { id: calendarPopup }
    QuickSettingsPopup { id: quickSettingsPopup }
}
