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

        onDataChanged: syncProxyModel()

        function syncProxyModel() {
            // print("syncSinkProxyModel ")
            sinkModelProxy.clear()
            for (var i = 0; i < rowCount(); i++) {
                var idx = index(i, 0)
                var sink = data(idx, role("PulseObject"))
                // print (sink, sink.description);
                sinkModelProxy.append({
                                          text: sink.description,
                                          sink: sink
                                      })
                var isDefault = data(idx, role("Default"))
                if (isDefault && sinkModelProxy.defaultSinkIndex !== i)
                    sinkModelProxy.defaultSinkIndex = i
            }
        }

        function setDefaultSink(i) {
            // print ("setDefaultSink", i)
            if (i < rowCount()) {
                var idx = index(i, 0)
                setData(idx, 1, role("Default"))
            }
        }
    }

    ListModel {
        id: sinkModelProxy
        property var defaultSink: sinkModel.defaultSink
        property int defaultSinkIndex: -1

        onDefaultSinkIndexChanged: sinkModel.setDefaultSink(defaultSinkIndex)
    }

    SourceModel {
        id: sourceModel

        onDataChanged: syncProxyModel()

        function syncProxyModel() {
            // print("syncSourceProxyModel ")
            sourceModelProxy.clear()
            for (var i = 0; i < rowCount(); i++) {
                var idx = index(i, 0)
                var sink = data(idx, role("PulseObject"))
                // print (sink, sink.description);
                sourceModelProxy.append({
                                          text: sink.description,
                                          sink: sink
                                      })
                var isDefault = data(idx, role("Default"))
                if (isDefault && sourceModelProxy.defaultSourceIndex !== i)
                    sourceModelProxy.defaultSourceIndex = i
            }
        }

        function setDefaultSource(i) {
            // print ("setDefaultSink", i)
            if (i < rowCount()) {
                var idx = index(i, 0)
                setData(idx, 1, role("Default"))
            }
        }
    }

    ListModel {
        id: sourceModelProxy
        property var defaultSource: sourceModel.defaultSource
        property int defaultSourceIndex: -1

        onDefaultSourceIndexChanged: sourceModel.setDefaultSource(defaultSourceIndex)
    }

    ColumnLayout {
        id: content

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        spacing: 4

        RowLayout {
            id: controller
            Layout.fillWidth: true

            GlobalController {
                id: globalController
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                pulseObject: sinkModelProxy.defaultSink
                onSetVolume: main.setVolume(volume)
            }

            PlasmaCore.SvgItem {
                id: expanderIcon
                Layout.alignment: Qt.AlignVCenter
                property bool expanded: false

                implicitHeight: openSettingsButton.height
                implicitWidth: openSettingsButton.width
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
            id: deviceDetailsLoader
            Layout.fillWidth: true
            Layout.bottomMargin: 12
            clip: true;

            Layout.maximumHeight: Layout.minimumHeight;

            NumberAnimation {
                id: showAnimation
                target: deviceDetailsLoader
                property: "Layout.minimumHeight"
                from: 0
                to: deviceDetailsLoader.implicitHeight
            }

            NumberAnimation {
                id: hideAnimation
                target: deviceDetailsLoader
                property: "Layout.minimumHeight"
                from: deviceDetailsLoader.implicitHeight
                to: 0
            }
        }

        states: [
            State {
                name: "collapsed"
                when: !expanderIcon.expanded
                StateChangeScript {
                    script: {
                        if (deviceDetailsLoader.status == Loader.Ready) {
                            hideAnimation.running = true
                            deviceDetailsLoader.sourceComponent = undefined
                        }
                    }
                }
            },
            State {
                name: "expanded"
                when: expanderIcon.expanded
                StateChangeScript {
                    script: {
                        deviceDetailsLoader.sourceComponent = details
                        showAnimation.running = true
                    }
                }
            }
        ]
    }

    Component {
        id: details
        ColumnLayout {
            PlasmaComponents.Label {
                Layout.leftMargin: 6
                text: i18n("Outputs")
            }

            PlasmaComponents.ComboBox {
                id: outputsComboBox
                Layout.fillWidth: true
                textRole: "text"
                model: sinkModelProxy
                currentIndex: sinkModelProxy.defaultSinkIndex
                onCurrentIndexChanged: sinkModelProxy.defaultSinkIndex = currentIndex
            }

            PlasmaComponents.ComboBox {
                id: outputsPortsComboBox
                Layout.fillWidth: true
                model: sinkModel.defaultSink.ports
                onModelChanged: currentIndex = sinkModel.defaultSink.activePortIndex
                textRole: "description"
                currentIndex: sinkModel.defaultSink.activePortIndex
                onActivated: sinkModel.defaultSink.activePortIndex = index
            }

            PlasmaComponents.Label {
                Layout.leftMargin: 6
                text: i18n("Inputs")
            }

            PlasmaComponents.ComboBox {
                id: inputsComboBox
                Layout.fillWidth: true
                textRole: "text"
                model: sourceModelProxy
                currentIndex: sourceModelProxy.defaultSourceIndex
                onCurrentIndexChanged: sourceModelProxy.defaultSourceIndex = currentIndex
            }

            PlasmaComponents.ComboBox {
                id: inputsPortsComboBox
                Layout.fillWidth: true
                model: sourceModel.defaultSource.ports
                onModelChanged: currentIndex = sourceModel.defaultSource.activePortIndex
                textRole: "description"
                currentIndex: sourceModel.defaultSource.activePortIndex
                onActivated: sourceModel.defaultSource.activePortIndex = index
            }
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
