/*
    Copyright 2013-2014 Jan Grulich <jgrulich@redhat.com>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) version 3, or any
    later version accepted by the membership of KDE e.V. (or its
    successor approved by the membership of KDE e.V.), which shall
    act as a proxy defined in Section 6 of version 3 of the license.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.2
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.networkmanagement 0.2 as PlasmaNM

Item {
    id: header

    height: headerLabel.height + Math.round(units.gridUnit / 2)

    PlasmaNM.EnabledConnections {
        id: enabledConnections
    }

    PlasmaComponents.Label {
        id: headerLabel

        text: i18n("Networks")
        font.pointSize: 14
        anchors.left: parent.left
        anchors.leftMargin: Math.round(units.gridUnit / 4)
        anchors.verticalCenter: parent.verticalCenter
    }

    PlasmaComponents.ToolButton {
        anchors {
            right: openEditorButton.left
            top: parent.top
            bottom: parent.bottom
        }
        width: height
        flat: true
        tooltip: i18n("Rescan wireless networks")
        visible: enabledConnections.wirelessEnabled && enabledConnections.wirelessHwEnabled && availableDevices.wirelessDeviceAvailable

        onClicked: {
            networkHandler.requestScan();
            refreshAnimation.restart();
        }

        PlasmaCore.SvgItem {
            anchors {
                fill: parent
                margins: Math.round(units.gridUnit / 3)
            }
            elementId: "view-refresh"
            svg: PlasmaCore.FrameSvg { imagePath: "icons/view" }

            RotationAnimator on rotation {
                id: refreshAnimation

                duration: 1000
                running: false
                from: 0
                to: 720
            }
        }
    }

    PlasmaComponents.ToolButton {
        id: openEditorButton

        anchors {
            right: parent.right
            rightMargin: Math.round(units.gridUnit / 2)
            top: parent.top
            bottom: parent.bottom
        }

        iconSource: "configure"
        tooltip: i18n("Configure network connections...")

        onClicked: {
            networkHandler.openEditor();
        }
    }
}
