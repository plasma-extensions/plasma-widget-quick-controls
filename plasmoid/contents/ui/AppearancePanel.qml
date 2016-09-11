import QtQuick 2.2
import QtQuick.Layouts 1.2

import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.plasma.appearance 1.0

FocusScope {
    height: childrenRect.height
    LookAndFeel {
        id: lookAndFeel
    }
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

        PlasmaComponents.Label {
            id: appearanceLabel
            Layout.fillWidth: true
            text: i18n("Select appearance")
        }

        PlasmaComponents.ComboBox {
            id: lookAndFeelComboBox
            Layout.fillWidth: true
            height: 24
            model: lookAndFeel
            textRole: "name"
            currentIndex : lookAndFeel.current;
            onCurrentIndexChanged : lookAndFeel.current = currentIndex;
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
            model: PlasmaTheme { id: plasmaTheme}
            currentIndex: plasmaTheme.current
            onCurrentIndexChanged : plasmaTheme.current = currentIndex;
            textRole: "packageNameRole"
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
