
#include "plasmoidplugin.h"

#include <QtQml>
#include <QDebug>

#include "lookandfeelmodel.h"
#include "plasmathemelistmodel.h"

void PlasmoidPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("org.kde.plasma.appearance"));
    
    qmlRegisterType<LookAndFeelModel>(uri, 1, 0, "LookAndFeel");
    qmlRegisterType<PlasmaThemeListModel>(uri, 1, 0, "PlasmaTheme");
}
