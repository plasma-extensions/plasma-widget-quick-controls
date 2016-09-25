import QtQuick 2.2
import QtQuick.Layouts 1.2

import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.plasma.appearance 1.0 as Appearance

FocusScope {
    height: childrenRect.height
    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right

        PlasmaComponents.Label {
            id: appearanceLabel
            Layout.fillWidth: true
            Layout.bottomMargin: 4
            text: i18n("Select appearance")
            font.pointSize: 12
        }

        PlasmaComponents.ComboBox {
            id: lookAndFeelComboBox
            Layout.fillWidth: true
            Layout.bottomMargin: 4
            height: 24
            model: Appearance.LookAndFeel
            textRole: "name"
            currentIndex : Appearance.LookAndFeel.current;
            onCurrentIndexChanged : {
                if (Appearance.LookAndFeel.current  !== currentIndex)
                    Appearance.LookAndFeel.current = currentIndex
            }

            style: CustomComboBoxStyle {
                entryText: i18n("Default Look and Feel")
            }

        }

        PlasmaComponents.CheckBox {
            id: showExtraSettingsCheckBox
            Layout.fillWidth: true
            Layout.bottomMargin: 10
            height: 24

            text: i18n("Show extra settings")
            checked: false
        }

        PlasmaComponents.ComboBox {
            id: plasmaThemeComboBox
            height: 28
            Layout.fillWidth: true
            model: Appearance.PlasmaTheme
            currentIndex: Appearance.PlasmaTheme.current
            onCurrentIndexChanged : {
                if (Appearance.PlasmaTheme.current  !== currentIndex)
                    Appearance.PlasmaTheme.current = currentIndex
            }

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
            model: Appearance.IconsTheme
            currentIndex: Appearance.IconsTheme.current
            onCurrentIndexChanged : {
                if (Appearance.IconsTheme.current  !== currentIndex)
                    Appearance.IconsTheme.current = currentIndex
            }
            textRole: "name"
            visible: showExtraSettingsCheckBox.checked
            style: CustomComboBoxStyle {
                entryText: i18n("Change Icon theme")
            }
        }

        PlasmaComponents.ComboBox {
            id: colorThemeComboBox
            height: 28
            Layout.fillWidth: true
            model: Appearance.ColorsTheme
            currentIndex: Appearance.ColorsTheme.current
            onCurrentIndexChanged : {
                if (Appearance.ColorsTheme.current  !== currentIndex)
                    Appearance.ColorsTheme.current = currentIndex
            }
            textRole: "name"

            visible: showExtraSettingsCheckBox.checked
            style: CustomComboBoxStyle {
                entryText: i18n("Change Color theme")
            }
        }

        PlasmaComponents.ComboBox {
            id: widgetsThemeComboBox
            height: 28
            Layout.fillWidth: true
            model: Appearance.WidgetStyleTheme
            currentIndex: Appearance.WidgetStyleTheme.current
            onCurrentIndexChanged : {
                if (Appearance.WidgetStyleTheme.current  !== currentIndex)
                    Appearance.WidgetStyleTheme.current = currentIndex
            }
            textRole: "name"
            visible: showExtraSettingsCheckBox.checked
            style: CustomComboBoxStyle {
                entryText: i18n("Change Widget theme")
            }
        }

        PlasmaComponents.ComboBox {
            id: cursorThemeComboBox
            height: 28
            Layout.fillWidth: true
            model: Appearance.CursorTheme
            currentIndex: Appearance.CursorTheme.current
            onCurrentIndexChanged : {
                if (Appearance.CursorTheme.current  !== currentIndex)
                    Appearance.CursorTheme.current = currentIndex
            }
            textRole: "name"
            visible: showExtraSettingsCheckBox.checked
            style: CustomComboBoxStyle {
                entryText: i18n("Change Mouse Cursor theme")
            }
        }
    }

    NumberAnimation on height {target: parent; duration: 300; easing.type: Easing.OutQuad}
    clip: true
}
