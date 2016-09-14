/*
 * Copyright © 2005-2007 Fredrik Höglund <fredrik@kde.org>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License version 2 or at your option version 3 as published
 * by the Free Software Foundation.
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

#ifndef THEMEMODEL_H
#define THEMEMODEL_H

#include <QAbstractTableModel>
#include <QStringList>

class QDir;
class CursorTheme;

// The two TableView/TreeView columns provided by the model
enum Columns { NameColumn = 0, DescColumn };


/**
 * The CursorThemeModel class provides a model for all locally installed
 * Xcursor themes, and the KDE/Qt legacy bitmap theme.
 *
 * This class automatically scans the locations in the file system from
 * which Xcursor loads cursors, and creates an internal list of all
 * available cursor themes.
 *
 * The model provides this theme list to item views in the form of a list
 * of rows with two columns; the first column has the theme's descriptive
 * name and its sample cursor as its icon, and the second column contains
 * the theme's description.
 *
 * Additional Xcursor themes can be added to a model after it's been
 * created, by calling addTheme(), which takes QDir as a parameter,
 * with the themes location. The intention is for this function to be
 * called when a new Xcursor theme has been installed, after the model
 * was instantiated.
 *
 * The KDE legacy theme is a read-only entry, with the descriptive name
 * "KDE Classic", and the internal name "#kde_legacy#".
 *
 * Calling defaultIndex() will return the index of the theme Xcursor
 * will use if the user hasn't explicitly configured a cursor theme.
 */
class CursorThemeModel : public QAbstractTableModel
{
    Q_OBJECT
    Q_PROPERTY(int current READ current WRITE setCurrent NOTIFY currentChanged)
    public:
        CursorThemeModel(QObject *parent = 0);
        ~CursorThemeModel();
        int columnCount(const QModelIndex &parent = QModelIndex()) const Q_DECL_OVERRIDE;
        int rowCount(const QModelIndex &parent = QModelIndex()) const Q_DECL_OVERRIDE;
        QVariant headerData(int section, Qt::Orientation orientation, int role) const;
        QVariant data(const QModelIndex &index, int role) const;
        void sort(int column, Qt::SortOrder order = Qt::AscendingOrder);

        /// Returns the CursorTheme at @p index.
        const CursorTheme *theme(const QModelIndex &index);

        QHash< int, QByteArray > roleNames() const Q_DECL_OVERRIDE;
        /// Returns the index for the CursorTheme with the internal name @p name,
        /// or an invalid index if no matching theme can be found.
        QModelIndex findIndex(const QString &name);

        /// Returns the index for the default theme.
        QModelIndex defaultIndex();

        /// Adds the theme in @p dir, and returns @a true if successful or @a false otherwise.
        bool addTheme(const QDir &dir);
        void removeTheme(const QModelIndex &index);

        /// Returns the list of base dirs Xcursor looks for themes in.
        static const QStringList searchPaths();

        /// Refresh the list of themes by checking what's on disk.
        void refreshList();

        int current();
        void setCurrent(int current);

        static bool applyCursorTheme(const CursorTheme *theme, const int size);
        static bool applyCursorTheme(const QString &themeName, const int size);
    signals:
        void currentChanged();

    private:
        bool handleDefault(const QDir &dir);
        void processThemeDir(const QDir &dir);
        void insertThemes();
        bool hasTheme(const QString &theme) const;
        bool isCursorTheme(const QString &theme, const int depth = 0);

    private:
        QList<CursorTheme*> list;
        static QStringList baseDirs;
        QString defaultName;

        static QDir cursorThemeDir(const QString &theme, const int depth);
};


#endif // THEMEMODEL_H
