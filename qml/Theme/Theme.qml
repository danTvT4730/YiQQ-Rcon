pragma Singleton
import QtQuick

QtObject {
    id: theme

    property bool dark: false

    readonly property color bgBase: dark ? "#0f172a" : "#ffffff"
    readonly property color bgPage: dark ? "#0f172a" : "#f8fafc"
    readonly property color bgCard: dark ? "#1e293b" : "#ffffff"
    readonly property color bgCardHover: dark ? "#334155" : "#f1f5f9"
    readonly property color bgInput: dark ? "#1e293b" : "#ffffff"
    readonly property color bgConsole: dark ? "#020617" : "#f8fafc"
    readonly property color bgElevated: dark ? "#334155" : "#ffffff"

    readonly property color border: dark ? "#334155" : "#e2e8f0"
    readonly property color borderStrong: dark ? "#475569" : "#cbd5e1"
    readonly property color borderAccent: dark ? "#60a5fa" : "#bfdbfe"

    readonly property color textMain: dark ? "#f8fafc" : "#0f172a"
    readonly property color textSub: dark ? "#cbd5e1" : "#475569"
    readonly property color textMuted: dark ? "#94a3b8" : "#94a3b8"
    readonly property color textAccent: dark ? "#60a5fa" : "#2563eb"
    readonly property color textInverse: "#ffffff"

    readonly property color accent: dark ? "#3b82f6" : "#2563eb"
    readonly property color accentHover: dark ? "#60a5fa" : "#1d4ed8"
    readonly property color accentLight: dark ? "#1e40af" : "#eff6ff"
    readonly property color accentDim: dark ? Qt.rgba(0.231, 0.510, 0.965, 0.20) : Qt.rgba(0.231, 0.510, 0.965, 0.08)

    readonly property color amber: "#f59e0b"
    readonly property color amberLight: "#fffbeb"
    readonly property color red: "#ef4444"
    readonly property color redLight: "#fef2f2"
    readonly property color green: "#10b981"
    readonly property color greenLight: "#ecfdf5"
    readonly property color yellow: "#eab308"

    readonly property color scrollHandle: dark ? "#475569" : "#cbd5e1"
    readonly property color scrollHandleHover: dark ? "#60a5fa" : "#94a3b8"
    readonly property color selectionBg: dark ? Qt.rgba(0.231, 0.510, 0.965, 0.30) : Qt.rgba(0.231, 0.510, 0.965, 0.15)
    readonly property color selectionFg: dark ? "#ffffff" : "#1d4ed8"

    readonly property color transparent: "transparent"

    readonly property int radiusSmall: 6
    readonly property int radiusMedium: 10
    readonly property int radiusLarge: 14
    readonly property int radiusPill: 999

    readonly property string fontFamily: "HarmonyOS Sans SC"
    readonly property string monoFontFamily: "Cascadia Code, Consolas, JetBrains Mono, HarmonyOS Sans SC, monospace"

    readonly property int fontSizeSmall: 12
    readonly property int fontSizeNormal: 14
    readonly property int fontSizeLarge: 15
    readonly property int fontSizeTitle: 18
    readonly property int fontSizeHeader: 24

    function colorAlpha(c, alpha) {
        return Qt.rgba(c.r, c.g, c.b, alpha)
    }

    function iconSource(name, color, size) {
        var c = color ? color.toString() : "#94a3b8"
        var s = size || 20
        var encoded = c.replace("#", "%23")
        return "image://icons/" + name + "?color=" + encoded + "&size=" + s
    }
}
