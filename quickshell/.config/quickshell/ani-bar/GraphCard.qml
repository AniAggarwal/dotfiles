import QtQuick
import QtQuick.Layouts
import "BarStyle.js" as BarStyle

// A card with a title, a current value and a history graph under them.
Card {
    id: card

    property string title
    // Small line under the title, e.g. "62°C · 3.4 GHz".
    property string detail
    // The current reading, shown large on the right. Dimmed while there is no reading.
    property string value
    property bool dimmed: false
    // Extra items on the right of the header, and under the graph.
    property alias trailing: trailingRow.data
    property alias footer: footerColumn.data
    property alias histories: graph.histories
    property alias colors: graph.colors
    property alias ceiling: graph.ceiling
    property alias floor: graph.floor
    // Text in the graph's top right corner, e.g. the value at its top edge.
    property string scaleLabel
    readonly property real shownCeiling: graph.shownCeiling
    property bool interactive: false
    signal activated()

    Accessible.role: interactive ? Accessible.Button : Accessible.Indicator
    Accessible.name: title + " " + value

    HoverHandler { cursorShape: card.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor }
    TapHandler { enabled: card.interactive; onTapped: card.activated() }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PanelText {
                    Layout.fillWidth: true
                    text: card.title
                    color: card.theme.foreground
                    font.weight: Font.DemiBold
                }
                PanelText {
                    Layout.fillWidth: true
                    visible: !!card.detail
                    text: card.detail
                    color: card.theme.secondary
                    font.pixelSize: BarStyle.popupFontSize - 2
                    font.features: { "tnum": 1 }
                    elide: Text.ElideRight
                }
            }
            PanelText {
                visible: !!card.value
                text: card.value
                color: card.dimmed ? card.theme.muted : card.theme.foreground
                font.pixelSize: BarStyle.popupFontSize + 7
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
            RowLayout {
                id: trailingRow
                spacing: 6
            }
        }

        Graph {
            id: graph
            Layout.fillWidth: true
            Layout.fillHeight: true
            gridColor: Qt.alpha(card.theme.foreground, 0.05)

            PanelText {
                anchors.right: parent.right
                anchors.top: parent.top
                visible: !!card.scaleLabel
                text: card.scaleLabel
                color: card.theme.muted
                font.pixelSize: BarStyle.popupFontSize - 3
            }
        }

        ColumnLayout {
            id: footerColumn
            Layout.fillWidth: true
            visible: children.length > 0
            spacing: 4
        }
    }
}
