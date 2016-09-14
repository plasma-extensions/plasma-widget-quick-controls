import QtQuick 2.0
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 2.0 as PlasmaComponents


import org.kde.plasma.networkmanagement 0.2 as PlasmaNM

Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    property string displayName: i18n("Quick Controls")


    Plasmoid.toolTipMainText: displayName
    Plasmoid.toolTipSubText: ""

    // Plasmoid.fullRepresentation:  FullRepresentation { anchors.fill: parent }
    Plasmoid.compactRepresentation: CompactRepresentation {}

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation


    PlasmaNM.NetworkStatus {
        id: networkStatus
    }

    PlasmaNM.ConnectionIcon {
        id: connectionIconProvider
    }

    PlasmaNM.Handler {
        id: networkHandler
    }

    PlasmaNM.AvailableDevices {
        id: availableNetworkDevices
    }

    PlasmaNM.EnabledConnections {
        id: enabledConnections
    }

}
