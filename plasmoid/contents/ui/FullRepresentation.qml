import QtQuick 2.0
import QtQuick.Layouts 1.2

ColumnLayout {
    Flickable {


          ColumnLayout {
              NetworksPanel {}
              BluetoothPanel {}
              DevicesPanel {}
          }
    }
    AppearancePanel {
    }

    ControlsPanel {
        id : controls
        Layout.fillWidth: true
    }
}
