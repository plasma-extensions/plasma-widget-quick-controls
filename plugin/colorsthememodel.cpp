#include "colorsthememodel.h"

#include <QModelIndex>
#include <QDBusMessage>
#include <QDBusConnection>
#include <QCoreApplication>
#include <QDebug>

#include <Plasma/PluginLoader>

#include <QStandardItem>
#include <KSharedConfig>
#include <KIconTheme>
#include <KIconLoader>
#include <KSharedDataCache>
#include <KBuildSycocaProgressDialog>

#include "krdb.h"

ColorsThemeModel::ColorsThemeModel(QObject *parent) :
    QAbstractListModel(parent)
{

    // add entries
    QIcon icon;

    QStringList schemeFiles;
    const QStringList schemeDirs = QStandardPaths::locateAll(QStandardPaths::GenericDataLocation, QStringLiteral("color-schemes"), QStandardPaths::LocateDirectory);
    for (const QString &dir: schemeDirs) {
        const QStringList fileNames = QDir(dir).entryList(QStringList()<<QStringLiteral("*.colors"));
        for (const QString &file: fileNames) {
            if( !schemeFiles.contains("color-schemes/"+file)) {
                schemeFiles.append("color-schemes/"+file);
            }
        }
    }
    for (QStringList::Iterator it = schemeFiles.begin(); it != schemeFiles.end(); ++it ) {
        *it = QStandardPaths::locate(QStandardPaths::GenericDataLocation, *it);
    }

    for (int i = 0; i < schemeFiles.size(); ++i)
    {
        // get the file name
        const QString filename = schemeFiles.at(i);
        const QFileInfo info(filename);

        // add the entry
        QVariantMap entry;
        KSharedConfigPtr config = KSharedConfig::openConfig(filename);
        KConfigGroup group(config, "General");
        entry["fileName"] = filename;
        entry["name"] = info.baseName();

        // qDebug() << entry;
        entries.append(entry);
    }
}

int ColorsThemeModel::current()
{
    KConfig m_config(QStringLiteral("kdeglobals"));
    KConfigGroup configGroup(&m_config, "General");
    QString name = configGroup.readEntry("ColorScheme", QString());
    for (int i = 0; i < entries.length(); i ++)
        if (entries[i]["name"] == name)
            return i;

    return -1;
}

void ColorsThemeModel::setCurrent(int current)
{
    if (current >= entries.size() || current < 0)
        return;

    KConfig m_config(QStringLiteral("kdeglobals"));
    KConfigGroup configGroup(&m_config, "General");
    configGroup.writeEntry("ColorScheme", entries[current]["name"]);
    configGroup.sync();

    KSharedConfigPtr conf = KSharedConfig::openConfig(entries[current]["fileName"].toString());
    for (const QString &grp : conf->groupList()) {
      KConfigGroup cg(conf, grp);
      KConfigGroup cg2(&m_config, grp);
      cg.copyTo(&cg2);
  }

    runRdb(KRdbExportQtColors | KRdbExportGtkTheme |  KRdbExportColors );

    QDBusMessage message = QDBusMessage::createSignal(QStringLiteral("/KGlobalSettings"), QStringLiteral("org.kde.KGlobalSettings"), QStringLiteral("notifyChange") );
    QList<QVariant> args;
    args.append(0);//previous KGlobalSettings::PaletteChanged. This is now private API in khintsettings
    args.append(0);//unused in palette changed but needed for the DBus signature
    message.setArguments(args);
    QDBusConnection::sessionBus().send(message);

    // Send signal to all kwin instances
    message =
            QDBusMessage::createSignal(QStringLiteral("/KWin"), QStringLiteral("org.kde.KWin"), QStringLiteral("reloadConfig"));
    QDBusConnection::sessionBus().send(message);

}


QHash< int, QByteArray > ColorsThemeModel::roleNames() const {
    QHash<int, QByteArray> roles = QAbstractItemModel::roleNames();
    roles.insert(Qt::DisplayRole, "display");
    roles.insert(Qt::DecorationRole, "decoration");
    roles.insert(Name, "name");
    roles.insert(FileName, "fileName");
    return roles;
}

int ColorsThemeModel::rowCount(const QModelIndex&) const {
    return entries.size();
}

 QVariant ColorsThemeModel::data(const QModelIndex& index, int role) const {
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
