import QtQuick
import QtQuick.Controls
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "io.github.thetxeagle.wireguard-advanced"
  ipcTarget: "io.github.thetxeagle.wireguard-advanced"
  manageIpc: false
  property int tunnelIndex: 0
  property bool cursorActive: false
  property bool chooserOpen: false
  property string chooserAction: ""
  property var settingsProfile: null
  property string renameText: ""
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property var selected: service.tunnels.length ? service.tunnels[Math.min(tunnelIndex, service.tunnels.length - 1)] : null

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  function moveCursor(dx, dy) { var n = service.tunnels.length; tunnelIndex = Math.max(0, Math.min(Math.max(0, n - 1), tunnelIndex + (dy || dx))); cursorActive = true }
  function selectedId() { return selected ? selected.uuid : "" }
  function activate() { if (selected) service.toggleTunnel(selected.uuid); else service.toggleTunnel("") }
  function openAdd() { chooserOpen = false; root.close(); service.manage("add", "") }
  function openSettings(tunnel) { settingsProfile = tunnel; chooserAction = "settings"; chooserOpen = true }
  function startRename() {
    if (!settingsProfile) return
    renameText = settingsProfile.name
    chooserAction = "rename"
    Qt.callLater(function () { renameInput.forceActiveFocus(); renameInput.selectAll() })
  }
  function saveRename() { var name = renameText.trim(); if (!settingsProfile || name === "") return; service.manage("rename", settingsProfile.uuid, name); chooserOpen = false }
  function toggleSettingsAuto() { if (!settingsProfile) return; service.manage(settingsProfile.autoconnect ? "autoOff" : "autoOn", settingsProfile.uuid); chooserOpen = false }
  function requestDelete() { if (settingsProfile) chooserAction = "deleteConfirm" }
  function confirmDelete() { if (settingsProfile) service.manage("delete", settingsProfile.uuid); settingsProfile = null; chooserOpen = false }
  function leaveSettings() { if (chooserAction === "settings") { settingsProfile = null; chooserOpen = false } else chooserAction = "settings" }

  Service { id: service; settings: root.settings }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): string { service.toggleTunnel(""); return "ok" }
    function refresh(): string { service.refresh(); return "ok" }
    function add(path: string): string { service.manage("add", path); return "ok" }
    function renameProfile(id: string, name: string): string { service.manage("rename", id, name); return "ok" }
    function deleteProfile(id: string): string { service.manage("delete", id); return "ok" }
    function on(id: string): string { service.manage("on", id); return "ok" }
    function off(id: string): string { service.manage("off", id); return "ok" }
    function autoOn(id: string): string { service.manage("autoOn", id); return "ok" }
    function autoOff(id: string): string { service.manage("autoOff", id); return "ok" }
    function status(): string { return service.statusText }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰖂"
    foreground: service.anyActive ? Color.accent : root.dim
    useActiveColor: false
    tooltipText: service.statusText
    onPressed: function (code) { if (code === Qt.RightButton) service.toggleTunnel(""); else if (code === Qt.MiddleButton) service.refresh(); else root.toggle() }
  }

  KeyboardPanel {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keys
    contentWidth: popup.fittedContentWidth(Style.space(460))
    contentHeight: popup.fittedContentHeight(Math.max(column.implicitHeight, chooser.implicitHeight), Style.space(700))

    PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      onMoveRequested: function (dx, dy) { root.moveCursor(dx, dy) }
      onActivateRequested: root.activate()
      onCloseRequested: root.close()
      onTextKey: function (t) {
        if (t === "i" || t === "I") root.openAdd()
        else if ((t === "s" || t === "S" || t === "e" || t === "E") && root.selected) root.openSettings(root.selected)
        else if ((t === "d" || t === "D") && root.selected) { root.openSettings(root.selected); root.requestDelete() }
        else if ((t === "a" || t === "A") && root.selected) { root.settingsProfile = root.selected; root.toggleSettingsAuto() }
        else if (t === "t" || t === "T") service.toggleTunnel("")
        else if (t === "r" || t === "R") service.refresh()
      }

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        Column {
          id: column
          width: parent.width
          spacing: Style.space(24)

          PanelHero {
            width: parent.width
            title: "WireGuard"
            meta: service.statusText
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconOpacity: service.anyActive ? 1 : 0.5
            iconComponent: Component { Text { text: "󰖂"; color: service.anyActive ? Color.accent : root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.display } }
          }

          Text { visible: service.lastError !== ""; width: parent.width; text: service.lastError; color: root.urgent; wrapMode: Text.WordWrap; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall }

          Row {
            width: parent.width
            height: Style.space(42)
            Text {
              width: parent.width - Style.space(50)
              anchors.verticalCenter: parent.verticalCenter
              text: "PROFILES"
              color: "#c6a96b"
              font.family: "monospace"
              font.pixelSize: Style.font.body
              font.bold: true
            }
            Rectangle {
              width: Style.space(42)
              height: Style.space(42)
              color: addMouse.containsMouse ? "#20251f" : "#0e110e"
              border.width: 1
              border.color: addMouse.containsMouse ? "#72786d" : "#4b514a"
              Text { anchors.centerIn: parent; text: "+"; color: addMouse.containsMouse ? "#e2c98d" : root.foreground; font.family: "monospace"; font.pixelSize: Style.font.title; font.bold: true }
              MouseArea { id: addMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.openAdd() }
            }
          }

          Rectangle { width: parent.width; height: 1; color: "#20251f" }

          Text { visible: !service.tunnels.length && service.loaded; width: parent.width; text: "No WireGuard profiles yet. Use + to import one."; color: root.dim; wrapMode: Text.WordWrap; font.family: root.fontFamily; font.pixelSize: Style.font.body }

          Repeater {
            model: service.tunnels
            delegate: Rectangle {
              required property var modelData
              required property int index
              width: parent.width
              height: Style.space(92)
              color: profileMouse.containsMouse ? "#151a15" : "#0b0e0b"
              border.width: 1
              border.color: modelData.active ? Color.accent : profileMouse.containsMouse ? "#626862" : "#343a34"
              Rectangle { visible: modelData.active; anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 2; color: Color.accent }
              Item {
                id: row
                anchors.fill: parent
                anchors.margins: Style.space(16)
                Column {
                  anchors.left: parent.left
                  anchors.right: profileControls.left
                  anchors.rightMargin: Style.space(16)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(7)
                  Text { text: modelData.name; color: root.foreground; font.family: root.fontFamily; font.bold: true; font.pixelSize: Style.font.body }
                  Text { text: Model.tunnelDetail(modelData); color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.body; elide: Text.ElideRight }
                  Text { text: modelData.autoconnect ? "Autoconnect on" : "Autoconnect off"; color: modelData.autoconnect ? "#c6a96b" : root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall }
                }
                Row {
                  id: profileControls
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(10)
                  ToggleSwitch { anchors.verticalCenter: parent.verticalCenter; checked: service.isActive(modelData); busy: service.busy; foreground: root.foreground; onToggled: service.toggleTunnel(modelData.uuid) }
                  Rectangle {
                    width: Style.space(38)
                    height: Style.space(38)
                    anchors.verticalCenter: parent.verticalCenter
                    color: settingsMouse.containsMouse ? "#2a2e29" : "transparent"
                    border.width: 1
                    border.color: settingsMouse.containsMouse ? "#72786d" : "#4b514a"
                    Text { anchors.centerIn: parent; text: "󰒓"; color: settingsMouse.containsMouse ? "#e2c98d" : root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body }
                    MouseArea { id: settingsMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.openSettings(modelData) }
                  }
                }
                MouseArea { id: profileMouse; anchors.fill: parent; anchors.rightMargin: profileControls.width + Style.space(16); hoverEnabled: true; onEntered: { root.tunnelIndex = index; root.cursorActive = true } onClicked: service.toggleTunnel(modelData.uuid) }
              }
            }
          }
        }
      }

      Rectangle {
        id: chooser
        anchors.fill: parent
        visible: root.chooserOpen
        z: 20
        clip: true
        implicitHeight: chooserColumn.implicitHeight + Style.space(40)
        color: "#080a08"
        border.width: 1
        border.color: "#4b514a"

        Column {
          id: chooserColumn
          anchors.fill: parent
          anchors.margins: Style.space(20)
          spacing: Style.space(14)

          Text {
            width: parent.width
            text: root.chooserAction === "rename" ? "RENAME PROFILE" : root.chooserAction === "deleteConfirm" ? "CONFIRM DELETE" : "PROFILE SETTINGS"
            color: "#c6a96b"
            font.family: "monospace"
            font.pixelSize: Style.font.body
            font.bold: true
          }

          Text {
            width: parent.width
            text: root.chooserAction === "rename" ? "Choose a new name for “" + (root.settingsProfile ? root.settingsProfile.name : "this profile") + "”." : root.chooserAction === "deleteConfirm" ? "Delete “" + (root.settingsProfile ? root.settingsProfile.name : "this profile") + "”? This cannot be undone." : (root.settingsProfile ? root.settingsProfile.name : "")
            color: root.chooserAction === "deleteConfirm" ? "#d08b78" : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }

          Rectangle {
            visible: root.chooserAction === "settings"
            width: parent.width
            height: Style.space(58)
            color: renameMouse.containsMouse ? "#20251f" : "#0e110e"
            border.width: 1
            border.color: renameMouse.containsMouse ? "#72786d" : "#4b514a"
            Text { anchors.left: parent.left; anchors.leftMargin: Style.space(16); anchors.verticalCenter: parent.verticalCenter; text: "RENAME"; color: renameMouse.containsMouse ? "#e2c98d" : root.foreground; font.family: "monospace"; font.pixelSize: Style.font.body; font.bold: true }
            Text { anchors.right: parent.right; anchors.rightMargin: Style.space(16); anchors.verticalCenter: parent.verticalCenter; text: "CHANGE NAME"; color: root.dim; font.family: "monospace"; font.pixelSize: Style.font.bodySmall }
            MouseArea { id: renameMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.startRename() }
          }

          Rectangle {
            visible: root.chooserAction === "settings"
            width: parent.width
            height: Style.space(58)
            color: autoMouse.containsMouse ? "#20251f" : "#0e110e"
            border.width: 1
            border.color: autoMouse.containsMouse ? "#72786d" : "#4b514a"
            Text { anchors.left: parent.left; anchors.leftMargin: Style.space(16); anchors.verticalCenter: parent.verticalCenter; text: "AUTO-CONNECT"; color: autoMouse.containsMouse ? "#e2c98d" : root.foreground; font.family: "monospace"; font.pixelSize: Style.font.body; font.bold: true }
            Text { anchors.right: parent.right; anchors.rightMargin: Style.space(16); anchors.verticalCenter: parent.verticalCenter; text: root.settingsProfile && root.settingsProfile.autoconnect ? "ON" : "OFF"; color: root.settingsProfile && root.settingsProfile.autoconnect ? "#c6a96b" : root.dim; font.family: "monospace"; font.pixelSize: Style.font.body }
            MouseArea { id: autoMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.toggleSettingsAuto() }
          }

          Rectangle {
            visible: root.chooserAction === "settings"
            width: parent.width
            height: Style.space(58)
            color: deleteMouse.containsMouse ? "#2a1b19" : "#0e110e"
            border.width: 1
            border.color: deleteMouse.containsMouse ? "#8f5146" : "#4b514a"
            Text { anchors.left: parent.left; anchors.leftMargin: Style.space(16); anchors.verticalCenter: parent.verticalCenter; text: "DELETE PROFILE"; color: deleteMouse.containsMouse ? "#e4a093" : "#d08b78"; font.family: "monospace"; font.pixelSize: Style.font.body; font.bold: true }
            MouseArea { id: deleteMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.requestDelete() }
          }

          Rectangle {
            visible: root.chooserAction === "rename"
            width: parent.width
            height: Style.space(52)
            color: "#0e110e"
            border.width: 1
            border.color: renameInput.activeFocus ? "#c6a96b" : "#4b514a"
            TextInput {
              id: renameInput
              anchors.fill: parent
              anchors.leftMargin: Style.space(14)
              anchors.rightMargin: Style.space(14)
              verticalAlignment: TextInput.AlignVCenter
              text: root.renameText
              onTextChanged: root.renameText = text
              color: root.foreground
              selectionColor: Color.accent
              selectedTextColor: "#080a08"
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              Keys.onReturnPressed: root.saveRename()
            }
          }

          Rectangle {
            visible: root.chooserAction === "rename"
            width: parent.width
            height: Style.space(50)
            color: root.renameText.trim() === "" ? "#0e110e" : saveMouse.containsMouse ? "#2a2e29" : "#171c17"
            border.width: 1
            border.color: root.renameText.trim() === "" ? "#343a34" : saveMouse.containsMouse ? "#72786d" : "#4b514a"
            Text { anchors.centerIn: parent; text: "SAVE NAME"; color: root.renameText.trim() === "" ? root.dim : "#d5d8ce"; font.family: "monospace"; font.pixelSize: Style.font.body; font.bold: true }
            MouseArea { id: saveMouse; anchors.fill: parent; enabled: root.renameText.trim() !== ""; hoverEnabled: true; onClicked: root.saveRename() }
          }

          Rectangle {
            visible: root.chooserAction === "deleteConfirm"
            width: parent.width
            height: Style.space(54)
            color: confirmDeleteMouse.containsMouse ? "#40231f" : "#211513"
            border.width: 1
            border.color: "#8f5146"
            Text { anchors.centerIn: parent; text: "DELETE PROFILE"; color: "#e4a093"; font.family: "monospace"; font.pixelSize: Style.font.body; font.bold: true }
            MouseArea { id: confirmDeleteMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.confirmDelete() }
          }

          Rectangle {
            width: parent.width
            height: Style.space(48)
            color: cancelMouse.containsMouse ? "#20251f" : "transparent"
            border.width: 1
            border.color: cancelMouse.containsMouse ? "#72786d" : "#4b514a"
            Text { anchors.centerIn: parent; text: root.chooserAction === "settings" ? "CLOSE" : "BACK"; color: "#d5d8ce"; font.family: "monospace"; font.pixelSize: Style.font.body; font.bold: true }
            MouseArea { id: cancelMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.leaveSettings() }
          }
        }
      }
    }
  }
}
