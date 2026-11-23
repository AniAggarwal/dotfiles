import QtQuick
import "BarStyle.js" as BarStyle

// A progress line whose played part is a wave. The wave is drawn once and then only slid
// sideways and flattened, which the GPU does without repainting anything.
Item {
    id: line

    // 0..1
    property real fraction: 0
    property color color: "white"
    property color trackColor: Qt.alpha(color, 0.25)
    // The wave rolls while true and settles flat while false.
    property bool moving: false
    // Whether rolling is allowed at all (off on battery): the wave then stands still.
    property bool animated: true
    readonly property real wavelength: 26
    readonly property real stroke: 3
    readonly property real played: Math.max(0, Math.min(1, fraction)) * width

    implicitHeight: 18

    // Played part.
    Item {
        width: Math.max(0, line.played - 5)
        height: parent.height
        clip: true

        Canvas {
            id: wave
            property real shift: 0
            x: -shift
            width: line.width + line.wavelength
            height: parent.height
            transform: Scale { origin.y: wave.height / 2; yScale: line.moving ? 1 : 0.0001; Behavior on yScale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } } }
            onWidthChanged: requestPaint()
            Connections {
                target: line
                function onColorChanged() { wave.requestPaint(); }
            }
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.strokeStyle = line.color.toString();
                ctx.lineWidth = line.stroke;
                ctx.lineCap = "round";
                ctx.beginPath();
                const middle = height / 2;
                for (let x = 0; x <= width; x += 2) {
                    const y = middle + 3.2 * Math.sin(2 * Math.PI * x / line.wavelength);
                    if (x === 0)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }
                ctx.stroke();
            }

            NumberAnimation on shift {
                running: line.moving && line.animated && line.visible
                loops: Animation.Infinite
                from: 0
                to: line.wavelength
                duration: 1500
            }
        }

        // The same stretch as a flat line, for when the wave has settled.
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: line.stroke
            radius: height / 2
            color: line.color
            opacity: line.moving ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 260 } }
        }
    }

    // Position marker.
    Rectangle {
        x: Math.max(0, Math.min(line.width - width, line.played - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: parent.height
        radius: 1.5
        color: line.color
    }

    // What is left to play.
    Rectangle {
        x: line.played + 5
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, line.width - x)
        height: line.stroke
        radius: height / 2
        color: line.trackColor
    }
}
