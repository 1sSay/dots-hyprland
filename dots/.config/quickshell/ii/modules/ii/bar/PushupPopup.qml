import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    property var week: Pushups.weekEntries()
    readonly property int weekMaximum: Math.max(1, ...week.map(day => day.count))

    ColumnLayout {
        id: content
        implicitWidth: 300
        anchors.centerIn: parent
        spacing: 10

        StyledPopupHeaderRow {
            icon: "fitness_center"
            label: "Подтягивания"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StatCard {
                Layout.fillWidth: true
                label: "Сегодня"
                value: Pushups.today
                highlighted: true
            }

            StatCard {
                Layout.fillWidth: true
                label: "Неделя"
                value: Pushups.weekTotal
            }

            StatCard {
                Layout.fillWidth: true
                label: Pushups.monthLabel
                value: Pushups.monthTotal
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            StyledText {
                text: "Эта неделя"
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnSurfaceVariant
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: root.week

                    delegate: ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 3

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                }
                                height: Math.max(3, parent.height * modelData.count / root.weekMaximum)
                                radius: 3
                                color: modelData.today ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer

                                Behavior on height {
                                    NumberAnimation {
                                        duration: Appearance.animation.elementMoveFast.duration
                                        easing.type: Appearance.animation.elementMoveFast.type
                                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                    }
                                }
                            }
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.count
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: modelData.today ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.label
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: "Нажми на кнопку в панели, чтобы добавить +1"
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnSurfaceVariant
        }
    }

    component StatCard: Rectangle {
        required property string label
        required property int value
        property bool highlighted: false
        implicitHeight: statContent.implicitHeight + 14
        radius: Appearance.rounding.small
        color: highlighted ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer1

        ColumnLayout {
            id: statContent
            anchors {
                fill: parent
                margins: 7
            }
            spacing: 1

            StyledText {
                Layout.fillWidth: true
                text: parent.parent.label
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }

            StyledText {
                Layout.fillWidth: true
                text: parent.parent.value
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.DemiBold
                color: parent.parent.highlighted ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
            }
        }
    }
}
