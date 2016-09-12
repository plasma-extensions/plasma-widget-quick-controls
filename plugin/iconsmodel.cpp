#include "iconsmodel.h"

#include <QModelIndex>
#include <QDebug>

#include <Plasma/PluginLoader>

#include <QStandardItem>
#include <KSharedConfig>
#include <KIconTheme>
#include <KIconLoader>
#include <KSharedDataCache>
#include <KBuildSycocaProgressDialog>

IconsModel::IconsModel(QObject *parent) :
    QAbstractListModel(parent)
{

    const QStringList themelist(KIconTheme::list());
    for (QString themeName : themelist) {
        KIconTheme icontheme(themeName);
        if (!icontheme.isValid()) qDebug() << "not a valid theme" << themeName;
        if (icontheme.isHidden()) continue;

        qDebug() << icontheme.name();
        qDebug() << themeName;
        QVariantMap entry;
        entry["name"] = icontheme.name();
        entry["internalName"] = themeName;

        entries.append(entry);
    }

    connect(KIconLoader::global(), &KIconLoader::iconChanged, this, &IconsModel::currentChanged);
}

int IconsModel::current()
{
    const QString currentTheme(KIconTheme::current());
    for (int i = 0; i < entries.length(); i++)
        if (entries[i]["internalName"] == currentTheme)
            return i;

    return -1;
}

void IconsModel::setCurrent(int current)
{
    KConfigGroup config(KSharedConfig::openConfig(QStringLiteral("kdeglobals"), KConfig::SimpleConfig), "Icons");
    config.writeEntry("Theme", entries.at(current)["internalName"] );
    config.sync();

    KIconTheme::reconfigure();

    KSharedDataCache::deleteCache(QStringLiteral("icon-cache"));

    for (int i=0; i<KIconLoader::LastGroup; i++) {
      KIconLoader::emitChange(KIconLoader::Group(i));
    }

    KBuildSycocaProgressDialog::rebuildKSycoca(NULL);
}


QHash< int, QByteArray > IconsModel::roleNames() const {
    QHash<int, QByteArray> roles = QAbstractItemModel::roleNames();
    roles.insert(Qt::DisplayRole, "display");
    roles.insert(Qt::DecorationRole, "decoration");
    roles.insert(Name, "name");
    roles.insert(InternalName, "internalName");
    return roles;
}

int IconsModel::rowCount(const QModelIndex&) const {
    return entries.size();
}

 QVariant IconsModel::data(const QModelIndex& index, int role) const {
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
