import QtQuick
import "BarStyle.js" as BarStyle
import QtQuick.Layouts

BarPopup {
    id: calendar

    required property date now
    property date displayed: new Date(now.getFullYear(), now.getMonth(), 1)
    readonly property int firstWeekday: (displayed.getDay() + 6) % 7
    readonly property int dayCount: new Date(displayed.getFullYear(), displayed.getMonth() + 1, 0).getDate()
    readonly property bool thisMonth: displayed.getFullYear() === now.getFullYear() && displayed.getMonth() === now.getMonth()

    implicitWidth: 294
    implicitHeight: 310
    onVisibleChanged: if (visible) displayed = new Date(now.getFullYear(), now.getMonth(), 1)

    function stepMonth(step) {
        displayed = new Date(displayed.getFullYear(), displayed.getMonth() + step, 1);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                PanelText {
                    text: Qt.formatDate(calendar.displayed, "MMMM yyyy")
                    font.pixelSize: BarStyle.popupFontSize + 5
                    font.weight: Font.DemiBold
                    color: calendar.theme.foreground
                }
                PanelText {
                    text: Qt.formatDate(calendar.now, "dddd, MMMM d")
                    font.pixelSize: BarStyle.popupFontSize - 2
                    color: Qt.alpha(calendar.theme.foreground, 0.65)
                }
            }

            BarButton {
                label: "‹"
                hint: "Previous month"
                foreground: calendar.theme.foreground
                accent: calendar.theme.accent
                onActivated: calendar.stepMonth(-1)
            }
            BarButton {
                label: "›"
                hint: "Next month"
                foreground: calendar.theme.foreground
                accent: calendar.theme.accent
                onActivated: calendar.stepMonth(1)
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 3
            rowSpacing: 3

            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                PanelText {
                    required property string modelData
                    Layout.preferredHeight: 21
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: modelData
                    color: Qt.alpha(calendar.theme.foreground, 0.55)
                    font.pixelSize: BarStyle.popupFontSize - 3
                    font.weight: Font.DemiBold
                }
            }

            Repeater {
                model: 42

                Rectangle {
                    required property int index
                    readonly property int day: index - calendar.firstWeekday + 1
                    readonly property bool today: calendar.thisMonth && day === calendar.now.getDate()
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    color: today ? calendar.theme.accent : "transparent"
                    radius: 8

                    PanelText {
                        anchors.centerIn: parent
                        text: parent.day > 0 && parent.day <= calendar.dayCount ? parent.day.toString() : ""
                        font.pixelSize: 12
                        font.weight: parent.today ? Font.Bold : Font.Normal
                        color: parent.today ? calendar.theme.background : calendar.theme.foreground
                    }
                }
            }
        }

        BarButton {
            Layout.alignment: Qt.AlignRight
            label: "Today"
            foreground: calendar.theme.foreground
            accent: calendar.theme.accent
            selected: true
            onActivated: calendar.displayed = new Date(calendar.now.getFullYear(), calendar.now.getMonth(), 1)
        }
    }
}
