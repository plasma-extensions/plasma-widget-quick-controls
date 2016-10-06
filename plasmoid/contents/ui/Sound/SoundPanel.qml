import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.4

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.kquickcontrolsaddons 2.0

import org.kde.plasma.private.volume 0.1

import "../../code/soundicon.js" as Icon

Item {
    id: main
    height: content.height

    GlobalActionCollection {
        // KGlobalAccel cannot transition from kmix to something else, so if
        // the user had a custom shortcut set for kmix those would get lost.
        // To avoid this we hijack kmix name and actions. Entirely mental but
        // best we can do to not cause annoyance for the user.
        // The display name actually is updated to whatever registered last
        // though, so as far as user visible strings go we should be fine.
        // As of 2015-07-21:
        //   componentName: kmix
        //   actions: increase_volume, decrease_volume, mute
        name: "kmix"
        GlobalAction {
            objectName: "increase_volume"
            text: i18n("Increase Volume")
            shortcut: Qt.Key_VolumeUp
            onTriggered: increaseVolume()
        }
        GlobalAction {
            objectName: "decrease_volume"
            text: i18n("Decrease Volume")
            shortcut: Qt.Key_VolumeDown
            onTriggered: decreaseVolume()
        }
        GlobalAction {
            objectName: "mute"
            text: i18n("Mute")
            shortcut: Qt.Key_VolumeMute
            onTriggered: muteVolume()
        }
    }

    VolumeOSD {
        id: osd
    }

    SinkModel {
        id: sinkModel
    }

    SourceModel {
        id: sourceModel
    }

    ColumnLayout {
        id: content

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        PlasmaComponents.TabBar {
            id: tabBar
            property int index: 0
            Layout.fillWidth: true
            PlasmaComponents.TabButton {
                text: i18n("Audio Output")
                onClicked: {
                    deviceDetails.sourceComponent = outputDeatils
                    globalController.pulseObject = deviceDetails.item.defaultDevice;
                }
            }

            PlasmaComponents.TabButton {
                text: i18n("Audio Input")
                onClicked: {
                    deviceDetails.sourceComponent = inputDeatils
                    globalController.pulseObject = deviceDetails.item.defaultDevice;
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            GlobalController {
                id: globalController
                Layout.fillWidth: true
                pulseObject: deviceDetails.item.defaultIndex
                onSetVolume: main.setVolume(volume);
            }

            PlasmaCore.SvgItem {
                id: expanderIcon
                property bool expanded: false

                implicitHeight: openSettingsButton.height;
                implicitWidth: openSettingsButton.width;
                antialiasing: true
                svg: PlasmaCore.Svg {
                    imagePath: "widgets/arrows"
                }
                elementId: "up-arrow"

                states: State {
                    name: "rotated"
                    PropertyChanges {
                        target: expanderIcon
                        rotation: 180

                    }
                    when: expanderIcon.expanded
                }

                transitions: Transition {
                    RotationAnimation {
                        direction: expanderIcon.expanded ? RotationAnimation.Clockwise : RotationAnimation.Counterclockwise
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: expanderIcon.expanded = !expanderIcon.expanded
                }
            }

            PlasmaComponents.ToolButton {
                id: openSettingsButton

                iconSource: "configure"
                tooltip: i18n("Configure Audio Volume...")

                onClicked: {
                    KCMShell.open(["pulseaudio"])
                }
            }
        }

        Loader {
            id: deviceDetails
            Layout.fillWidth: true
            visible: expanderIcon.expanded
            sourceComponent: outputDeatils
        }
    }
    Component {
        id: outputDeatils
        AudioControllersDetails {
            model: sinkModel
            onDefaultDeviceChanged: globalController.pulseObject = defaultDevice;
        }
    }

    Component {
        id: inputDeatils
        AudioControllersDetails {
            model: sourceModel
            onDefaultDeviceChanged: globalController.pulseObject = defaultDevice;
        }
    }

    function setVolume(volume) {
        var device = globalController.pulseObject
        if (volume > 0 && globalController.muted) {
            var toMute = !device.Muted
            if (toMute) {
                osd.show(0)
            } else {
                osd.show(volumePercent(volume))
            }
            device.Muted = toMute
        }
        device.volume = volume
    }

    function volumePercent(volume) {
        return 100 * volume / slider.maximumValue
    }
}
