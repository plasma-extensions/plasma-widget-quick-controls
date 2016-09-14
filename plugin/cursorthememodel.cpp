
#include <QStringList>
#include <QX11Info>
#include <QDir>
#include <QDebug>

#include <KLocalizedString>
#include <KGlobalSettings>
#include <KConfigGroup>
#include <KConfig>

#include <klauncher_iface.h>

#include "cursorthememodel.h"
#include "xcursor/xcursortheme.h"
#include "xcursor/cursortheme.h"
#include "krdb.h"

#include "config-X11.h"
#ifdef HAVE_X11
    #include <X11/Xlib.h>
    #include <X11/Xcursor/Xcursor.h>
#endif

#ifdef HAVE_XFIXES
#  include <X11/Xlib.h>
#  include <X11/extensions/Xfixes.h>
#endif

// Check for older version
#if !defined(XCURSOR_LIB_MAJOR) && defined(XCURSOR_MAJOR)
#  define XCURSOR_LIB_MAJOR XCURSOR_MAJOR
#  define XCURSOR_LIB_MINOR XCURSOR_MINOR
#endif

QStringList CursorThemeModel::baseDirs;

CursorThemeModel::CursorThemeModel(QObject *parent)
    : QAbstractTableModel(parent)
{
    insertThemes();
}

CursorThemeModel::~CursorThemeModel()
{
    qDeleteAll(list);
    list.clear();
}

void CursorThemeModel::refreshList()
{
    beginResetModel();
    qDeleteAll(list);
    list.clear();
    endResetModel();
    insertThemes();
}

int CursorThemeModel::current()
{
    // Get the name of the theme libXcursor currently uses
    QString currentTheme;
    if (QX11Info::isPlatformX11()) {
        currentTheme = XcursorGetTheme(QX11Info::display());
    }

    // Get the name of the theme KDE is configured to use
    KConfig c(QStringLiteral("kcminputrc"));
    KConfigGroup cg(&c, "Mouse");
    currentTheme = cg.readEntry("cursorTheme", currentTheme);


    return findIndex(currentTheme).row();
}

void CursorThemeModel::setCurrent(int current)
{
    bool result = applyCursorTheme(list.at(current), 24);
    qDebug() << "Setting cursor theme" << list.at(current)->name() << result;
}

bool CursorThemeModel::applyCursorTheme(const CursorTheme *theme, const int size)
{
    // Require the Xcursor version that shipped with X11R6.9 or greater, since
    // in previous versions the Xfixes code wasn't enabled due to a bug in the
    // build system (freedesktop bug #975).
#if HAVE_XFIXES && XFIXES_MAJOR >= 2 && XCURSOR_LIB_VERSION >= 10105
    if (!theme)
        return false;

    if (!CursorTheme::haveXfixes())
        return false;

    QByteArray themeName = QFile::encodeName(theme->name());

    // Set up the proper launch environment for newly started apps
    OrgKdeKLauncherInterface klauncher(QStringLiteral("org.kde.klauncher5"),
                                       QStringLiteral("/KLauncher"),
                                       QDBusConnection::sessionBus());
    klauncher.setLaunchEnv(QStringLiteral("XCURSOR_THEME"), themeName);

    // Update the Xcursor X resources
    runRdb(0);

    // Notify all applications that the cursor theme has changed
    KGlobalSettings::self()->emitChange(KGlobalSettings::CursorChanged);

    // Reload the standard cursors
    QStringList names;

    // Qt cursors
    names << QStringLiteral("left_ptr")       << QStringLiteral("up_arrow")      << QStringLiteral("cross")      << QStringLiteral("wait")
          << QStringLiteral("left_ptr_watch") << QStringLiteral("ibeam")         << QStringLiteral("size_ver")   << QStringLiteral("size_hor")
          << QStringLiteral("size_bdiag")     << QStringLiteral("size_fdiag")    << QStringLiteral("size_all")   << QStringLiteral("split_v")
          << QStringLiteral("split_h")        << QStringLiteral("pointing_hand") << QStringLiteral("openhand")
          << QStringLiteral("closedhand")     << QStringLiteral("forbidden")     << QStringLiteral("whats_this") << QStringLiteral("copy") << QStringLiteral("move") << QStringLiteral("link");

    // X core cursors
    names << QStringLiteral("X_cursor")            << QStringLiteral("right_ptr")           << QStringLiteral("hand1")
          << QStringLiteral("hand2")               << QStringLiteral("watch")               << QStringLiteral("xterm")
          << QStringLiteral("crosshair")           << QStringLiteral("left_ptr_watch")      << QStringLiteral("center_ptr")
          << QStringLiteral("sb_h_double_arrow")   << QStringLiteral("sb_v_double_arrow")   << QStringLiteral("fleur")
          << QStringLiteral("top_left_corner")     << QStringLiteral("top_side")            << QStringLiteral("top_right_corner")
          << QStringLiteral("right_side")          << QStringLiteral("bottom_right_corner") << QStringLiteral("bottom_side")
          << QStringLiteral("bottom_left_corner")  << QStringLiteral("left_side")           << QStringLiteral("question_arrow")
          << QStringLiteral("pirate");

    foreach (const QString &name, names)
    {
        XFixesChangeCursorByName(QX11Info::display(), theme->loadCursor(name, size), QFile::encodeName(name));
    }

    return true;
#else
    Q_UNUSED(theme)
    return false;
#endif

}

bool CursorThemeModel::applyCursorTheme(const QString &themeName, const int size)
{
    QDir themeDir= cursorThemeDir(themeName, 0);
    XCursorTheme cursorTheme(themeDir);
    return applyCursorTheme(&cursorTheme, size);
}

QVariant CursorThemeModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    // Only provide text for the headers
    if (role != Qt::DisplayRole)
        return QVariant();

    // Horizontal header labels
    if (orientation == Qt::Horizontal)
    {
        switch (section)
        {
        case NameColumn:
            return i18n("Name");

        case DescColumn:
            return i18n("Description");

        default: return QVariant();
        }
    }

    // Numbered vertical header lables
    return QString(section);
}


QVariant CursorThemeModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= list.count())
        return QVariant();

    const CursorTheme *theme = list.at(index.row());

    // Text label
    if (role == Qt::DisplayRole)
    {
        switch (index.column())
        {
        case NameColumn:
            return theme->title();

        case DescColumn:
            return theme->description();

        default: return QVariant();
        }
    }

    // Description for the first name column
    if (role == CursorTheme::DisplayDetailRole && index.column() == NameColumn)
        return theme->description();

    // Icon for the name column
    if (role == Qt::DecorationRole && index.column() == NameColumn)
        return theme->icon();

    return QVariant();
}


void CursorThemeModel::sort(int column, Qt::SortOrder order)
{
    Q_UNUSED(column);
    Q_UNUSED(order);

    // Sorting of the model isn't implemented, as the KCM currently uses
    // a sorting proxy model.
}


const CursorTheme *CursorThemeModel::theme(const QModelIndex &index)
{
    if (!index.isValid())
        return NULL;

    if (index.row() < 0 || index.row() >= list.count())
        return NULL;

    return list.at(index.row());
}

QHash<int, QByteArray> CursorThemeModel::roleNames() const
{
    QHash<int, QByteArray> roles = QAbstractItemModel::roleNames();
    roles.insert(Qt::DisplayRole, "display");
    roles.insert(Qt::DecorationRole, "decoration");
    roles.insert(NameColumn, "name");
    roles.insert(DescColumn, "description");
    return roles;
}


QModelIndex CursorThemeModel::findIndex(const QString &name)
{
    uint hash = qHash(name);

    for (int i = 0; i < list.count(); i++)
    {
        const CursorTheme *theme = list.at(i);
        if (theme->hash() == hash)
            return index(i, 0);
    }

    return QModelIndex();
}


QModelIndex CursorThemeModel::defaultIndex()
{
    return findIndex(defaultName);
}


const QStringList CursorThemeModel::searchPaths()
{
    if (!baseDirs.isEmpty())
        return baseDirs;

#if XCURSOR_LIB_MAJOR == 1 && XCURSOR_LIB_MINOR < 1
    // These are the default paths Xcursor will scan for cursor themes
    QString path("~/.icons:/usr/share/icons:/usr/share/pixmaps:/usr/X11R6/lib/X11/icons");

    // If XCURSOR_PATH is set, use that instead of the default path
    char *xcursorPath = std::getenv("XCURSOR_PATH");
    if (xcursorPath)
        path = xcursorPath;
#else
    // Get the search path from Xcursor
    QString path = XcursorLibraryPath();
#endif

    // Separate the paths
    baseDirs = path.split(':', QString::SkipEmptyParts);

    // Remove duplicates
    QMutableStringListIterator i(baseDirs);
    while (i.hasNext())
    {
        const QString path = i.next();
        QMutableStringListIterator j(i);
        while (j.hasNext())
            if (j.next() == path)
                j.remove();
    }

    // Expand all occurrences of ~/ to the home dir
    baseDirs.replaceInStrings(QRegExp(QStringLiteral("^~\\/")), QDir::home().path() + '/');
    return baseDirs;
}


bool CursorThemeModel::hasTheme(const QString &name) const
{
    const uint hash = qHash(name);

    foreach (const CursorTheme *theme, list)
        if (theme->hash() == hash)
            return true;

    return false;
}


bool CursorThemeModel::isCursorTheme(const QString &theme, const int depth)
{
    // Prevent infinite recursion
    if (depth > 10)
        return false;

    // Search each icon theme directory for 'theme'
    foreach (const QString &baseDir, searchPaths())
    {
        QDir dir(baseDir);
        if (!dir.exists() || !dir.cd(theme))
            continue;

        // If there's a cursors subdir, we'll assume this is a cursor theme
        if (dir.exists(QStringLiteral("cursors")))
            return true;

        // If the theme doesn't have an index.theme file, it can't inherit any themes.
        if (!dir.exists(QStringLiteral("index.theme")))
            continue;

        // Open the index.theme file, so we can get the list of inherited themes
        KConfig config(dir.path() + "/index.theme", KConfig::NoGlobals);
        KConfigGroup cg(&config, "Icon Theme");

        // Recurse through the list of inherited themes, to check if one of them
        // is a cursor theme.
        QStringList inherits = cg.readEntry("Inherits", QStringList());
        foreach (const QString &inherit, inherits)
        {
            // Avoid possible DoS
            if (inherit == theme)
                continue;

            if (isCursorTheme(inherit, depth + 1))
                return true;
        }
    }

    return false;
}


bool CursorThemeModel::handleDefault(const QDir &themeDir)
{
    QFileInfo info(themeDir.path());

    // If "default" is a symlink
    if (info.isSymLink())
    {
        QFileInfo target(info.symLinkTarget());
        if (target.exists() && (target.isDir() || target.isSymLink()))
            defaultName = target.fileName();

        return true;
    }

    // If there's no cursors subdir, or if it's empty
    if (!themeDir.exists(QStringLiteral("cursors")) || QDir(themeDir.path() + "/cursors")
            .entryList(QDir::Files | QDir::NoDotAndDotDot ).isEmpty())
    {
        if (themeDir.exists(QStringLiteral("index.theme")))
        {
            XCursorTheme theme(themeDir);
            if (!theme.inherits().isEmpty())
                defaultName = theme.inherits().at(0);
        }
        return true;
    }

    defaultName = QStringLiteral("default");
    return false;
}


void CursorThemeModel::processThemeDir(const QDir &themeDir)
{
    bool haveCursors = themeDir.exists(QStringLiteral("cursors"));

    // Special case handling of "default", since it's usually either a
    // symlink to another theme, or an empty theme that inherits another
    // theme.
    if (defaultName.isNull() && themeDir.dirName() == QLatin1String("default"))
    {
        if (handleDefault(themeDir))
            return;
    }

    // If the directory doesn't have a cursors subdir and lacks an
    // index.theme file it can't be a cursor theme.
    if (!themeDir.exists(QStringLiteral("index.theme")) && !haveCursors)
        return;

    static bool isX11 = QX11Info::isPlatformX11();
    if (!isX11) {
        // TODO: implement Wayland Cursor Theme support
        return;
    }
    // Create a cursor theme object for the theme dir
    XCursorTheme *theme = new XCursorTheme(themeDir);

    // Skip this theme if it's hidden.
    if (theme->isHidden()) {
        delete theme;
        return;
    }

    // If there's no cursors subdirectory we'll do a recursive scan
    // to check if the theme inherits a theme with one.
    if (!haveCursors)
    {
        bool foundCursorTheme = false;

        foreach (const QString &name, theme->inherits())
            if ((foundCursorTheme = isCursorTheme(name)))
                break;

        if (!foundCursorTheme) {
            delete theme;
            return;
        }
    }

    // Append the theme to the list
    beginInsertRows(QModelIndex(), list.size(), list.size());
    list.append(theme);
    endInsertRows();
}


void CursorThemeModel::insertThemes()
{
    // Scan each base dir for Xcursor themes and add them to the list.
    foreach (const QString &baseDir, searchPaths())
    {
        QDir dir(baseDir);
        if (!dir.exists())
            continue;

        // Process each subdir in the directory
        foreach (const QString &name, dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot))
        {
            // Don't process the theme if a theme with the same name already exists
            // in the list. Xcursor will pick the first one it finds in that case,
            // and since we use the same search order, the one Xcursor picks should
            // be the one already in the list.
            if (hasTheme(name) || !dir.cd(name))
                continue;

            processThemeDir(dir);
            dir.cdUp(); // Return to the base dir
        }
    }

    // The theme Xcursor will end up using if no theme is configured
    if (defaultName.isNull() || !hasTheme(defaultName))
        defaultName = QStringLiteral("KDE_Classic");
}


bool CursorThemeModel::addTheme(const QDir &dir)
{
    XCursorTheme *theme = new XCursorTheme(dir);

    // Don't add the theme to the list if it's hidden
    if (theme->isHidden()) {
        delete theme;
        return false;
    }

    // ### If the theme is hidden, the user will probably find it strange that it
    //     doesn't appear in the list view. There also won't be a way for the user
    //     to delete the theme using the KCM. Perhaps a warning about this should
    //     be issued, and the user be given a chance to undo the installation.

    // If an item with the same name already exists in the list,
    // we'll remove it before inserting the new one.
    for (int i = 0; i < list.count(); i++)
    {
        if (list.at(i)->hash() == theme->hash()) {
            removeTheme(index(i, 0));
            break;
        }
    }

    // Append the theme to the list
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    list.append(theme);
    endInsertRows();

    return true;
}


void CursorThemeModel::removeTheme(const QModelIndex &index)
{
    if (!index.isValid())
        return;

    beginRemoveRows(QModelIndex(), index.row(), index.row());
    delete list.takeAt(index.row());
    endRemoveRows();
}

QDir CursorThemeModel::cursorThemeDir(const QString &theme, const int depth)
{
    // Prevent infinite recursion
    if (depth > 10) {
        return QDir();
    }

    // Search each icon theme directory for 'theme'
    foreach (const QString &baseDir, searchPaths()) {
        QDir dir(baseDir);
        if (!dir.exists() || !dir.cd(theme)) {
            continue;
        }

        // If there's a cursors subdir, we'll assume this is a cursor theme
        if (dir.exists(QStringLiteral("cursors"))) {
            return dir;
        }

        // If the theme doesn't have an index.theme file, it can't inherit any themes.
        if (!dir.exists(QStringLiteral("index.theme"))) {
            continue;
        }

        // Open the index.theme file, so we can get the list of inherited themes
        KConfig config(dir.path() + "/index.theme", KConfig::NoGlobals);
        KConfigGroup cg(&config, "Icon Theme");

        // Recurse through the list of inherited themes, to check if one of them
        // is a cursor theme.
        QStringList inherits = cg.readEntry("Inherits", QStringList());
        foreach (const QString &inherit, inherits) {
            // Avoid possible DoS
            if (inherit == theme) {
                continue;
            }

            if (cursorThemeDir(inherit, depth + 1).exists()) {
                return dir;
            }
        }
    }

    return QDir();
}
int CursorThemeModel::rowCount(const QModelIndex &) const
{
    return list.count();
}

int CursorThemeModel::columnCount(const QModelIndex &) const
{
    return 2;
}
