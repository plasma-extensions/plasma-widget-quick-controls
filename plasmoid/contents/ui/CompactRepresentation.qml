import QtQuick 2.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

PlasmaCore.IconItem {
  id: appletIcon
  property int iconSize: Math.min(parent.width, parent.height)
  width: iconSize
  height: iconSize
  source: plasmoid.icon

  anchors.fill: parent

  SidePanel {
   id: sidePanel
   FullRepresentation {}
  }

  MouseArea {
    anchors.fill: parent
    property bool wasExpanded: false
    acceptedButtons: Qt.LeftButton

    onPressed: wasExpanded = sidePanel.visible
    onClicked: if (!wasExpanded) sidePanel.display(); else sidePanel.visible = false;
  }
}
