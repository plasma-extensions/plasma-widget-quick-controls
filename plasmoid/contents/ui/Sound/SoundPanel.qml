import QtQuick 2.0
import QtQuick.Layouts 1.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

import org.kde.plasma.private.volume 0.1

import "../../code/soundicon.js" as Icon

Item {
    id: main
    height: globalController.height

    function runOnAllSinks(func) {
        if (typeof (sinkView) === "undefined") {
            print("This case we need to handle.")
            return
        } else if (sinkView.count < 0) {
            return
        }
        for (var i = 0; i < sinkView.count; ++i) {
            sinkView.currentIndex = i
            sinkView.currentItem[func]()
        }
    }

    function increaseVolume() {
        runOnAllSinks("increaseVolume")
    }

    function decreaseVolume() {
        runOnAllSinks("decreaseVolume")
    }

    function muteVolume() {
        runOnAllSinks("toggleMute")
    }

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
        label: i18n("Audio Volume")
        subComponent: fullPanel

        pulseObject: sinkModel.sinks[0]

        onSetVolume: {
            for (var i = 0; i < sinkModel.rowCount(); i ++) {
                var sink = sinkModel.sinks[i];
                if (volume > 0 && muted) {
                    var toMute = !sink.PulseObject.Muted;
                    if (toMute) {
                        osd.show(0);
                    } else {
                        osd.show(volumePercent(volume));
                    }
                    sink.Muted = toMute;
                }
                sink.volume = volume
            }
        }
    }

    Component {
        id: fullPanel

        ColumnLayout {

            Header {
                Layout.fillWidth: true
                visible: sinkView.count > 0
                text: i18n("Playback Devices")
            }
            ListView {
                id: sinkView

                Layout.fillWidth: true
                Layout.minimumHeight: contentHeight
                Layout.maximumHeight: contentHeight

                model: sinkModel
                boundsBehavior: Flickable.StopAtBounds
                delegate: SinkListItem {
                }
            }

            Header {
                Layout.fillWidth: true
                visible: sourceView.count > 0
                text: i18n("Capture Devices")
            }
            ListView {
                id: sourceView

                Layout.fillWidth: true
                Layout.minimumHeight: contentHeight
                Layout.maximumHeight: contentHeight

                model: SourceModel {
                    id: sourceModel
                }
                boundsBehavior: Flickable.StopAtBounds
                delegate: SourceListItem {
                }
            }
        }
    }
}
