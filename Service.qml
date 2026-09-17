import QtQuick
import Quickshell.Io
import "Model.js" as Model

Item {
  id: root
  property var settings: ({})
  property var tunnels: []
  property bool loaded: false
  property string lastError: ""
  property var pending: ({})
  readonly property int refreshIntervalSec: intSetting("refreshIntervalSec", 5, 2, 3600)
  readonly property string preferredPrimary: String(setting("primary", ""))
  readonly property var primary: Model.primaryTunnel(tunnels, preferredPrimary)
  readonly property bool anyActive: tunnels.some(function (t) { return isActive(t) })
  readonly property bool busy: pollProcess.running || actionProcess.running || managementProcess.running
  readonly property string statusText: Model.statusSummary(tunnels, loaded)
  readonly property string scriptPath: String(Qt.resolvedUrl("poll.sh")).replace(/^file:\/\//, "")
  readonly property string managePath: String(Qt.resolvedUrl("manage.sh")).replace(/^file:\/\//, "")

  function setting(name, fallback) { var v = settings ? settings[name] : undefined; return v === undefined || v === null ? fallback : v }
  function intSetting(name, fallback, min, max) { var n = parseInt(String(setting(name, fallback)), 10); if (!isFinite(n)) n = fallback; return Math.max(min, Math.min(max, n)) }
  function isActive(t) { if (!t) return false; return pending[t.uuid] === undefined ? t.active : pending[t.uuid] }
  function find(value) { value = String(value || ""); for (var i = 0; i < tunnels.length; i++) if (tunnels[i].uuid === value || tunnels[i].name === value) return tunnels[i]; return null }
  function setPending(uuid, value) { var n = {}; for (var k in pending) n[k] = pending[k]; n[uuid] = value; pending = n; pendingTimeout.restart() }
  function refresh() { if (!pollProcess.running) { pollProcess.command = ["bash", scriptPath]; pollProcess.running = true } }
  function applyPoll(raw) { tunnels = Model.parsePoll(raw); loaded = true; var n = {}; for (var i = 0; i < tunnels.length; i++) if (pending[tunnels[i].uuid] !== undefined && pending[tunnels[i].uuid] !== tunnels[i].active) n[tunnels[i].uuid] = pending[tunnels[i].uuid]; pending = n }
  function run(command) { if (actionProcess.running) return; lastError = ""; actionProcess.command = command; actionProcess.running = true }
  function toggleTunnel(value) { var t = value ? find(value) : primary; if (t) (isActive(t) ? down : up)(t.uuid) }
  function up(uuid) { var t = find(uuid); if (t) { setPending(t.uuid, true); run(["nmcli", "connection", "up", "uuid", t.uuid]) } }
  function down(uuid) { var t = find(uuid); if (t) { setPending(t.uuid, false); run(["nmcli", "connection", "down", "uuid", t.uuid]) } }
  function manage(action, value, extra) { if (managementProcess.running) return; var t = value ? find(value) : primary; if (action === "add") { managementProcess.command = value ? ["bash", managePath, "add", value] : ["bash", managePath, "add"]; managementProcess.running = true; return } if (!t) return; managementProcess.command = extra === undefined ? ["bash", managePath, action, t.uuid] : ["bash", managePath, action, t.uuid, String(extra)]; managementProcess.running = true }
  function isPending(t) { return t && (pending[t.uuid] !== undefined || t.activating) }

  Timer { interval: root.refreshIntervalSec * 1000; repeat: true; running: true; triggeredOnStart: true; onTriggered: root.refresh() }
  Timer { id: settle; interval: 700; onTriggered: root.refresh() }
  Timer { id: pendingTimeout; interval: 20000; onTriggered: root.pending = ({}) }
  Process {
    id: pollProcess
    command: []
    stdout: StdioCollector { id: pollOut; waitForEnd: true }
    stderr: StdioCollector { id: pollErr; waitForEnd: true }
    onExited: function (code) {
      if (code === 0) {
        root.applyPoll(pollOut.text)
        root.lastError = ""
      } else {
        root.loaded = true
        root.lastError = String(pollErr.text || "").trim() || "Could not read WireGuard state"
      }
    }
  }
  Process {
    id: actionProcess
    command: []
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector { id: actionErr; waitForEnd: true }
    onExited: function (code) {
      if (code !== 0) {
        root.pending = ({})
        root.lastError = String(actionErr.text || "").trim() || "NetworkManager action failed"
      }
      settle.restart()
    }
  }
  Process {
    id: managementProcess
    command: []
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector { id: managementErr; waitForEnd: true }
    onExited: function (code) {
      if (code !== 0) root.lastError = String(managementErr.text || "").trim() || "Profile management action failed"
      settle.restart()
    }
  }
}
