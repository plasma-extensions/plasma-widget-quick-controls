import QtQuick 2.0
import QtQuick.Layouts 1.2
import org.kde.plasma.extras 2.0 as PlasmaExtras

import "Network"
import "Devices"
import "Bluetooth"
import "Sound"

Item {
    width: 300
    height: 600
    ColumnLayout {
        anchors {
            top: parent.top
            bottom: soundPanel.top
            left: parent.left
            right: parent.right
        }

        NetworksPanel {
            id: networksPanel
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: childrenRect.height
            Layout.maximumHeight: childrenRect.height

            clip: true
        }

        BluetoothPanel {
            id: bluetoothPanel
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
        }
    }

    SoundPanel {
        id: soundPanel
        anchors {
            bottom: appearancePanel.top
            left: parent.left
            right: parent.right
        }
    }

    AppearancePanel {
        id: appearancePanel
        anchors {
            bottom: controls.top
            bottomMargin: 10
            left: parent.left
            right: parent.right
        }
        clip: true
    }

    ControlsPanel {
        id: controls
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        clip: true
    }
}
