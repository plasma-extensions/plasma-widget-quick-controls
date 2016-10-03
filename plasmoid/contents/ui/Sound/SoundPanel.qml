import QtQuick 2.0
import QtQuick.Layouts 1.0

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.plasma.private.volume 0.1

import "../../code/soundicon.js" as Icon

Item {
    id: main
    height: globalController.height

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

    GlobalController {
        id: globalController
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        subComponent: fullPanel;
        //subComponent: sinkModel.rowCount() > 1 ? fullPanel : undefined;

        pulseObject: sinkModel.sinks[currentDevice]
        property int currentDevice : 0;
        property var currentDeviceDescription : pulseObject ? pulseObject.description : i18n("Audio Volume");

        onSetVolume: main.setVolume(volume);
    }

    Component {
        id: fullPanel

        ColumnLayout {
            ListView {
                id: sinkView

                Layout.fillWidth: true
                Layout.minimumHeight: contentHeight
                Layout.maximumHeight: contentHeight

                model: sinkModel
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: globalController.currentDevice
                onCurrentIndexChanged: globalController.currentDevice = currentIndex;


                highlight: Rectangle {
                    anchors.left: parent.left;
                    anchors.right: parent.right;
                    color: theme.highlightColor;
                }
                highlightFollowsCurrentItem: true
                delegate: RowLayout {

                    PlasmaComponents.Label {
                        Layout.leftMargin: 12;
                        Layout.rightMargin: 8;
                        Layout.topMargin: 8
                        Layout.bottomMargin: 8
                        text: PulseObject.description
                        font.pointSize: 11
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: sinkView.currentIndex = index;
                    }
                }
            }
        }
    }

    function setVolume(volume) {
        var device = globalController.pulseObject;
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
        return 100 * volume / slider.maximumValue;
    }
}
