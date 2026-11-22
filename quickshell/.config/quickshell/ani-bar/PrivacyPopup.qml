import QtQuick
import QtQuick.Layouts
import "BarStyle.js" as BarStyle

BarPopup {
    id: privacy

    required property var microphone
    required property var video
    required property bool screenShare

    implicitWidth: 300
    implicitHeight: privacyContent.implicitHeight + 28

    function appName(node) {
        return node.properties?.["application.name"] || node.description || node.name || "Unknown app";
    }

    ColumnLayout {
        id: privacyContent
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 2

        PopupHeader {
            Layout.bottomMargin: 6
            theme: privacy.theme
            title: "In use"
        }

        Repeater {
            model: privacy.microphone
            ListRow {
                required property var modelData
                theme: privacy.theme
                interactive: false
                icon: BarStyle.icons.microphone
                iconColor: privacy.theme.critical
                title: privacy.appName(modelData)
                detail: "Microphone"
            }
        }
        Repeater {
            model: privacy.video
            ListRow {
                required property var modelData
                theme: privacy.theme
                interactive: false
                icon: privacy.screenShare ? BarStyle.icons.screenShare : BarStyle.icons.webcam
                iconColor: privacy.theme.critical
                title: privacy.appName(modelData)
                detail: privacy.screenShare ? "Screen" : "Camera"
            }
        }
    }
}
