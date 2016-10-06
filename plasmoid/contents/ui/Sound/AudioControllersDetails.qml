import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.4

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.plasma.private.volume 0.1

ColumnLayout {
    id: root
    property alias model: devicesView.model;
    property var defaultDevice: undefined;
    property int defaultDeviceIndex : -1;

    ExclusiveGroup { id: devicesGroup }

    Repeater {
        id: devicesView

        Layout.fillWidth: true
        Layout.minimumHeight: implicitHeight
        Layout.maximumHeight: implicitHeight

        delegate: ColumnLayout {
            PlasmaComponents.RadioButton {
                id: radioButton
                Layout.leftMargin: 12
                Layout.rightMargin: 8
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                Layout.fillWidth: true
                text: PulseObject.description

                exclusiveGroup: devicesGroup;

                checked: PulseObject.default;
                onClicked: PulseObject.default = true;
                onCheckedChanged: {
                    if (checked){
                        root.defaultDeviceIndex = index;
                        root.defaultDevice = PulseObject
                    }
                }
            }

            PlasmaComponents.ComboBox {
                id: portbox
                Layout.leftMargin: 12
                Layout.rightMargin: 8
                Layout.bottomMargin: 8
                Layout.fillWidth: true
                model: PulseObject.ports
                onModelChanged: currentIndex = PulseObject.activePortIndex
                textRole: "description"
                currentIndex: PulseObject.activePortIndex
                onActivated: PulseObject.activePortIndex = index
            }
        }
    }
}
