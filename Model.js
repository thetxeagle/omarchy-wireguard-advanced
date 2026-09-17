.pragma library

function splitTerse(line) {
  var fields = [], current = ""
  for (var i = 0; i < line.length; i++) {
    var ch = line[i]
    if (ch === "\\" && i + 1 < line.length) current += line[++i]
    else if (ch === ":") { fields.push(current); current = "" }
    else current += ch
  }
  fields.push(current)
  return fields
}
function kv(line) { var at = line.indexOf(":"); return at < 0 ? null : {key: line.substring(0, at), value: line.substring(at + 1).replace(/\\(.)/g, "$1")} }
function isDefaultRoute(value) { value = String(value || "").trim(); return value === "0.0.0.0/0" || value === "::/0" || value === "default" }
function humanBytes(value) { var n = Number(value); if (!isFinite(n) || n < 0) return ""; if (n < 1024) return n + " B"; var u = ["KB", "MB", "GB", "TB"], i = 0, v = n / 1024; while (v >= 1024 && i < u.length - 1) { v /= 1024; i++ } return (v >= 10 ? Math.round(v) : v.toFixed(1)) + " " + u[i] }

function parsePoll(raw) {
  var section = "", arg = "", details = {}, conns = [], lines = String(raw || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i]; if (!line) continue
    if (line[0] === "#") { var p = line.indexOf(" "); section = p < 0 ? line.substring(1) : line.substring(1, p); arg = p < 0 ? "" : line.substring(p + 1); if (!details[arg]) details[arg] = {peer: "", addresses: [], routes: [], rx: -1, tx: -1, autoconnect: false}; continue }
    if (section === "CONNS") { var f = splitTerse(line), end = f.length; if (end < 6 || f[end - 4] !== "wireguard") continue; conns.push({uuid: f[0], name: f.slice(1, end - 4).join(":"), device: f[end - 2], active: f[end - 3] === "yes", state: f[end - 1]}) }
    else if (section === "PEER") details[arg].peer += line + "\n"
    else if (section === "DEV") { var d = kv(line); if (!d) continue; if (d.key.indexOf("IP4.ADDRESS") === 0 || d.key.indexOf("IP6.ADDRESS") === 0) details[arg].addresses.push(d.value); if (d.key.indexOf("IP4.ROUTE") === 0 || d.key.indexOf("IP6.ROUTE") === 0) { var route = d.value.match(/dst\s*=\s*([^,]+)/); if (route) details[arg].routes.push(route[1].trim()) } }
    else if (section === "STAT") { if (details[arg].rx < 0) details[arg].rx = Number(line); else if (details[arg].tx < 0) details[arg].tx = Number(line) }
    else if (section === "AUTO") details[arg].autoconnect = line === "yes"
  }
  var result = []
  for (var c = 0; c < conns.length; c++) { var t = conns[c], byUuid = details[t.uuid] || {peer: "", autoconnect: false}, byDev = details[t.device], endpoint = (byUuid.peer.match(/endpoint[=:]\s*([^\s,;\\]+)/i) || ["", ""])[1], am = byUuid.peer.match(/allowed-ips[=:]\s*([^\s,\\]+)/i), allowed = am ? am[1].split(";") : [], routes = byDev ? byDev.routes : [], full = routes.some(isDefaultRoute) || allowed.some(isDefaultRoute); result.push({uuid: t.uuid, name: t.name, device: t.device, state: t.state, active: t.active, activating: t.active && t.state !== "activated", autoconnect: byUuid.autoconnect, endpoint: endpoint, allowedIps: allowed, addresses: byDev ? byDev.addresses : [], routes: routes, fullTunnel: full, rx: byDev ? byDev.rx : -1, tx: byDev ? byDev.tx : -1}) }
  return result
}
function primaryTunnel(tunnels, preference) { if (!tunnels || !tunnels.length) return null; preference = String(preference || "").trim(); for (var i = 0; i < tunnels.length; i++) if (preference && (tunnels[i].uuid === preference || tunnels[i].name === preference)) return tunnels[i]; for (var j = 0; j < tunnels.length; j++) if (tunnels[j].active) return tunnels[j]; return tunnels[0] }
function tunnelDetail(t) { if (!t) return ""; if (!t.active) return t.endpoint || "Not connected"; if (t.activating) return "Connecting…"; return (t.addresses[0] || "No address") + " · " + (t.fullTunnel ? "all traffic" : "split tunnel") + (t.autoconnect ? " · auto" : "") }
function transferDetail(t) { return t && t.active && t.rx >= 0 && t.tx >= 0 ? "↓ " + humanBytes(t.rx) + "   ↑ " + humanBytes(t.tx) : "" }
function statusSummary(tunnels, loaded) { if (!loaded) return "Checking…"; if (!tunnels.length) return "No tunnels configured"; var up = tunnels.filter(function (t) { return t.active }).map(function (t) { return t.name }); return !up.length ? (tunnels.length === 1 ? "Disconnected" : "All tunnels off") : up.length === 1 ? "Connected to " + up[0] : up.length + " tunnels up" }
