import QtQuick
import QtQuick.Layouts
import "BarStyle.js" as BarStyle

BarPopup {
    id: privacy

    // PipeWire streams capturing audio and video; apps holding the webcam come from theme.privacy.
    required property var microphone
    required property var video
    required property bool screenShare
    readonly property PrivacyState switches: theme.privacy
    readonly property bool inUse: microphone.length > 0 || video.length > 0 || switches.cameraUsers.length > 0

    panelWidth: 300
    panelHeight: privacyContent.implicitHeight + 28

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
            title: "Privacy"
        }

        ToggleTile {
            theme: privacy.theme
            icon: privacy.switches.micOff ? BarStyle.icons.microphoneOff : BarStyle.icons.microphone
            name: "Microphone"
            detail: privacy.switches.micOff ? "Off" : "On"
            selected: !privacy.switches.micOff
            onActivated: privacy.switches.setMicOff(!privacy.switches.micOff)
        }
        ToggleTile {
            Layout.topMargin: 4
            theme: privacy.theme
            icon: privacy.switches.cameraOff ? BarStyle.icons.webcamOff : BarStyle.icons.webcam
            name: "Camera"
            detail: privacy.switches.cameraError || (privacy.switches.cameraOff ? "Off" : "On")
            selected: !privacy.switches.cameraOff
            interactive: !privacy.switches.cameraSwitching
            onActivated: privacy.switches.setCameraOff(!privacy.switches.cameraOff)
        }

        PanelText {
            visible: privacy.inUse
            Layout.topMargin: 10
            Layout.bottomMargin: 2
            text: "In use"
            color: privacy.theme.secondary
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
            model: privacy.switches.cameraUsers
            ListRow {
                required property var modelData
                theme: privacy.theme
                interactive: false
                icon: BarStyle.icons.webcam
                iconColor: privacy.theme.critical
                title: modelData.name
                detail: "Camera"
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
