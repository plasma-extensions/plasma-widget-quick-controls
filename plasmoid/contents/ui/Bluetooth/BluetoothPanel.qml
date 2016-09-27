/*
    Copyright 2013-2014 Jan Grulich <jgrulich@redhat.com>
    Copyright 2014-2015 David Rosca <nowrep@gmail.com>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) version 3, or any
    later version accepted by the membership of KDE e.V. (or its
    successor approved by the membership of KDE e.V.), which shall
    act as a proxy defined in Section 6 of version 3 of the license.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.2

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.bluezqt 1.0 as BluezQt
import org.kde.plasma.private.bluetooth 1.0 as PlasmaBt

FocusScope {
    focus: true

    PlasmaBt.DevicesProxyModel {
        id: devicesModel
        sourceModel: BluezQt.DevicesModel { }
    }

    Header {
        id: toolbar

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
    }

    PlasmaExtras.Heading {
        id: noAdaptersHeading
        level: 3
        opacity: 0.6
        text: i18n("No Adapters Available")

        anchors {
            top: toolbar.bottom
            left: parent.left
        }
    }

    PlasmaExtras.ScrollArea {
        id: scrollView
        visible: toolbar.visible

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            top: toolbar.bottom
        }

        Item {
            id: noDevicesView
            anchors.fill: parent

            PlasmaExtras.Heading {
                id: noDevicesHeading
                level: 3
                opacity: 0.6
                text: i18n("No Devices Found")

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: addDeviceButton.top
                    bottomMargin: units.smallSpacing
                }
            }

            PlasmaComponents.Button {
                id: addDeviceButton
                text: i18n("Add New Device")
                iconSource: "list-add"

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                }

                onClicked: {
                    PlasmaBt.LaunchApp.runCommand("bluedevil-wizard");
                }
            }
        }

        ListView {
            id: devicesView
            anchors.fill: parent
            clip: true
            model: devicesModel
            currentIndex: -1
            enabled: btManager.bluetoothOperational
            boundsBehavior: Flickable.StopAtBounds
            delegate: DeviceItem { }
        }
    }

    states: [
        State {
            name: "BlockedState"
            when: btManager.bluetoothBlocked
        },
        State {
            name: "DevicesState"
            when: btManager.devices.length
        },
        State {
            name: "NoDevicesState"
            when: btManager.adapters.length && !btManager.devices.length
        },
        State {
            name: "NoAdaptersState"
            when: !btManager.adapters.length
        }
    ]

    onStateChanged: {
        noAdaptersHeading.visible = (state == "NoAdaptersState");
        noDevicesView.visible = (state == "NoDevicesState");
        devicesView.visible = (state == "DevicesState");
    }

    Component.onCompleted: {
        btManager.deviceAdded.connect(updateStatus);
        btManager.deviceRemoved.connect(updateStatus);
        btManager.deviceChanged.connect(updateStatus);
        btManager.bluetoothBlockedChanged.connect(updateStatus);
        btManager.bluetoothOperationalChanged.connect(updateStatus);

        updateStatus();
    }

    function updateStatus()
    {
        var connectedDevices = [];

        for (var i = 0; i < btManager.devices.length; ++i) {
            var device = btManager.devices[i];
            if (device.connected) {
                connectedDevices.push(device);
            }
        }

        var text = "";
        var bullet = "\u2022";

        if (btManager.bluetoothBlocked) {
            text = i18n("Bluetooth is disabled");
        } else if (!btManager.bluetoothOperational) {
            if (!btManager.adapters.length) {
                text = i18n("No adapters available");
            } else {
                text = i18n("Bluetooth is offline");
            }
        } else if (connectedDevices.length) {
            text = i18ncp("Number of connected devices", "%1 connected device", "%1 connected devices", connectedDevices.length);
            for (var i = 0; i < connectedDevices.length; ++i) {
                var device = connectedDevices[i];
                text += "\n %1 %2".arg(bullet).arg(device.name);
            }
        } else {
            text = i18n("No connected devices");
        }

        deviceConnected = connectedDevices.length;
    }
}
