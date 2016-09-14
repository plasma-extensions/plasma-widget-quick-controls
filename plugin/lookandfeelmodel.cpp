#include "lookandfeelmodel.h"

#include <QModelIndex>
#include <QDBusMessage>
#include <QDBusConnection>

#include <QDebug>

#include <Plasma/PluginLoader>

#include <QStandardItem>
#include <KSharedConfig>
#include <KPackage/Package>
#include <KPackage/PackageLoader>


#include "widgetstylemodel.h"
#include "colorsthememodel.h"
#include "iconsmodel.h"
#include "cursorthememodel.h"
#include "plasmathemelistmodel.h"

LookAndFeelModel::LookAndFeelModel(QObject *parent) :
    QAbstractListModel(parent)
{
    refresh();
}

int LookAndFeelModel::current()
{
    KPackage::Package package = KPackage::PackageLoader::self()->loadPackage(QStringLiteral("Plasma/LookAndFeel"));

    KConfigGroup cg(KSharedConfig::openConfig(QStringLiteral("kdeglobals")), "KDE");
    const QString packageName = cg.readEntry("LookAndFeelPackage", QString());
    if (!packageName.isEmpty()) {
        package.setPath(packageName);
    }

    if (!package.metadata().isValid()) {
        return -1;
    }

    QString pluginId = package.metadata().pluginId();
    for (int i = 0; i < entries.size(); i ++)
        if (entries.at(i)["pluginName"] == pluginId)
            return i;

    return -1;
}

void LookAndFeelModel::setCurrent(int current)
{
    if (current < 0 || current >= entries.size())
        return;

    QString pluginId = entries[current]["pluginName"].toString();
    qDebug() << "Settign new Look And Feel : " << pluginId;


    KPackage::Package package = KPackage::PackageLoader::self()->loadPackage(QStringLiteral("Plasma/LookAndFeel"));
    package.setPath(pluginId);

    if (!package.isValid()) {
        qDebug() << "Invalid Look&Feel pluginId" << pluginId;
        return;
    }

    KConfig m_config(QStringLiteral("kdeglobals"));
    KConfigGroup m_configGroup(m_config.group("KDE"));
    m_configGroup.writeEntry("LookAndFeelPackage", pluginId);

    if (!package.filePath("defaults").isEmpty()) {
        KSharedConfigPtr conf = KSharedConfig::openConfig(package.filePath("defaults"));
        KConfigGroup cg(conf, "kdeglobals");
        cg = KConfigGroup(&cg, "KDE");


        QString widgetStyle = cg.readEntry("widgetStyle", QString());
        WidgetStyleModel::applyWidgetStyle(widgetStyle);

        QString colorsFile = package.filePath("colors");
        cg = KConfigGroup(conf, "kdeglobals");
        cg = KConfigGroup(&cg, "General");
        QString colorScheme = cg.readEntry("ColorScheme", QString());

        if (!colorsFile.isEmpty()) {
            if (!colorScheme.isEmpty()) {
                ColorsThemeModel::applyColorsScheme(colorScheme, colorsFile);
            } else {
                ColorsThemeModel::applyColorsScheme(package.metadata().name(), colorsFile);
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
            ColorsThemeModel::applyColorsScheme(colorScheme, src);
        }

        cg = KConfigGroup(conf, "kdeglobals");
        cg = KConfigGroup(&cg, "Icons");
        IconsModel::applyIconsTheme(cg.readEntry("Theme", QString()));

        cg = KConfigGroup(conf, "plasmarc");
        cg = KConfigGroup(&cg, "Theme");

        Plasma::Theme theme;
        theme.setThemeName(cg.readEntry("name", QString()));


        cg = KConfigGroup(conf, "kcminputrc");
        cg = KConfigGroup(&cg, "Mouse");
        QString cursorTheme = cg.readEntry("cursorTheme", QString());
        CursorThemeModel::applyCursorTheme(cursorTheme, 24);

        cg = KConfigGroup(conf, "kwinrc");
        cg = KConfigGroup(&cg, "WindowSwitcher");
        setWindowSwitcher(cg.readEntry("LayoutName", QString()));


        cg = KConfigGroup(conf, "kwinrc");
        cg = KConfigGroup(&cg, "DesktopSwitcher");
        setDesktopSwitcher(cg.readEntry("LayoutName", QString()));
    }

    //TODO: option to enable/disable apply? they don't seem required by UI design
    setSplashScreen(pluginId);
    setLockScreen(pluginId);

    m_configGroup.sync();
}

void LookAndFeelModel::refresh()
{
    entries.clear();

    QStringList paths;
    const QStringList dataPaths = QStandardPaths::standardLocations(QStandardPaths::GenericDataLocation);

    for (const QString &path : dataPaths) {
        QDir dir(path + "/plasma/look-and-feel");
        paths << dir.entryList(QDir::AllDirs | QDir::NoDotAndDotDot);
    }

    for (const QString &path : paths) {
        KPackage::Package pkg = KPackage::PackageLoader::self()->loadPackage(QStringLiteral("Plasma/LookAndFeel"));
        pkg.setPath(path);
        if (pkg.metadata().isValid()) {
            QVariantMap entry;
            entry["pluginName"] = pkg.metadata().pluginId();
            entry["name"] = pkg.metadata().name();
            entries.append(entry);
        }
    }
}

void LookAndFeelModel::setSplashScreen(const QString &theme)
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

void LookAndFeelModel::setLockScreen(const QString &theme)
{
    if (theme.isEmpty()) {
        return;
    }

    KConfig config(QStringLiteral("kscreenlockerrc"));
    KConfigGroup cg(&config, "Greeter");
    cg.writeEntry("Theme", theme);
    cg.sync();
}

void LookAndFeelModel::setWindowSwitcher(const QString &theme)
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

void LookAndFeelModel::setDesktopSwitcher(const QString &theme)
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
