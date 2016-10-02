import QtQuick 2.0

import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0

import org.kde.kquickcontrolsaddons 2.0
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras

MouseArea {
    id: root
    property bool muted: false
    property bool expanded: false
    property string icon
    property Component subComponent
    property var pulseObject

    property alias label: textLabel.text
    property alias expanderIconVisible: expanderIcon.visible

    signal setVolume(var volume)

    enabled: subComponent

    height: layout.implicitHeight

    onIconChanged: {
        clientIcon.visible = icon ? true : false
        clientIcon.icon = icon
    }

    ColumnLayout {
        id: layout

        anchors {
            left: parent.left
            right: parent.right
        }

        RowLayout {
            id: controler
            Layout.fillWidth: true
            spacing: 8

            ColumnLayout {
                id: column

                Item {
                    Layout.fillWidth: true
                    height: textLabel.height

                    PlasmaComponents.Label {
                        id: textLabel
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: expanderIcon.visible ? expanderIcon.left : parent.right
                        //                    anchors.verticalCenter: iconContainer.verticalCenter
                        font.pointSize: 12
                    }

                    PlasmaCore.SvgItem {
                        id: expanderIcon
                        visible: subComponent
                        anchors.top: parent.top
                        anchors.right: openSettingsButton.left
                        anchors.rightMargin: units.smallSpacing
                        anchors.bottom: parent.bottom
                        width: height
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
                            when: expanded
                        }

                        transitions: Transition {
                            RotationAnimation {
                                direction: expanded ? RotationAnimation.Clockwise : RotationAnimation.Counterclockwise
                            }
                        }
                    }

                    PlasmaComponents.ToolButton {
                        id: openSettingsButton

                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom

                        iconSource: "configure"
                        tooltip: i18n("Configure Audio Volume...")

                        onClicked: {
                            KCMShell.open(["pulseaudio"])
                        }
                    }
                }

                Loader {
                    id: subLoader
                    height: 0;
                    clip: true;

                    Layout.fillWidth: true
                    Layout.maximumHeight: Layout.minimumHeight

                    NumberAnimation {
                          id: showAnimation
                          target: subLoader
                          property: "Layout.minimumHeight"
                          from: 0
                          to: subLoader.item ? subLoader.item.implicitHeight : 0
                    }

                    NumberAnimation {
                          id: hideAnimation
                          target: subLoader
                          property: "Layout.minimumHeight"
                          from: subLoader.item.implicitHeight
                          to: 0
                    }
                }

                RowLayout {
                    Layout.rightMargin: 8;
                    Layout.leftMargin: 8;

                    VolumeIcon {
                        Layout.maximumHeight: slider.height * 0.75
                        Layout.maximumWidth: slider.height * 0.75
                        volume: pulseObject.volume
                        muted: pulseObject.muted

                        MouseArea {
                            anchors.fill: parent
                            onPressed: pulseObject.muted = !pulseObject.muted
                        }
                    }

                    PlasmaComponents.Slider {
                        id: slider

                        // Helper properties to allow async slider updates.
                        // While we are sliding we must not react to value updates
                        // as otherwise we can easily end up in a loop where value
                        // changes trigger volume changes trigger value changes.
                        property int volume: pulseObject.volume
                        property bool ignoreValueChange: false

                        Layout.fillWidth: true
                        minimumValue: 0
                        // FIXME: I do wonder if exposing max through the model would be useful at all
                        maximumValue: 65536
                        stepSize: maximumValue / 100
                        visible: pulseObject.hasVolume
                        enabled: {
                            if (typeof pulseObject.volumeWritable === 'undefined') {
                                return !pulseObject.muted
                            }
                            return pulseObject.volumeWritable
                                    && !pulseObject.muted
                        }

                        onVolumeChanged: {
                            ignoreValueChange = true
                            value = pulseObject.volume
                            ignoreValueChange = false
                        }

                        onValueChanged: {
                            if (!ignoreValueChange) {
                                setVolume(value)

                                if (!pressed) {
                                    updateTimer.restart()
                                }
                            }
                        }

                        onPressedChanged: {
                            if (!pressed) {
                                // Make sure to sync the volume once the button was
                                // released.
                                // Otherwise it might be that the slider is at v10
                                // whereas PA rejected the volume change and is
                                // still at v15 (e.g.).
                                updateTimer.restart()
                            }
                        }

                        Timer {
                            id: updateTimer
                            interval: 200
                            onTriggered: slider.value = pulseObject.volume
                        }
                    }
                    PlasmaComponents.Label {
                        id: percentText
                        Layout.alignment: Qt.AlignHCenter
                        Layout.minimumWidth: referenceText.width
                        horizontalAlignment: Qt.AlignRight
                        text: i18nc(
                                  "volume percentage", "%1%", Math.floor(
                                      slider.value / slider.maximumValue * 100.0))
                    }
                }
            }
        }


    }

    states: [
        State {
            name: "collapsed"
            when: !expanded
            StateChangeScript {
                script: {
                    if (subLoader.status == Loader.Ready) {
                        hideAnimation.running = true;
                        subLoader.sourceComponent = undefined
                    }
                }
            }
        },
        State {
            name: "expanded"
            when: expanded
            StateChangeScript {
                script: {
                    subLoader.sourceComponent = subComponent;
                    showAnimation.running = true;
                }
            }
        }
    ]


    onClicked: {
        if (!subComponent) {
            return
        }

        expanded = !expanded
    }
}
