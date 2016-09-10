#ifndef APPEARANCE_H
#define APPEARANCE_H

#include <QDir>
#include <QString>
#include <Plasma/Package>
#include <KConfig>
#include <KConfigGroup>

class Appearance
{
public:
    Appearance();

    QList<QVariantMap> getLookAndFeelStyles();
    QString getCurrentLookAndFeelStyle();
    void setCurrentLookAndFeelStyle(const QString &pluginName);

    void setWidgetStyle(const QString &style);
    void setColors(const QString &scheme, const QString &colorFile);
    void setIcons(const QString &theme);
    void setPlasmaTheme(const QString &theme);
    void setCursorTheme(const QString themeName);
    void setSplashScreen(const QString &theme);
    void setLockScreen(const QString &theme);
    void setWindowSwitcher(const QString &theme);
    void setDesktopSwitcher(const QString &theme);

private:
    QDir cursorThemeDir(const QString &theme, const int depth);
    const QStringList cursorSearchPaths();
    QList<Plasma::Package> availablePackages(const QString &component = QString());


    Plasma::Package m_package;
    KConfig m_config;
    KConfigGroup m_configGroup;
    QStringList m_cursorSearchPaths;
};

#endif // APPEARANCE_H
