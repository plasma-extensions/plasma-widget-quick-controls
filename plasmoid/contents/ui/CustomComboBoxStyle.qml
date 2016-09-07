import QtQuick 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls.Styles 1.4

import org.kde.plasma.components 2.0 as PlasmaComponents
import QtQuick.Controls.Styles.Plasma 2.0 as Styles

Styles.ComboBoxStyle {
    property var entryText
    label: PlasmaComponents.Label {
        text: entryText
    }
}
