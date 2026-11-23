import QtQuick
import QtQuick.Layouts
import "BarStyle.js" as BarStyle

BarPopup {
    id: calendar

    required property date now
    property date displayed: new Date(now.getFullYear(), now.getMonth(), 1)
    readonly property int firstWeekday: (displayed.getDay() + 6) % 7
    readonly property bool thisMonth: displayed.getFullYear() === now.getFullYear() && displayed.getMonth() === now.getMonth()
    property real wheelDelta: 0

    panelWidth: 332
    padding: 16
    panelHeight: calendarContent.implicitHeight + 2 * padding
    onVisibleChanged: if (visible) displayed = new Date(now.getFullYear(), now.getMonth(), 1)

    function stepMonth(step) {
        displayed = new Date(displayed.getFullYear(), displayed.getMonth() + step, 1);
    }

    // Cell 0 is the Monday on or before the 1st, so leading/trailing days come from the neighbor months.
    function cellDate(index) {
        return new Date(displayed.getFullYear(), displayed.getMonth(), index - firstWeekday + 1);
    }

    function isoWeek(day) {
        const thursday = new Date(day.getFullYear(), day.getMonth(), day.getDate() + 3 - (day.getDay() + 6) % 7);
        const firstThursday = new Date(thursday.getFullYear(), 0, 4);
        return 1 + Math.round(((thursday - firstThursday) / 86400000 - 3 + (firstThursday.getDay() + 6) % 7) / 7);
    }

    WheelHandler {
        target: null
        onWheel: function(event) {
            calendar.wheelDelta += event.angleDelta.y;
            if (Math.abs(calendar.wheelDelta) >= 120) {
                calendar.stepMonth(calendar.wheelDelta > 0 ? -1 : 1);
                calendar.wheelDelta = 0;
            }
        }
    }

    component NavButton: PanelButton {
        theme: calendar.theme
        fontSize: BarStyle.popupFontSize + 5
        implicitWidth: 30
        implicitHeight: 30
        radius: 15
    }

    ColumnLayout {
        id: calendarContent
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            spacing: 2

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                PanelText {
                    Layout.fillWidth: true
                    text: Qt.formatDate(calendar.displayed, "MMMM yyyy")
                    font.pixelSize: BarStyle.popupFontSize + 5
                    font.weight: Font.DemiBold
                    color: calendar.theme.foreground
                }
                PanelText {
                    text: Qt.formatDate(calendar.now, "dddd, MMMM d")
                    font.pixelSize: BarStyle.popupFontSize - 2
                    color: calendar.theme.secondary
                }
            }

            NavButton { label: "‹"; hint: "Previous month"; onActivated: calendar.stepMonth(-1) }
            NavButton { label: "›"; hint: "Next month"; onActivated: calendar.stepMonth(1) }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 8
            columnSpacing: 2
            rowSpacing: 2

            Repeater {
                model: ["", "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                PanelText {
                    required property string modelData
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: modelData ? -1 : 22
                    Layout.fillWidth: modelData !== ""
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: modelData
                    color: calendar.theme.muted
                    font.pixelSize: BarStyle.popupFontSize - 2
                    font.weight: Font.Medium
                }
            }

            Repeater {
                model: 48

                Rectangle {
                    id: cell
                    required property int index
                    readonly property bool weekColumn: index % 8 === 0
                    readonly property int dayIndex: Math.floor(index / 8) * 7 + (index % 8) - 1
                    readonly property date day: calendar.cellDate(weekColumn ? dayIndex + 1 : dayIndex)
                    readonly property bool inMonth: day.getMonth() === calendar.displayed.getMonth()
                    readonly property bool today: !weekColumn && day.getFullYear() === calendar.now.getFullYear()
                        && day.getMonth() === calendar.now.getMonth() && day.getDate() === calendar.now.getDate()
                    readonly property bool weekend: !weekColumn && (day.getDay() === 0 || day.getDay() === 6)

                    Layout.fillWidth: !weekColumn
                    Layout.preferredWidth: weekColumn ? 22 : -1
                    Layout.preferredHeight: 34
                    color: "transparent"

                    // Today sits on a rounded square.
                    Rectangle {
                        anchors.centerIn: parent
                        visible: cell.today
                        width: 32
                        height: 32
                        radius: 11
                        color: calendar.theme.accent
                    }

                    PanelText {
                        anchors.centerIn: parent
                        text: cell.weekColumn ? calendar.isoWeek(cell.day) : cell.day.getDate()
                        font.pixelSize: cell.weekColumn ? BarStyle.popupFontSize - 3 : BarStyle.popupFontSize
                        font.weight: cell.today ? Font.DemiBold : Font.Normal
                        font.features: { "tnum": 1 }
                        color: cell.today ? calendar.theme.background
                            : cell.weekColumn ? Qt.alpha(calendar.theme.muted, 0.7)
                            : !cell.inMonth ? Qt.alpha(calendar.theme.muted, 0.55)
                            : cell.weekend ? calendar.theme.secondary
                            : calendar.theme.foreground
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Item { Layout.fillWidth: true }
            PanelButton {
                label: "Today"
                theme: calendar.theme
                selected: !calendar.thisMonth
                interactive: !calendar.thisMonth
                opacity: interactive ? 1 : 0.45
                onActivated: calendar.displayed = new Date(calendar.now.getFullYear(), calendar.now.getMonth(), 1)
            }
        }
    }
}
