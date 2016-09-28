cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

set(QT_MIN_VERSION "5.4.0")
set(KF5_MIN_VERSION "5.0.0")

find_package(ECM 0.0.11 REQUIRED NO_MODULE)

set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings)

find_package(Qt5 ${REQUIRED_QT_VERSION} CONFIG REQUIRED Core Quick DBus X11Extras)
find_package(KF5 ${KF5_MIN_VERSION} REQUIRED COMPONENTS Plasma PlasmaQuick WindowSystem KDELibs4Support WidgetsAddons DBusAddons)
find_package(KF5Declarative)

find_package(X11)
set_package_properties(X11 PROPERTIES DESCRIPTION "X11 libraries"
                        URL "http://www.x.org"
                        TYPE REQUIRED
                        PURPOSE "Required for building the X11 based workspace"
                      )

plasma_install_package(plasmoid org.plasma-light.quick-controls)

install( DIRECTORY image/breeze DESTINATION ${ICON_INSTALL_DIR})

file(GLOB_RECURSE PLASMOID_SRCS "plasmoid/*")
add_custom_target(DUMMY_FILE_TRACKER_FOR_QTCREATOR SOURCES ${PLASMOID_SRCS})

add_subdirectory(plugin)
add_subdirectory(translations)
