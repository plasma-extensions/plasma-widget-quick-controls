import QtQuick 2.2
import QtQuick.Layouts 1.2

import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 2.0 as PlasmaComponents

FocusScope {
    height: childrenRect.height
    ListModel {
        id: lookAndFeelModel

        ListElement {
            name: "Breeze"
        }
        ListElement {
            name: "Breeze-Dark"
        }
        ListElement {
            name: "Oxygen"
        }
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right

        Component.onCompleted: print("content height:", height)

        PlasmaComponents.Label {
            id: appearanceLabel
            Layout.fillWidth: true
            text: i18n("Select appearance")
        }

        PlasmaComponents.ComboBox {
            Layout.fillWidth: true
            height: 24
            model: lookAndFeelModel
            style: CustomComboBoxStyle {
                entryText: i18n("Default Look and Feel")
            }
        }

        PlasmaComponents.CheckBox {
            id: showExtraSettingsCheckBox
            Layout.fillWidth: true
            height: 24

            text: i18n("Show extra settings")
            checked: false
        }

        PlasmaComponents.ComboBox {
            id: plasmaThemeComboBox
            height: 28
            Layout.fillWidth: true
            model: lookAndFeelModel
            visible: showExtraSettingsCheckBox.checked
            style: CustomComboBoxStyle {
                entryText: i18n("Change Plasma theme")
            }
        }

        PlasmaComponents.ComboBox {
            id: iconThemeComboBox
            height: 28
            Layout.fillWidth: true
            model: lookAndFeelModel
            visible: showExtraSettingsCheckBox.checked
            style: CustomComboBoxStyle {
                entryText: i18n("Change Icon theme")
            }
        }

        PlasmaComponents.ComboBox {
            id: colorThemeComboBox
            height: 28
            Layout.fillWidth: true
            model: lookAndFeelModel
            visible: showExtraSettingsCheckBox.checked
            style: CustomComboBoxStyle {
                entryText: i18n("Change Color theme")
            }
        }

        PlasmaComponents.ComboBox {
            id: widgetsThemeComboBox
            height: 28
            Layout.fillWidth: true
            model: lookAndFeelModel
            visible: showExtraSettingsCheckBox.checked
            style: CustomComboBoxStyle {
                entryText: i18n("Change Widget theme")
            }
        }

        PlasmaComponents.ComboBox {
            id: cursorThemeComboBox
            height: 28
            Layout.fillWidth: true
            model: lookAndFeelModel

            visible: showExtraSettingsCheckBox.checked
            style: CustomComboBoxStyle {
                entryText: i18n("Change Mouse Cursor theme")
            }
        }
    }

    NumberAnimation on height {target: parent; duration: 300; easing.type: Easing.OutQuad}
    clip: true
}
