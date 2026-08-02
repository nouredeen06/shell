pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property PopoutState popouts

    implicitWidth: 220
    implicitHeight: Math.min(col.implicitHeight, 500)

    clip: true

    Flickable {
        anchors.fill: parent

        contentWidth: width
        contentHeight: col.implicitHeight

        clip: true

        ColumnLayout {
            id: col

            width: root.implicitWidth
            spacing: Tokens.spacing.small

            Repeater {
                model: {
                    const list = Hypr.workspaces.values.filter(ws => !ws.name.startsWith("special:") && ws.lastIpcObject.windows > 0);
                    list.sort((a, b) => a.id - b.id);
                    return list;
                }

                delegate: WorkspaceCard {
                    required property var modelData

                    Layout.fillWidth: true

                    wsId: modelData.id
                    popouts: root.popouts
                }
            }
        }
    }

    component WorkspaceCard: StyledRect {
        id: card

        required property int wsId
        required property PopoutState popouts

        readonly property bool isActive: Hypr.activeWsId === card.wsId
        readonly property var windows: Hypr.toplevels.values.filter(t => t.workspace?.id === card.wsId)

        implicitHeight: cardLayout.implicitHeight + Tokens.padding.medium * 2

        radius: Tokens.rounding.medium
        color: card.isActive ? Colours.tPalette.m3primaryContainer : Colours.tPalette.m3surfaceContainer

        StateLayer {
            radius: parent.radius
            onClicked: {
                Hypr.dispatch(`workspace ${card.wsId}`);
                card.popouts.hasCurrent = false;
            }
        }

        ColumnLayout {
            id: cardLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.medium

            spacing: Tokens.spacing.small

            StyledText {
                text: {
                    const ws = Hypr.workspaces.values.find(w => w.id === card.wsId);
                    return ws?.name && ws.name !== card.wsId.toString() ? ws.name : qsTr("Workspace %1").arg(card.wsId);
                }
                font: Tokens.font.label.medium
                color: card.isActive ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
            }

            Flow {
                Layout.fillWidth: true

                spacing: Tokens.spacing.extraSmall

                Repeater {
                    model: card.windows

                    delegate: ScreencopyView {
                        required property var modelData

                        captureSource: modelData.wayland // qmllint disable unresolved-type
                        live: true
                        constraintSize.width: 80
                        constraintSize.height: 55
                    }
                }
            }
        }
    }
}
