import QtQuick 2.0
import QtQuick.Layouts 1.2

ColumnLayout {
    Flickable {
          contentWidth: image.width; contentHeight: image.height

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
