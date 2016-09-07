import QtQuick 2.2
import QtQuick.Layouts 1.2

import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.networkmanagement 0.2 as PlasmaNM

FocusScope {
    PlasmaNM.AvailableDevices {
        id: availableDevices
    }

    PlasmaNM.NetworkModel {
        id: connectionModel
    }

    PlasmaNM.AppletProxyModel {
        id: appletProxyModel

        sourceModel: connectionModel
    }

    Header {
        id: header
        text: "Networks"
    }
    PlasmaExtras.ScrollArea {
        id: scrollView
        anchors {
            top: header.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        ListView {
            id: connectionView

            property bool availableConnectionsVisible: false
            property int currentVisibleButtonIndex: -1

            anchors.fill: parent
            clip: true
            model: appletProxyModel
            currentIndex: -1
            boundsBehavior: Flickable.StopAtBounds
            delegate: ConnectionItem {
            }
        }
    }
}
