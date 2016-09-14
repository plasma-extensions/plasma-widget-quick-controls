#ifndef WIDGETSTYLEMODEL_H
#define WIDGETSTYLEMODEL_H

#include <QList>
#include <QHash>
#include <QVariant>
#include <QByteArray>
#include <QAbstractListModel>

#include <KConfig>
#include <KConfigGroup>
#include <Plasma/Package>
#include <KQuickAddons/ConfigModule>

class WidgetStyleModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int current READ current WRITE setCurrent NOTIFY currentChanged)

public:
    enum Roles {
        Name = Qt::UserRole + 1
    };

    explicit WidgetStyleModel(QObject *parent = 0);

    QHash< int, QByteArray > roleNames() const Q_DECL_OVERRIDE;

    int rowCount(const QModelIndex&) const Q_DECL_OVERRIDE;
    QVariant data(const QModelIndex& index, int role) const Q_DECL_OVERRIDE;

    int current();
    void setCurrent(int current);

    static bool applyWidgetStyle(const QString &style);
signals:
    void currentChanged();

private:
    int _current;
    QList<QVariantMap> entries;
};

#endif // WIDGETSTYLEMODEL_H
