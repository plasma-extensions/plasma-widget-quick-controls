import QtQuick 2.2
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.networkmanagement 0.2 as PlasmaNM

Item {
    id: header

    height: headerLabel.height + Math.round(units.gridUnit / 4)

    PlasmaNM.EnabledConnections {
        id: enabledConnections
    }

    PlasmaComponents.Label {
        id: headerLabel

        text: i18n("Networks")
        font.weight: Font.Light
        font.pointSize: 18
        anchors.left: parent.left
        anchors.leftMargin: Math.round(units.gridUnit / 4)
        anchors.verticalCenter: parent.verticalCenter
    }

    Row {
        id: rightButtons
        spacing: units.smallSpacing

        anchors {
            right: parent.right
            rightMargin: Math.round(units.gridUnit / 2)
            top: parent.top
            bottom: parent.bottom
        }

        PlasmaComponents.ToolButton {

            width: height
            flat: true
            tooltip: i18n("Rescan wireless networks")
            visible: enabledConnections.wirelessEnabled
                     && enabledConnections.wirelessHwEnabled
                     && availableDevices.wirelessDeviceAvailable

            onClicked: {
                networkHandler.requestScan()
                refreshAnimation.restart()
            }

            PlasmaCore.SvgItem {
                anchors {
                    fill: parent
                    margins: Math.round(units.gridUnit / 3)
                }
                elementId: "view-refresh"
                svg: PlasmaCore.FrameSvg {
                    imagePath: "icons/view"
                }

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

            iconSource: "configure"
            tooltip: i18n("Configure network connections...")

            onClicked: {
                networkHandler.openEditor()
            }
        }
    }
}
