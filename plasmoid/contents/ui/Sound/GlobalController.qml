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
    property string icon
    property var pulseObject

    signal setVolume(var volume)

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

                RowLayout {
                    id: contorller
                    Layout.fillWidth: true

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
}
