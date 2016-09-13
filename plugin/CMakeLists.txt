configure_file (config-plugin.h.cmake ${CMAKE_CURRENT_BINARY_DIR}/config-plugin.h )

set(plasmoidplugin_SRCS
    plasmoidplugin.cpp
    lookandfeelmodel.cpp
    plasmathemelistmodel.cpp
    widgetstylemodel.cpp
    iconsmodel.cpp
    colorsthememodel.cpp
    appearance.cpp

    krdb.cpp
    xcursor/cursortheme.cpp
    xcursor/xcursortheme.cpp

    qmldir
    )

set(klauncher_xml ${KINIT_DBUS_INTERFACES_DIR}/kf5_org.kde.KLauncher.xml)
qt5_add_dbus_interface(plasmoidplugin_SRCS ${klauncher_xml} klauncher_iface)

add_library(plasmoidplugin SHARED ${plasmoidplugin_SRCS})

target_include_directories(plasmoidplugin PUBLIC ${LIBVLC_INCLUDE_DIR} )
target_link_libraries(plasmoidplugin
    Qt5::Widgets
    Qt5::Quick
    Qt5::DBus

    KF5::Plasma
    KF5::QuickAddons
    KF5::WidgetsAddons
    KF5::KIOWidgets
    KF5::CoreAddons
    KF5::I18n
    KF5::PlasmaQuick
    KF5::KDELibs4Support
    KF5::Declarative
    KF5::QuickAddons

    ${X11_LIBRARIES}
)
if(X11_FOUND)
    target_link_libraries(plasmoidplugin Qt5::X11Extras)
endif()
if (X11_Xcursor_FOUND)
   target_link_libraries(plasmoidplugin ${X11_Xcursor_LIB})
endif ()
if (X11_Xfixes_FOUND)
   target_link_libraries(plasmoidplugin ${X11_Xfixes_LIB})
endif ()

install(TARGETS plasmoidplugin DESTINATION ${QML_INSTALL_DIR}/org/kde/plasma/appearance)

install(FILES qmldir DESTINATION ${QML_INSTALL_DIR}/org/kde/plasma/appearance)
