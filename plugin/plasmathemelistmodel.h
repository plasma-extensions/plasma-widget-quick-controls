/*
 * ThemeListModel
 * Copyright (C) 2002 Karol Szwed <gallium@kde.org>
 * Copyright (C) 2002 Daniel Molkentin <molkentin@kde.org>
 * Copyright (C) 2007 Urs Wolfer <uwolfer @ kde.org>
 * Copyright (C) 2009 by Davide Bettio <davide.bettio@kdemail.net>

 * Portions Copyright (C) 2007 Paolo Capriotti <p.capriotti@gmail.com>
 * Portions Copyright (C) 2007 Ivan Cukic <ivan.cukic+kde@gmail.com>
 * Portions Copyright (C) 2008 by Petri Damsten <damu@iki.fi>
 * Portions Copyright (C) 2000 TrollTech AS.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#ifndef THEMELISTMODEL_H
#define THEMELISTMODEL_H

#include <QAbstractItemView>
#include <Plasma/Theme>

namespace Plasma
{
    class FrameSvg;
}

//Theme selector code by Andre Duffeck (modified to add package description)
class ThemeInfo
{
public:
    QString package;
    QString description;
    QString author;
    QString version;
    QString themeRoot;
};

class PlasmaThemeListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int current READ current WRITE setCurrent NOTIFY currentChanged);
public:
    enum { PackageNameRole = Qt::UserRole,
           PackageDescriptionRole = Qt::UserRole + 1,
           PackageAuthorRole = Qt::UserRole + 2,
           PackageVersionRole = Qt::UserRole + 3
         };

    PlasmaThemeListModel(QObject *parent = 0);
    virtual ~PlasmaThemeListModel();

    virtual QHash<int, QByteArray> roleNames() const;

    virtual int rowCount(const QModelIndex &parent = QModelIndex()) const;
    virtual QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    QModelIndex indexOf(const QString &path) const;
    void refresh();
    void clearThemeList();

    int current() const;
    void setCurrent(int current);
    Q_INVOKABLE QVariantMap get(int index) const;


Q_SIGNALS:
    void currentChanged();
private:
    QHash<int, QByteArray> m_roleNames;

    QMap<QString, ThemeInfo> m_themes;
    Plasma::Theme m_defaultTheme;
};


#endif
