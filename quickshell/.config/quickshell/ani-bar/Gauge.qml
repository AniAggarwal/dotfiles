import QtQuick
import QtQuick.Shapes
import "BarStyle.js" as BarStyle

// A ring gauge open at the bottom, with the reading in the middle and the label in the opening.
Item {
    id: gauge

    required property BarState theme
    // 0..1; negative means no reading (empty ring, dimmed text).
    property real value: -1
    property color color: theme.accent
    property string label
    property string reading
    property string above
    property string below
    property int thickness: 7
    property real shown: Math.max(0, Math.min(1, value))
    readonly property real radius: Math.min(width, height) / 2 - thickness

    Behavior on shown { NumberAnimation { duration: BarStyle.motion.meter; easing.type: Easing.OutCubic } }

    Accessible.role: Accessible.Indicator
    Accessible.name: label + " " + reading

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Qt.alpha(gauge.theme.foreground, 0.1)
            strokeWidth: gauge.thickness
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            PathAngleArc {
                centerX: gauge.width / 2
                centerY: gauge.height / 2
                radiusX: gauge.radius
                radiusY: gauge.radius
                startAngle: 130
                sweepAngle: 280
            }
        }

        ShapePath {
            strokeColor: gauge.value >= 0 ? gauge.color : "transparent"
            strokeWidth: gauge.thickness
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            PathAngleArc {
                centerX: gauge.width / 2
                centerY: gauge.height / 2
                radiusX: gauge.radius
                radiusY: gauge.radius
                startAngle: 130
                sweepAngle: Math.max(0.5, 280 * gauge.shown)
            }
        }
    }

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -2
        spacing: 1

        PanelText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !!gauge.above
            text: gauge.above
            color: gauge.theme.secondary
            font.pixelSize: BarStyle.popupFontSize - 2
            font.features: { "tnum": 1 }
        }
        PanelText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: gauge.reading
            color: gauge.value >= 0 ? gauge.theme.foreground : gauge.theme.muted
            font.pixelSize: gauge.reading.length > 5 ? BarStyle.popupFontSize + 3 : BarStyle.popupFontSize + 9
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }
        PanelText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !!gauge.below
            text: gauge.below
            color: gauge.theme.secondary
            font.pixelSize: BarStyle.popupFontSize - 2
            font.features: { "tnum": 1 }
        }
    }

    PanelText {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        text: gauge.label
        color: gauge.theme.foreground
        font.weight: Font.DemiBold
    }
}
