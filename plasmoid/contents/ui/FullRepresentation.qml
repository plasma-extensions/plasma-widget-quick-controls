import QtQuick 2.0
import QtQuick.Layouts 1.2
import org.kde.plasma.extras 2.0 as PlasmaExtras

import "Network"
import "Devices"

Item {
    width: 300
    height: 600
    NetworksPanel {
        id: networksPanel
        anchors {
            top: parent.top
            bottom: appearancePanel.top
            left: parent.left
            right: parent.right
        }
        clip: true
    }

    AppearancePanel {
        id: appearancePanel
        anchors {
            bottom: controls.top
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
