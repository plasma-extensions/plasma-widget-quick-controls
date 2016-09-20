import QtQuick 2.2
import QtQuick.Layouts 1.2

import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.appearance 1.0 as Appearance

RowLayout {
    spacing: 12

    Connections {
        target: enabledConnections

        onWirelessEnabledChanged: {
            wirelessSwitch.checked = wirelessSwitch.enabled && enabled
        }

        onWirelessHwEnabledChanged: {
            wirelessSwitch.enabled = enabled && availableNetworkDevices.wirelessDeviceAvailable && !airplaneModeSwitch.airplaneModeEnabled
        }
    }


    PlasmaComponents.ToolButton {
        id: bluetoothSwitch
        Layout.alignment: Qt.AlignHCenter
        iconSource: "network-bluetooth"

        onClicked: {
            checked = !checked
        }
    }

    PlasmaComponents.ToolButton {
        id: darkModeSwitch
        Layout.alignment: Qt.AlignHCenter
        iconSource: "weather-clear-night"

        property var darkModeIndex : -1;
        property var previousIndex : -1;
        enabled: darkModeIndex  != -1
        checked: Appearance.LookAndFeel.current == darkModeIndex
        onClicked: {
            if (checked)
                Appearance.LookAndFeel.current = previousIndex
            else {
                previousIndex = Appearance.LookAndFeel.current
                Appearance.LookAndFeel.current  = darkModeIndex
            }
        }

        Repeater {
            model: Appearance.LookAndFeel

            Component {
                Item {
                    Component.onCompleted: {
                        if (name == "Breeze Dark") {
                            darkModeSwitch.darkModeIndex = index;
                        }
                    }
                }
            }
        }
    }

    PlasmaComponents.ToolButton {
        id: wirelessSwitch
        Layout.alignment: Qt.AlignHCenter
        iconSource: "network-wireless"

        onClicked: {
            checked = !checked
            networkHandler.enableWireless(checked);
        }
    }

    PlasmaComponents.ToolButton {
        id: airplaneModeSwitch
        property bool airplaneModeEnabled: false

        Layout.alignment: Qt.AlignHCenter
        checked: airplaneModeEnabled
        iconSource: "airplane-mode-symbolic"

        onClicked: {
            airplaneModeEnabled = !airplaneModeEnabled;
            wirelessSwitch.enabled = !airplaneModeEnabled;

            networkHandler.enableAirplaneMode(checked);
        }
    }
}
