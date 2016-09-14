
#ifndef PLASMOIDPLUGIN_H
#define PLASMOIDPLUGIN_H

#include <QJSValue>
#include <QQmlExtensionPlugin>

class QQmlEngine;
class PlasmoidPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
    void registerTypes(const char *uri);

    static QObject *lookandfeel_singleton_provider(QQmlEngine *engine, QJSEngine *scriptEngine);
    static QObject *plasmatheme_singleton_provider(QQmlEngine *engine, QJSEngine *scriptEngine);
    static QObject *iconstheme_singleton_provider(QQmlEngine *engine, QJSEngine *scriptEngine);
    static QObject *colorstheme_singleton_provider(QQmlEngine *engine, QJSEngine *scriptEngine);
    static QObject *widgetstyle_singleton_provider(QQmlEngine *engine, QJSEngine *scriptEngine);
    static QObject *cursorstheme_singleton_provider(QQmlEngine *engine, QJSEngine *scriptEngine);
};

#endif // PLASMOIDPLUGIN_H
