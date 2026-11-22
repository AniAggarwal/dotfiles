import QtQuick
import "BarStyle.js" as BarStyle

// A compact live reading for the bar: level meter, icon, and value.
Item {
    id: stat

    required property BarState theme
    required property string icon
    required property string value
    // Widest expected value, so changing digits never shift the bar. Digits are tabular, so "0" stands for any.
    property string valueTemplate: ""
    // 0..1 fills the meter. Negative leaves the track empty (no reading).
    property real fraction: -1
    property int severity: 0
    property bool dimmed: false
    readonly property color tone: theme.tone(severity)

    implicitWidth: row.implicitWidth + 12
    implicitHeight: BarStyle.chipHeight

    Accessible.role: Accessible.Indicator
    Accessible.name: value

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 3

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 12
            radius: 1.5
            color: Qt.alpha(stat.theme.foreground, 0.14)

            Rectangle {
                visible: stat.fraction >= 0
                anchors.bottom: parent.bottom
                width: parent.width
                radius: parent.radius
                height: Math.max(2, parent.height * Math.max(0, Math.min(1, stat.fraction)))
                color: stat.tone
                Behavior on height { NumberAnimation { duration: BarStyle.motion.meter; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: BarStyle.motion.normal } }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: BarStyle.barIconBox
            horizontalAlignment: Text.AlignHCenter
            text: stat.icon
            color: stat.severity > 0 ? stat.tone : stat.dimmed ? stat.theme.muted : stat.theme.secondary
            font.family: BarStyle.iconFont
            font.pixelSize: BarStyle.barIconSize
        }

        Text {
            id: valueText
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(implicitWidth, Math.ceil(metrics.advanceWidth))
            horizontalAlignment: Text.AlignRight
            text: stat.value
            color: stat.severity > 0 ? stat.tone : stat.dimmed ? stat.theme.muted : stat.theme.foreground
            font.family: BarStyle.textFont
            font.pixelSize: BarStyle.barFontSize
            font.features: { "tnum": 1 }
        }
    }

    TextMetrics {
        id: metrics
        font: valueText.font
        text: stat.valueTemplate
    }
}
