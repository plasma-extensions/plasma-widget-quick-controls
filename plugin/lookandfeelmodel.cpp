#include "lookandfeelmodel.h"

#include <QModelIndex>
#include <QDebug>

#include <Plasma/PluginLoader>

#include <QStandardItem>
#include <KSharedConfig>

#include "appearance.h"

LookAndFeelModel::LookAndFeelModel(QObject *parent) :
    QAbstractListModel(parent)
{
    Appearance ap;

    entries = ap.getLookAndFeelStyles();
    QString currentStyleName = ap.getCurrentLookAndFeelStyle();


    _current = -1;
    for (int i = 0; i < entries.size() && _current == -1; i ++)
        if (entries.at(i)["name"] == currentStyleName)
            _current = i;
}

int LookAndFeelModel::current()
{
    return _current;
}

void LookAndFeelModel::setCurrent(int current)
{
    if (_current == current)
        return;

    _current = current;
    qDebug() << "Settign new Look And Feel : " << _current;
    Appearance a;
    a.setCurrentLookAndFeelStyle(entries[_current]["pluginName"].toString());
}

QHash< int, QByteArray > LookAndFeelModel::roleNames() const {
    QHash<int, QByteArray> roles = QAbstractItemModel::roleNames();
    roles.insert(Qt::DisplayRole, "display");
    roles.insert(Qt::DecorationRole, "decoration");
    roles.insert(Name, "name");
    return roles;
}

int LookAndFeelModel::rowCount(const QModelIndex&) const {
    return entries.size();
}

 QVariant LookAndFeelModel::data(const QModelIndex& index, int role) const {
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
