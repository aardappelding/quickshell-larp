pragma Singleton
import QtQuick

QtObject {
    property color background: "#12140e"
    property color surface: "#12140e"
    property color surfaceContainer: "#1e201a"
    property color primary: "#b2d189"
    
    // Renamed to avoid QML signal conflict
    property color onPrimaryColor: "#203601"
    property color onSurfaceColor: "#e2e3d8"
    property color onSurfaceVariantColor: "#c5c8ba"
}
