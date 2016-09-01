import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.kquickcontrolsaddons 2.0
import org.kde.plasma.extras 2.0 as PlasmaExtras


Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    property string displayName: i18n("Quick Controls")


    Plasmoid.toolTipMainText: displayName
    Plasmoid.toolTipSubText: ""

    Plasmoid.fullRepresentation:  FullRepresentation { anchors.fill: parent }
    Plasmoid.compactRepresentation: CompactRepresentation {}

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation

}
