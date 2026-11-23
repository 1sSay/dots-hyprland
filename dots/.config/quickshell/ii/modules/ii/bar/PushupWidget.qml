import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    property bool containsMouse: button.hovered

    RippleButton {
        id: button
        anchors.centerIn: parent
        buttonRadius: Appearance.rounding.full
        implicitWidth: contentRow.implicitWidth + 16
        implicitHeight: 30
        downAction: Pushups.add

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 4

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: "fitness_center"
                fill: 1
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnLayer1
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Pushups.today
                animateChange: true
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer1
            }
        }
    }

    PushupPopup {
        hoverTarget: root
    }
}
