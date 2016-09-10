
#include "plasmoidplugin.h"

#include <QtQml>
#include <QDebug>

#include "lookandfeelmodel.h"

void PlasmoidPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("org.kde.plasma.appearance"));
    
    qmlRegisterType<LookAndFeelModel>(uri, 1, 0, "LookAndFeel");
}
