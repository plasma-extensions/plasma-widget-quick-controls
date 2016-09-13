#include "widgetstylemodel.h"

#include <QModelIndex>
#include <QStandardPaths>
#include <QDebug>

#include <Plasma/PluginLoader>

#include <KGlobal>
#include <QStandardItem>
#include <KSharedConfig>
#include <KIconTheme>
#include <KIconLoader>
#include <KStandardDirs>
#include <KSharedDataCache>
#include <KGlobalSettings>
#include <KBuildSycocaProgressDialog>

WidgetStyleModel::WidgetStyleModel(QObject *parent) :
    QAbstractListModel(parent)
{

    QStringList dirs = QStandardPaths::locateAll(QStandardPaths::GenericDataLocation, "kstyle/themes", QStandardPaths::LocateDirectory);

    QStringList list;
    for (const QString &dir: dirs) {
         const QStringList fileNames = QDir(dir).entryList(QStringList() << QStringLiteral("*.themerc"));
         for (const QString &file: fileNames) {
             list.append(dir + '/' + file);
         }
     }

    qDebug() << list;
    for (QString theme: list) {
        KConfig config(theme, KConfig::SimpleConfig);
        if ( !(config.hasGroup("KDE") && config.hasGroup("Misc")) )
            continue;

        KConfigGroup configGroup = config.group("KDE");

        QString strWidgetStyle = configGroup.readEntry("WidgetStyle");
        if (strWidgetStyle.isNull())
            continue;

        // We have a widgetstyle, so lets read the i18n entries for it...
        QVariantMap entry;
        configGroup = config.group("Misc");
        entry["name"] = configGroup.readEntry("Name");

        qDebug() << entry;
        // Check if this style should be shown
        configGroup = config.group("Desktop Entry");
        bool hidden = configGroup.readEntry("Hidden", false);

        if (!hidden)
            entries.append(entry);
    }
    connect(KGlobalSettings::self(), &KGlobalSettings::settingsChanged, this, &WidgetStyleModel::currentChanged);
}

int WidgetStyleModel::current() {
    KConfig config( QStringLiteral("kdeglobals"), KConfig::FullConfig );
    KConfigGroup configGroup = config.group( "KDE" );
    const QString currentStyle(configGroup.readEntry( "widgetStyle", ""));
    for (int i = 0; i < entries.length(); i++)
        if (entries[i]["name"] == currentStyle)
            return i;

    return -1;
}

void WidgetStyleModel::setCurrent(int current) {
    if (current < 0 || current > entries.size())
        return;
    QString style = entries[current]["name"].toString();

    // qDebug() << "Setting style " << style;
    KConfig m_config(QStringLiteral("kdeglobals"));
    KConfigGroup m_configGroup(m_config.group("KDE"));
    m_configGroup.writeEntry("widgetStyle", style);
    m_configGroup.sync();
    //FIXME: changing style on the fly breaks QQuickWidgets
    KGlobalSettings::self()->emitChange(KGlobalSettings::StyleChanged);
}


QHash< int, QByteArray > WidgetStyleModel::roleNames() const {
    QHash<int, QByteArray> roles = QAbstractItemModel::roleNames();
    roles.insert(Qt::DisplayRole, "display");
    roles.insert(Qt::DecorationRole, "decoration");
    roles.insert(Name, "name");
    return roles;
}

int WidgetStyleModel::rowCount(const QModelIndex&) const {
    return entries.size();
}

 QVariant WidgetStyleModel::data(const QModelIndex& index, int role) const {
     if (!index.isValid() || index.parent().isValid() ||
         index.column() > 0 || index.row() < 0 || index.row() >= entries.size()) {
         // index requested must be valid, but we have no child items!
         return QVariant();
     }

     switch(role) {
         case Qt::DisplayRole:
         case Name:
             return entries.at(index.row())["name"];
     }
     return QVariant();
 }
