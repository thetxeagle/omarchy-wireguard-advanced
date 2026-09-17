# WireGuard Advanced for Omarchy

An Omarchy Quickshell bar plugin for NetworkManager-managed WireGuard tunnels.

It includes the upstream status panel and adds profile management from the plugin:

- add/import a `.conf` file
- rename a profile
- delete a profile
- connect and disconnect profiles
- enable and disable NetworkManager autoconnect

Everything runs as the logged-in user through `nmcli`; the plugin does not use
`wg-quick`, `wg show`, sudo, services, or custom privilege escalation.

## Install

```bash
omarchy plugin add https://github.com/thetxeagle/omarchy-wireguard-advanced.git --enable
omarchy bar move io.github.thetxeagle.wireguard-advanced --section right
```

The plugin requires Omarchy's Quickshell shell and NetworkManager with
WireGuard support. Add/import uses Omarchy's built-in desktop-portal file
chooser, so there are no extra picker packages to install.

## Controls

Use the `+` control beside Profiles to import a configuration. Each profile has
a connection toggle and a settings control for renaming, autoconnect, and
deletion.

| Key | Action |
| --- | --- |
| `i` | Import a WireGuard config |
| `s` or `e` | Open settings for the selected profile |
| `d` | Delete the selected profile |
| `a` | Toggle autoconnect for the selected profile |
| `t` | Toggle the primary profile |
| `r` | Refresh |

The IPC surface is also available:

```text
omarchy-shell io.github.thetxeagle.wireguard-advanced add /path/to/tunnel.conf
omarchy-shell io.github.thetxeagle.wireguard-advanced renameProfile <name-or-uuid> "New name"
omarchy-shell io.github.thetxeagle.wireguard-advanced deleteProfile <name-or-uuid>
omarchy-shell io.github.thetxeagle.wireguard-advanced on <name-or-uuid>
omarchy-shell io.github.thetxeagle.wireguard-advanced off <name-or-uuid>
omarchy-shell io.github.thetxeagle.wireguard-advanced autoOn <name-or-uuid>
omarchy-shell io.github.thetxeagle.wireguard-advanced autoOff <name-or-uuid>
```

The plugin never deletes source `.conf` files. Imported profiles are stored by
NetworkManager in its own connection store.

## License

MIT. The status-panel design is based on
[studylamp/omarchy-wireguard](https://github.com/studylamp/omarchy-wireguard).
