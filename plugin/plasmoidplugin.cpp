
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
    
    qmlRegisterSingletonType<LookAndFeelModel>(uri, 1, 0, "LookAndFeel", lookandfeel_singleton_provider);
    qmlRegisterSingletonType<PlasmaThemeListModel>(uri, 1, 0, "PlasmaTheme", plasmatheme_singleton_provider);
    qmlRegisterSingletonType<IconsModel>(uri, 1, 0, "IconsTheme", iconstheme_singleton_provider);
    qmlRegisterSingletonType<ColorsThemeModel>(uri, 1, 0, "ColorsTheme", colorstheme_singleton_provider);
    qmlRegisterSingletonType<WidgetStyleModel>(uri, 1, 0, "WidgetStyleTheme", widgetstyle_singleton_provider);
    qmlRegisterSingletonType<CursorThemeModel>(uri, 1, 0, "CursorTheme", cursorstheme_singleton_provider);
}

QObject *PlasmoidPlugin::lookandfeel_singleton_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    return new LookAndFeelModel();
}

QObject *PlasmoidPlugin::plasmatheme_singleton_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    return new PlasmaThemeListModel();
}

QObject *PlasmoidPlugin::iconstheme_singleton_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    return new IconsModel();
}

QObject *PlasmoidPlugin::colorstheme_singleton_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    return new ColorsThemeModel();
}

QObject *PlasmoidPlugin::widgetstyle_singleton_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    return new WidgetStyleModel();
}

QObject *PlasmoidPlugin::cursorstheme_singleton_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    return new CursorThemeModel();
}

