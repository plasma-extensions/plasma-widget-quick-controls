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
import org.kde.kcoreaddons 1.0 as KCoreAddons
import org.kde.kquickcontrolsaddons 2.0 as KQuickControlsAddons
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.networkmanagement 0.2 as PlasmaNM

PlasmaComponents.ListItem {
    id: connectionItem

    property bool activating: ConnectionState == PlasmaNM.Enums.Activating;
    property int  baseHeight: connectionItemBase.height
    property bool expanded: visibleDetails || visiblePasswordDialog
    property bool predictableWirelessPassword: !Uuid && Type == PlasmaNM.Enums.Wireless &&
                                               (SecurityType == PlasmaNM.Enums.StaticWep || SecurityType == PlasmaNM.Enums.WpaPsk ||
                                                SecurityType == PlasmaNM.Enums.Wpa2Psk)
    property bool showSpeed: ConnectionState == PlasmaNM.Enums.Activated &&
                             (Type == PlasmaNM.Enums.Wimax ||
                              Type == PlasmaNM.Enums.Wired ||
                              Type == PlasmaNM.Enums.Wireless ||
                              Type == PlasmaNM.Enums.Gsm ||
                              Type == PlasmaNM.Enums.Cdma)
    property bool visibleDetails: false
    property bool visiblePasswordDialog: false

    checked: connectionItem.containsMouse
    enabled: true
    height: expanded ? baseHeight + expandableComponentLoader.height + Math.round(units.gridUnit / 3) : baseHeight

    PlasmaCore.DataSource {
        id: dataSource

        property string downloadSource: "network/interfaces/" + DeviceName + "/receiver/data"
        property string uploadSource: "network/interfaces/" + DeviceName + "/transmitter/data"

        connectedSources: showSpeed && plasmoid.expanded ? [downloadSource, uploadSource] : []
        engine: "systemmonitor"
        interval: 2000
    }

    Item {
        id: connectionItemBase

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            // Reset top margin from PlasmaComponents.ListItem
            topMargin: -Math.round(units.gridUnit / 3)
        }
        height: Math.max(units.iconSizes.medium, connectionNameLabel.height + connectionStatusLabel.height) + Math.round(units.gridUnit / 2)

        PlasmaCore.SvgItem {
            id: connectionSvgIcon

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            elementId: ConnectionIcon
            height: units.iconSizes.medium; width: height
            svg: PlasmaCore.Svg {
                multipleImages: true
                imagePath: "icons/network"
                colorGroup: PlasmaCore.ColorScope.colorGroup
            }
        }

        PlasmaComponents.Label {
            id: connectionNameLabel

            anchors {
                bottom: connectionSvgIcon.verticalCenter
                left: connectionSvgIcon.right
                leftMargin: Math.round(units.gridUnit / 2)
                right: stateChangeButton.visible ? stateChangeButton.left : parent.right
            }
            height: paintedHeight
            elide: Text.ElideRight
            font.weight: ConnectionState == PlasmaNM.Enums.Activated ? Font.DemiBold : Font.Normal
            font.italic: ConnectionState == PlasmaNM.Enums.Activating ? true : false
            text: ItemUniqueName
            textFormat: Text.PlainText
        }

        PlasmaComponents.Label {
            id: connectionStatusLabel

            anchors {
                left: connectionSvgIcon.right
                leftMargin: Math.round(units.gridUnit / 2)
                right: stateChangeButton.visible ? stateChangeButton.left : parent.right
                top: connectionNameLabel.bottom
            }
            height: paintedHeight
            elide: Text.ElideRight
            font.pointSize: theme.smallestFont.pointSize
            opacity: 0.6
            text: itemText()
        }

        PlasmaComponents.BusyIndicator {
            id: connectingIndicator

            anchors {
                right: stateChangeButton.visible ? stateChangeButton.left : parent.right
                rightMargin: Math.round(units.gridUnit / 2)
                verticalCenter: connectionSvgIcon.verticalCenter
            }
            height: units.iconSizes.medium; width: height
            running: plasmoid.expanded && !stateChangeButton.visible && ConnectionState == PlasmaNM.Enums.Activating
            visible: running
        }

        PlasmaComponents.Button {
            id: stateChangeButton

            anchors {
                right: parent.right
                rightMargin: Math.round(units.gridUnit / 2)
                verticalCenter: connectionSvgIcon.verticalCenter
            }
            opacity: connectionView.currentVisibleButtonIndex == index ? 1 : 0
            visible: opacity != 0
            text: (ConnectionState == PlasmaNM.Enums.Deactivated) ? i18n("Connect") : i18n("Disconnect")

            Behavior on opacity { NumberAnimation { duration: units.shortDuration } }

            onClicked: changeState()
        }
    }


    Component {
        id: passwordDialogComponent

        Item {
            property alias password: passwordInput.text
            property alias passwordFocus: passwordInput

            height: childrenRect.height

            PlasmaCore.SvgItem {
                id: passwordSeparator

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: lineSvg.elementSize("horizontal-line").height; width: parent.width
                elementId: "horizontal-line"
                svg: PlasmaCore.Svg { id: lineSvg; imagePath: "widgets/line" }
            }

            PlasmaComponents.TextField {
                id: passwordInput

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: passwordSeparator.bottom
                    topMargin: Math.round(units.gridUnit / 3)
                }
                height: implicitHeight; width: 200
                echoMode: showPasswordCheckbox.checked ? TextInput.Normal : TextInput.Password
                placeholderText: i18n("Password...")
                validator: RegExpValidator {
                                regExp: if (SecurityType == PlasmaNM.Enums.StaticWep) {
                                            /^(?:.{5}|[0-9a-fA-F]{10}|.{13}|[0-9a-fA-F]{26}){1}$/
                                        } else {
                                            /^(?:.{8,64}){1}$/
                                        }
                                }

                onAccepted: {
                    stateChangeButton.clicked();
                }

                onAcceptableInputChanged: {
                    stateChangeButton.enabled = acceptableInput;
                }
            }

            PlasmaComponents.CheckBox {
                id: showPasswordCheckbox

                anchors {
                    left: passwordInput.left
                    right: parent.right
                    top: passwordInput.bottom
                }
                checked: false
                text: i18n("Show password")
            }

            Component.onCompleted: {
                stateChangeButton.enabled = false;
            }

            Component.onDestruction: {
                stateChangeButton.enabled = true;
            }
        }
    }

    states: [
        State {
            name: "collapsed"
            when: !(visibleDetails || visiblePasswordDialog)
            StateChangeScript { script: if (expandableComponentLoader.status == Loader.Ready) {expandableComponentLoader.sourceComponent = undefined} }
        },

        State {
            name: "expandedDetails"
            when: visibleDetails
            StateChangeScript { script: createContent() }
        },

        State {
            name: "expandedPasswordDialog"
            when: visiblePasswordDialog
            StateChangeScript { script: createContent() }
            PropertyChanges { target: stateChangeButton; opacity: 1 }
        }
    ]

    function createContent() {
        if (visibleDetails) {
            expandableComponentLoader.sourceComponent = detailsComponent;
        } else if (visiblePasswordDialog) {
            expandableComponentLoader.sourceComponent = passwordDialogComponent;
            expandableComponentLoader.item.passwordFocus.forceActiveFocus();
        }
    }

    function changeState() {
        visibleDetails = false
        if (Uuid || !predictableWirelessPassword || visiblePasswordDialog) {
            if (ConnectionState == PlasmaNM.Enums.Deactivated) {
                if (!predictableWirelessPassword && !Uuid) {
                    networkHandler.addAndActivateConnection(DevicePath, SpecificPath);
                } else if (visiblePasswordDialog) {
                    if (expandableComponentLoader.item.password != "") {
                        networkHandler.addAndActivateConnection(DevicePath, SpecificPath, expandableComponentLoader.item.password);
                        visiblePasswordDialog = false;
                    } else {
                        connectionItem.clicked();
                    }
                } else {
                    networkHandler.activateConnection(ConnectionPath, DevicePath, SpecificPath);
                }
            } else {
                networkHandler.deactivateConnection(ConnectionPath, DevicePath);
            }
        } else if (predictableWirelessPassword) {
            visiblePasswordDialog = true;
        }
    }

    function itemText() {
        if (ConnectionState == PlasmaNM.Enums.Activating) {
            if (Type == PlasmaNM.Enums.Vpn)
                return VpnState;
            else
                return DeviceState;
        } else if (ConnectionState == PlasmaNM.Enums.Deactivating) {
            if (Type == PlasmaNM.Enums.Vpn)
                return VpnState;
            else
                return DeviceState;
        } else if (ConnectionState == PlasmaNM.Enums.Deactivated) {
            var result = LastUsed;
            if (SecurityType > PlasmaNM.Enums.NoneSecurity)
                result += ", " + SecurityTypeString;
            return result;
        } else if (ConnectionState == PlasmaNM.Enums.Activated) {
            if (showSpeed && dataSource.data && dataSource.data[dataSource.downloadSource] && dataSource.data[dataSource.uploadSource]) {
                return i18n("Connected, <font color='%1'>⬇</font> %2/s, <font color='%3'>⬆</font> %4/s",
                            theme.highlightColor,
                            KCoreAddons.Format.formatByteSize(dataSource.data[dataSource.downloadSource].value * 1024 || 0),
                            cycle(theme.highlightColor, -180),
                            KCoreAddons.Format.formatByteSize(dataSource.data[dataSource.uploadSource].value * 1024 || 0));
            } else {
                return i18n("Connected");
            }
        }
    }

    /*
     * Stolen from the system monitor applet
     * from plasma-workspace/applets/systemmonitor/common/contents/ui/DoublePlotter.qml
     */
    function cycle(color, degrees) {
        var min = Math.min(color.r, Math.min(color.g, color.b));
        var max = Math.max(color.r, Math.max(color.g, color.b));
        var c = max - min;
        var h;

        if (c == 0) {
            h = 0
        } else if (max == color.r) {
            h = ((color.g - color.b) / c) % 6;
        } else if (max == color.g) {
            h = ((color.b - color.r) / c) + 2;
        } else if (max == color.b) {
            h = ((color.r - color.g) / c) + 4;
        }
        var hue = (1/6) * h + (degrees/360);
        var saturation = c / (1 - Math.abs(2 * ((max+min)/2) - 1));
        var lightness = (max + min)/3;

        return Qt.hsla(hue, saturation, lightness, 1.0);
    }

    onActivatingChanged: {
        if (ConnectionState == PlasmaNM.Enums.Activating) {
            ListView.view.positionViewAtBeginning()
        }
    }

    onClicked: {
        if (visiblePasswordDialog) {
            visiblePasswordDialog = false
        } else {
            visibleDetails = !visibleDetails
        }

        if (visibleDetails || visiblePasswordDialog) {
            ListView.view.currentIndex = index
        } else {
            ListView.view.currentIndex = -1
        }
    }

    onContainsMouseChanged: {
        if (connectionItem.containsMouse) {
            connectionView.currentVisibleButtonIndex = index
        }
    }
}
