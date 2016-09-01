import QtQuick 2.2
import QtQuick.Layouts 1.2

import org.kde.plasma.components 2.0 as PlasmaComponents


RowLayout {
    spacing: 12
    PlasmaComponents.ToolButton {
        id: bluetooth
        Layout.alignment: Qt.AlignHCenter
        iconSource: "network-bluetooth"

        onClicked: {
            checked = !checked
        }
    }

    PlasmaComponents.ToolButton {
        id: darkMode
        Layout.alignment: Qt.AlignHCenter
        iconSource: "dark-mode-symbolic"

        onClicked: {
            checked = !checked
        }
    }

    PlasmaComponents.ToolButton {
        id: network
        Layout.alignment: Qt.AlignHCenter
        iconSource: "network-wireless"

        onClicked: {
            checked = !checked
        }
    }

    PlasmaComponents.ToolButton {
        id: airplaneMode
        Layout.alignment: Qt.AlignHCenter
        iconSource: "airplane-mode-symbolic"

        onClicked: {
            checked = !checked
        }
    }
}
