import QtQuick 2.0
import QtQuick.Layouts 1.2
import org.kde.plasma.extras 2.0 as PlasmaExtras

import "Network"
import "Devices"

ColumnLayout {

        ColumnLayout {
            anchors.fill: parent
            NetworksPanel {
                id: networksPanel
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            BluetoothPanel {
                id: bluetoothPanel
            }
            DevicesPanel {
                id: devicesPanel
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            AppearancePanel {
            }

    }
    ControlsPanel {
        id : controls
        Layout.fillWidth: true
    }
}
