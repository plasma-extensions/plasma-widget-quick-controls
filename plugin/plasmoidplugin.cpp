
#include "plasmoidplugin.h"

#include <QtQml>
#include <QDebug>

#include "lookandfeelmodel.h"
#include "plasmathemelistmodel.h"
#include "iconsmodel.h"
#include "colorsthememodel.h"
#include "widgetstylemodel.h"
#include "cursorthememodel.h"

void PlasmoidPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("org.kde.plasma.appearance"));
    
    qmlRegisterType<LookAndFeelModel>(uri, 1, 0, "LookAndFeel");
    qmlRegisterType<PlasmaThemeListModel>(uri, 1, 0, "PlasmaTheme");
    qmlRegisterType<IconsModel>(uri, 1, 0, "IconsTheme");
    qmlRegisterType<ColorsThemeModel>(uri, 1, 0, "ColorsTheme");
    qmlRegisterType<WidgetStyleModel>(uri, 1, 0, "WidgetStyleTheme");
    qmlRegisterType<CursorThemeModel>(uri, 1, 0, "CursorTheme");
}
