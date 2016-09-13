#include "appearance.h"

#include <QDebug>
#include <QProcess>
#include <QStandardPaths>
#include <QQuickView>
#include <QVBoxLayout>
#include <QPushButton>
#include <QMessageBox>
#include <QtQml>
#include <QQmlEngine>
#include <QQmlContext>
#include <QStandardItemModel>
#include <QtDBus/QDBusMessage>
#include <QtDBus/QDBusConnection>
#include <QtX11Extras/QX11Info>

#include <KWidgetsAddons/KMessageBox>
#include <KPluginFactory>
#include <KPluginLoader>
#include <KAboutData>
#include <KSharedConfig>
#include <KGlobalSettings>
#include <KIconLoader>

#include <KLocalizedString>
#include <Plasma/PluginLoader>
#include <klauncher_iface.h>

#include <X11/Xlib.h>
#include <X11/Xcursor/Xcursor.h>
//#ifdef HAVE_XFIXES
    #include <X11/extensions/Xfixes.h>
//#endif

#include "config-plugin.h"
#include "xcursor/xcursortheme.h"
#include "krdb.h"

Appearance::Appearance() :
    m_config(QStringLiteral("kdeglobals"))
  , m_configGroup(m_config.group("KDE"))
{
}


void Appearance::setWidgetStyle(const QString &style)
{
    if (style.isEmpty()) {
        return;
    }

    m_configGroup.writeEntry("widgetStyle", style);
    m_configGroup.sync();
    //FIXME: changing style on the fly breaks QQuickWidgets
    KGlobalSettings::self()->emitChange(KGlobalSettings::StyleChanged);
}

void Appearance::setColors(const QString &scheme, const QString &colorFile)
{
    if (scheme.isEmpty() && colorFile.isEmpty()) {
        return;
    }
    KConfigGroup configGroup(&m_config, "General");
    configGroup.writeEntry("ColorScheme", scheme);
    configGroup.sync();

    KSharedConfigPtr conf = KSharedConfig::openConfig(colorFile);
    foreach (const QString &grp, conf->groupList()) {
      KConfigGroup cg(conf, grp);
      KConfigGroup cg2(&m_config, grp);
      cg.copyTo(&cg2);
  }
}

void Appearance::setIcons(const QString &theme)
{
    if (theme.isEmpty()) {
        return;
    }

    KConfigGroup cg(&m_config, "Icons");
    cg.writeEntry("Theme", theme);
    cg.sync();

    for (int i=0; i < KIconLoader::LastGroup; i++) {
        KIconLoader::emitChange(KIconLoader::Group(i));
    }
}

void Appearance::setPlasmaTheme(const QString &theme)
{
    if (theme.isEmpty()) {
        return;
    }

    KConfig config(QStringLiteral("plasmarc"));
    KConfigGroup cg(&config, "Theme");
    cg.writeEntry("name", theme);
    cg.sync();
}

void Appearance::setCursorTheme(const QString themeName)
{
    //TODO: use pieces of cursor kcm when moved to plasma-desktop
    if (themeName.isEmpty()) {
        return;
    }

    qDebug() << "Beep 5.1";

    KConfig config(QStringLiteral("kcminputrc"));
    KConfigGroup cg(&config, "Mouse");
    cg.writeEntry("cursorTheme", themeName);
    cg.sync();

    // Require the Xcursor version that shipped with X11R6.9 or greater, since
    // in previous versions the Xfixes code wasn't enabled due to a bug in the
    // build system (freedesktop bug #975).
// #if HAVE_XFIXES && XFIXES_MAJOR >= 2 && XCURSOR_LIB_VERSION >= 10105
    QDir themeDir = cursorThemeDir(themeName, 0);

    if (!themeDir.exists()) {
        return;
    }

    XCursorTheme theme(themeDir);

    if (!CursorTheme::haveXfixes()) {
        return;
    }

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

    foreach (const QString &name, names) {
        XFixesChangeCursorByName(QX11Info::display(), theme.loadCursor(name, 0), QFile::encodeName(name));
    }

/*#else
    KMessageBox::information(NULL,
                                 i18n("You have to restart KDE for cursor changes to take effect."),
                                 i18n("Cursor Settings Changed"), "CursorSettingsChanged");
#endif*/
    KGlobalSettings::self()->emitChange(KGlobalSettings::CursorChanged);
}

QDir Appearance::cursorThemeDir(const QString &theme, const int depth)
{
    // Prevent infinite recursion
    if (depth > 10) {
        return QDir();
    }

    // Search each icon theme directory for 'theme'
    foreach (const QString &baseDir, cursorSearchPaths()) {
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

const QStringList Appearance::cursorSearchPaths()
{
    if (!m_cursorSearchPaths.isEmpty())
        return m_cursorSearchPaths;

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
    m_cursorSearchPaths = path.split(':', QString::SkipEmptyParts);

    // Remove duplicates
    QMutableStringListIterator i(m_cursorSearchPaths);
    while (i.hasNext())
    {
        const QString path = i.next();
        QMutableStringListIterator j(i);
        while (j.hasNext())
            if (j.next() == path)
                j.remove();
    }

    // Expand all occurrences of ~/ to the home dir
    m_cursorSearchPaths.replaceInStrings(QRegExp(QStringLiteral("^~\\/")), QDir::home().path() + '/');
    return m_cursorSearchPaths;
}

void Appearance::setSplashScreen(const QString &theme)
{
    if (theme.isEmpty()) {
        return;
    }

    KConfig config(QStringLiteral("ksplashrc"));
    KConfigGroup cg(&config, "KSplash");
    cg.writeEntry("Theme", theme);
    //TODO: a way to set none as spash in the l&f
    cg.writeEntry("Engine", "KSplashQML");
    cg.sync();
}

void Appearance::setLockScreen(const QString &theme)
{
    if (theme.isEmpty()) {
        return;
    }

    KConfig config(QStringLiteral("kscreenlockerrc"));
    KConfigGroup cg(&config, "Greeter");
    cg.writeEntry("Theme", theme);
    cg.sync();
}

void Appearance::setWindowSwitcher(const QString &theme)
{
    if (theme.isEmpty()) {
        return;
    }

    KConfig config(QStringLiteral("kwinrc"));
    KConfigGroup cg(&config, "TabBox");
    cg.writeEntry("LayoutName", theme);
    cg.sync();
    // Reload KWin.
    QDBusMessage message = QDBusMessage::createSignal(QStringLiteral("/KWin"),
                                                      QStringLiteral("org.kde.KWin"),
                                                      QStringLiteral("reloadConfig"));
    QDBusConnection::sessionBus().send(message);
}

void Appearance::setDesktopSwitcher(const QString &theme)
{
    if (theme.isEmpty()) {
        return;
    }

    KConfig config(QStringLiteral("kwinrc"));
    KConfigGroup cg(&config, "TabBox");
    cg.writeEntry("DesktopLayout", theme);
    cg.writeEntry("DesktopListLayout", theme);
    cg.sync();
    // Reload KWin.
    QDBusMessage message = QDBusMessage::createSignal(QStringLiteral("/KWin"),
                                                      QStringLiteral("org.kde.KWin"),
                                                      QStringLiteral("reloadConfig"));
    QDBusConnection::sessionBus().send(message);
}

QList<QVariantMap> Appearance::getLookAndFeelStyles()
{
    QList<QVariantMap> styles;

    m_package = Plasma::PluginLoader::self()->loadPackage(QStringLiteral("Plasma/LookAndFeel"));
    KConfigGroup cg(KSharedConfig::openConfig(QStringLiteral("kdeglobals")), "KDE");
    const QString packageName = cg.readEntry("LookAndFeelPackage", QString());
    if (!packageName.isEmpty()) {
        m_package.setPath(packageName);
    }

    if (!m_package.metadata().isValid()) {
        return styles;
    }

    const QList<Plasma::Package> pkgs = availablePackages();
    for (const Plasma::Package &pkg : pkgs) {
        if (!pkg.metadata().isValid()) {
            continue;
        }

        QVariantMap entry;
        entry["pluginName"] = pkg.metadata().pluginName();
        entry["name"] = pkg.metadata().name();
        styles.append(entry);
    }

    return styles;
}

QString Appearance::getCurrentLookAndFeelStyle()
{
    m_package = Plasma::PluginLoader::self()->loadPackage(QStringLiteral("Plasma/LookAndFeel"));
    KConfigGroup cg(KSharedConfig::openConfig(QStringLiteral("kdeglobals")), "KDE");
    const QString packageName = cg.readEntry("LookAndFeelPackage", QString());
    if (!packageName.isEmpty()) {
        m_package.setPath(packageName);
    }

    if (!m_package.metadata().isValid()) {
        return "";
    }

    return m_package.metadata().name();
}

void Appearance::setCurrentLookAndFeelStyle(const QString &pluginName)
{
    Plasma::Package package = Plasma::PluginLoader::self()->loadPackage(QStringLiteral("Plasma/LookAndFeel"));
    package.setPath(pluginName);

    if (!package.isValid()) {
        return;
    }

    qDebug() << "Beep 1";
    m_configGroup.writeEntry("LookAndFeelPackage", pluginName);
qDebug() << "Beep 1.1";

    if (!package.filePath("defaults").isEmpty()) {
        KSharedConfigPtr conf = KSharedConfig::openConfig(package.filePath("defaults"));
        KConfigGroup cg(conf, "kdeglobals");
        cg = KConfigGroup(&cg, "KDE");


        setWidgetStyle(cg.readEntry("widgetStyle", QString()));
        qDebug() << "Beep 2";

        QString colorsFile = package.filePath("colors");
        cg = KConfigGroup(conf, "kdeglobals");
        cg = KConfigGroup(&cg, "General");
        QString colorScheme = cg.readEntry("ColorScheme", QString());

        if (!colorsFile.isEmpty()) {
            if (!colorScheme.isEmpty()) {
                setColors(colorScheme, colorsFile);
            } else {
                setColors(package.metadata().name(), colorsFile);
            }
        } else if (!colorScheme.isEmpty()) {
            colorScheme.remove('\''); // So Foo's does not become FooS
            QRegExp fixer(QStringLiteral("[\\W,.-]+(.?)"));
            int offset;
            while ((offset = fixer.indexIn(colorScheme)) >= 0) {
                colorScheme.replace(offset, fixer.matchedLength(), fixer.cap(1).toUpper());
            }
            colorScheme.replace(0, 1, colorScheme.at(0).toUpper());
            QString src = QStandardPaths::locate(QStandardPaths::GenericDataLocation, "color-schemes/" +  colorScheme + ".colors");
            setColors(colorScheme, src);
        }
        qDebug() << "Beep 3";


        cg = KConfigGroup(conf, "kdeglobals");
        cg = KConfigGroup(&cg, "Icons");
        setIcons(cg.readEntry("Theme", QString()));

        qDebug() << "Beep 4";

        cg = KConfigGroup(conf, "plasmarc");
        cg = KConfigGroup(&cg, "Theme");
        setPlasmaTheme(cg.readEntry("name", QString()));
qDebug() << "Beep 5";


        cg = KConfigGroup(conf, "kcminputrc");
        cg = KConfigGroup(&cg, "Mouse");
        setCursorTheme(cg.readEntry("cursorTheme", QString()));
qDebug() << "Beep 6";


        cg = KConfigGroup(conf, "kwinrc");
        cg = KConfigGroup(&cg, "WindowSwitcher");
        setWindowSwitcher(cg.readEntry("LayoutName", QString()));
qDebug() << "Beep 7";


        cg = KConfigGroup(conf, "kwinrc");
        cg = KConfigGroup(&cg, "DesktopSwitcher");
        setDesktopSwitcher(cg.readEntry("LayoutName", QString()));
qDebug() << "Beep 8";
    }

    //TODO: option to enable/disable apply? they don't seem required by UI design
    setSplashScreen(pluginName);
    setLockScreen(pluginName);

    m_configGroup.sync();
    runRdb(KRdbExportQtColors | KRdbExportGtkTheme | KRdbExportColors | KRdbExportQtSettings | KRdbExportXftSettings);
}

QList<Plasma::Package> Appearance::availablePackages(const QString &component)
{
    QList<Plasma::Package> packages;
    QStringList paths;
    const QStringList dataPaths = QStandardPaths::standardLocations(QStandardPaths::GenericDataLocation);

    for (const QString &path : dataPaths) {
        QDir dir(path + "/plasma/look-and-feel");
        paths << dir.entryList(QDir::AllDirs | QDir::NoDotAndDotDot);
    }

    for (const QString &path : paths) {
        Plasma::Package pkg = Plasma::PluginLoader::self()->loadPackage(QStringLiteral("Plasma/LookAndFeel"));
        pkg.setPath(path);
        pkg.setFallbackPackage(Plasma::Package());
        if (component.isEmpty() || !pkg.filePath(component.toUtf8()).isEmpty()) {
            packages << pkg;
        }
    }

    return packages;
}
