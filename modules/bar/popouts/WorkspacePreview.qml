pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property PopoutState popouts

    implicitWidth: 220
    implicitHeight: Math.min(list.contentHeight, 500)

    focus: true

    ListView {
        id: list

        anchors.fill: parent

        clip: true
        spacing: Tokens.spacing.small
        keyNavigationEnabled: true
        focus: true

        model: {
            const ws = Hypr.workspaces.values.filter(w => !w.name.startsWith("special:") && w.lastIpcObject.windows > 0);
            ws.sort((a, b) => a.id - b.id);
            return ws;
        }

        currentIndex: {
            const activeId = Hypr.activeWsId;
            const wsList = Hypr.workspaces.values.filter(w => !w.name.startsWith("special:") && w.lastIpcObject.windows > 0);
            wsList.sort((a, b) => a.id - b.id);
            return Math.max(0, wsList.findIndex(w => w.id === activeId));
        }

        Keys.onReturnPressed: {
            const ws = model[currentIndex];
            if (ws) {
                Hypr.dispatch(`workspace ${ws.id}`);
                root.popouts.hasCurrent = false;
            }
        }

        delegate: Item {
            id: wsCard

            required property var modelData
            required property int index

            readonly property int wsId: modelData.id
            readonly property bool isHighlighted: ListView.isCurrentItem
            readonly property var firstWindow: Hypr.toplevels.values.find(t => t.workspace?.id === wsCard.wsId) ?? null

            width: list.width
            height: 120
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: Tokens.rounding.medium
                color: wsCard.isHighlighted ? Colours.tPalette.m3primaryContainer : Colours.tPalette.m3surfaceContainer
            }

            ScreencopyView {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter

                captureSource: wsCard.firstWindow?.wayland ?? null // qmllint disable unresolved-type
                live: true
                constraintSize.width: 220
                constraintSize.height: 500
            }

            Rectangle {
                z: 1
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: Tokens.spacing.extraSmall
                radius: Tokens.rounding.small
                color: Qt.rgba(0, 0, 0, 0.55)
                implicitWidth: badge.implicitWidth + Tokens.padding.small
                implicitHeight: badge.implicitHeight + 2

                StyledText {
                    id: badge

                    anchors.centerIn: parent
                    text: wsCard.wsId.toString()
                    font: Tokens.font.label.small
                    color: "white"
                }
            }

            StateLayer {
                radius: Tokens.rounding.medium
                onClicked: {
                    Hypr.dispatch(`workspace ${wsCard.wsId}`);
                    root.popouts.hasCurrent = false;
                }
            }
        }
    }
}
