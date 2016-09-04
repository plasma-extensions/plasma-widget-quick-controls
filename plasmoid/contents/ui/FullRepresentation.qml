import QtQuick 2.0
import QtQuick.Layouts 1.2

import "Network"

ColumnLayout {
    NetworksPanel {
        id: networksPanel
        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    BluetoothPanel {id: bluetoothPanel}
    DevicesPanel { id: devicesPanel}

    AppearancePanel {
    }

    ControlsPanel {
        id : controls
        Layout.fillWidth: true
    }
}
