import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

FocusScope {
    id: devicenotifier
    property string devicesType: "removable"
    property string expandedDevice
    property string popupIcon: "device-notifier"

    PlasmaCore.DataSource {
        id: hpSource
        engine: "hotplug"
        connectedSources: sources
        interval: 0

        onSourceAdded: {
            disconnectSource(source)
            connectSource(source)
        }
        onSourceRemoved: {
            disconnectSource(source)
        }
    }

    PlasmaCore.DataSource {
        id: sdSource
        engine: "soliddevice"
        connectedSources: hpSource.sources
        interval: plasmoid.expanded ? 5000 : 0
        property string last
        onSourceAdded: {
            disconnectSource(source)
            connectSource(source)
            last = source
            processLastDevice(true)
        }

        onSourceRemoved: {
            if (expandedDevice == source) {
                devicenotifier.currentExpanded = -1
                expandedDevice = ""
            }
            disconnectSource(source)
        }

        onDataChanged: {
            processLastDevice(true)
        }

        onNewData: {
            last = sourceName
            processLastDevice(false)
        }

        function processLastDevice(expand) {
            if (last != "") {
                if (devicesType == "all" || (devicesType == "removable"
                                             && data[last]
                                             && data[last]["Removable"] == true)
                        || (devicesType == "nonRemovable" && data[last]
                            && data[last]["Removable"] == false)) {
                    if (expand && hpSource.data[last]["added"]) {
                        expandDevice(last)
                    }
                    last = ""
                }
            }
        }
    }

    PlasmaCore.SortFilterModel {
        id: filterModel
        sourceModel: PlasmaCore.DataModel {
            dataSource: sdSource
        }
        filterRole: "Removable"
        filterRegExp: {
            var all = false
            var removable = true

            if (all == true) {
                devicesType = "all"
                return ""
            } else if (removable == true) {
                devicesType = "removable"
                return "true"
            } else {
                devicesType = "nonRemovable"
                return "false"
            }
        }
        sortRole: "Timestamp"
        sortOrder: Qt.DescendingOrder
        onCountChanged: {
            var data = filterModel.get(0)
            if (data && (data["Icon"] != undefined)) {
                plasmoid.icon = data["Icon"]
                plasmoid.toolTipMainText = i18n("Most recent device")
                plasmoid.toolTipSubText = data["Description"]
            } else {
                plasmoid.icon = "device-notifier"
                plasmoid.toolTipMainText = i18n("No devices available")
                plasmoid.toolTipSubText = ""
            }
        }
    }

    function popupEventSlot(popped) {
        if (!popped) {
            // reset the property that lets us remember if an item was clicked
            // (versus only hovered) for autohide purposes
            devicenotifier.itemClicked = true
            expandedDevice = ""
            devicenotifier.currentExpanded = -1
            devicenotifier.currentIndex = -1
        }
    }

    function expandDevice(udi) {
        if (hpSource.data[udi]["actions"].length > 1) {
            expandedDevice = udi
        }

        // reset the property that lets us remember if an item was clicked
        // (versus only hovered) for autohide purposes
        devicenotifier.itemClicked = false

        devicenotifier.popupIcon = "preferences-desktop-notification"
        //plasmoid.expanded = true;
        expandTimer.restart()
        popupIconTimer.restart()
    }

    function isMounted(udi) {
        var types = sdSource.data[udi]["Device Types"]
        if (types.indexOf("Storage Access") >= 0) {
            if (sdSource.data[udi]["Accessible"]) {
                return true
            } else {
                return false
            }
        } else if (types.indexOf("Storage Volume") >= 0 && types.indexOf(
                       "OpticalDisc") >= 0) {
            return true
        } else {
            return false
        }
    }

    Timer {
        id: popupIconTimer
        interval: 2500
        onTriggered: devicenotifier.popupIcon = "device-notifier"
    }

    Timer {
        id: passiveTimer
        interval: 2500
        onTriggered: plasmoid.status = PlasmaCore.Types.PassiveStatus
    }

    Timer {
        id: expandTimer
        interval: 250
        onTriggered: {
            plasmoid.expanded = true
        }
    }

    PlasmaCore.Svg {
        id: lineSvg
        imagePath: "widgets/line"
    }

    PlasmaExtras.Heading {
        width: parent.width
        level: 3
        opacity: 0.6
        text: i18n("No Devices Available")
        visible: filterModel.count == 0
    }

    PlasmaCore.DataSource {
        id: statusSource
        engine: "devicenotifications"
        property string last
        onSourceAdded: {
            console.debug("Source added " + last)
            last = source
            disconnectSource(source)
            connectSource(source)
        }
        onSourceRemoved: {
            console.debug("Source removed " + last)
            disconnectSource(source)
        }
        onDataChanged: {
            console.debug("Data changed for " + last)
            console.debug("Error:" + data[last]["error"])
            if (last != "") {
                statusBar.setData(data[last]["error"],
                                  data[last]["errorDetails"], data[last]["udi"])
                plasmoid.expanded = true
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent

        ListView {
            id: notifierDialog
            focus: true
            boundsBehavior: Flickable.StopAtBounds

            Layout.fillWidth: true
            Layout.fillHeight: true

            model: filterModel

            property int currentExpanded: -1
            property bool itemClicked: true
            delegate: deviceItem
            highlight: PlasmaComponents.Highlight {
            }
            highlightMoveDuration: 0
            highlightResizeDuration: 0

            //this is needed to make SectionScroller actually work
            //acceptable since one doesn't have a billion of devices
            cacheBuffer: 1000

            onCountChanged: {
                if (count == 0) {
                    passiveTimer.restart()
                } else {
                    passiveTimer.stop()
                    plasmoid.status = PlasmaCore.Types.ActiveStatus
                }
            }

            section {
                property: "Type Description"
                delegate: Item {
                    height: childrenRect.height
                    width: notifierDialog.width
                    PlasmaExtras.Heading {
                        level: 3
                        opacity: 0.6
                        text: section
                    }
                }
            }
        }

        PlasmaCore.SvgItem {
            id: statusBarSeparator
            Layout.fillWidth: true
            svg: lineSvg
            elementId: "horizontal-line"
            height: lineSvg.elementSize("horizontal-line").height

            visible: statusBar.height > 0
            anchors.bottom: statusBar.top
        }

        StatusBar {
            id: statusBar
            Layout.fillWidth: true
            anchors.bottom: parent.bottom
        }
    }

    Component {
        id: deviceItem

        DeviceItem {
            id: wrapper
            width: notifierDialog.width
            udi: DataEngineSource
            icon: sdSource.data[udi] ? sdSource.data[udi]["Icon"] : ""
            deviceName: sdSource.data[udi] ? sdSource.data[udi]["Description"] : ""
            emblemIcon: Emblems[0]
            state: sdSource.data[udi]["State"]

            percentUsage: {
                if (!sdSource.data[udi]) {
                    return 0
                }
                var freeSpace = new Number(sdSource.data[udi]["Free Space"])
                var size = new Number(sdSource.data[udi]["Size"])
                var used = size - freeSpace
                return used * 100 / size
            }
            freeSpaceText: sdSource.data[udi]
                           && sdSource.data[udi]["Free Space Text"] ? sdSource.data[udi]["Free Space Text"] : ""

            leftActionIcon: {
                if (mounted) {
                    return "media-eject"
                } else {
                    return "emblem-mounted"
                }
            }
            mounted: devicenotifier.isMounted(udi)

            onLeftActionTriggered: {
                var operationName = mounted ? "unmount" : "mount"
                var service = sdSource.serviceForSource(udi)
                var operation = service.operationDescription(operationName)
                service.startOperationCall(operation)
            }
            property bool isLast: (expandedDevice == udi)
            property int operationResult: (model["Operation result"])

            onIsLastChanged: {
                if (isLast) {
                    devicenotifier.currentExpanded = index
                }
            }
            onOperationResultChanged: {
                if (operationResult == 1) {
                    devicenotifier.popupIcon = "dialog-ok"
                    popupIconTimer.restart()
                } else if (operationResult == 2) {
                    devicenotifier.popupIcon = "dialog-error"
                    popupIconTimer.restart()
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: units.shortDuration * 3
                }
            }
        }
    }
} // MouseArea
