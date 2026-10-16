/*-
 * Copyright (c) 2015-2019 elementary, Inc. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

public class Network.VPNPage : Network.Widgets.Page {
    private Gee.List<NM.ActiveConnection> active_connections;

    private Gtk.ListBox vpn_list;
    private uint timeout_id = 0;
    private VPNMenuItem? sel_row;
    private Granite.Toast remove_vpn_toast;

    public VPNPage () {
        Object (
            title: _("VPN"),
            description: _("A Virtual Private Network can hide network traffic on public networks or from your internet service provider. It can't protect passwords from attackers or prevent websites from identifying you."),
            icon: new ThemedIcon ("network-vpn")
        );
    }

    construct {
        remove_vpn_toast = new Granite.Toast (_("VPN removed"));
        remove_vpn_toast.set_default_action (_("Undo"));

        var placeholder = new Granite.Placeholder (_("No VPN Connections")) {
            description = _("Add a new VPN connection to begin.")
        };

        vpn_list = new Gtk.ListBox () {
            activate_on_single_click = false,
            hexpand = true,
            vexpand = true,
            selection_mode = BROWSE
        };
        vpn_list.set_placeholder (placeholder);
        vpn_list.set_sort_func ((Gtk.ListBoxSortFunc) compare_rows);
        vpn_list.add_css_class (Granite.STYLE_CLASS_RICH_LIST);

        var add_button_label = new Gtk.Label (_("Add Connection…"));

        var add_button_box = new Gtk.Box (HORIZONTAL, 0);
        add_button_box.append (new Gtk.Image.from_icon_name ("list-add-symbolic"));
        add_button_box.append (add_button_label);

        var add_button = new Gtk.Button () {
            child = add_button_box,
            has_frame = false
        };
        add_button_label.mnemonic_widget = add_button;

        var actionbar = new Gtk.ActionBar ();
        actionbar.add_css_class (Granite.STYLE_CLASS_FLAT);
        actionbar.pack_start (add_button);

        var scrolled = new Gtk.ScrolledWindow () {
            child = vpn_list
        };

        var vpn_box = new Gtk.Box (VERTICAL, 0);
        vpn_box.append (scrolled);
        vpn_box.append (actionbar);

        var frame = new Gtk.Frame (null) {
            child = vpn_box,
            vexpand = true
        };

        var main_overlay = new Gtk.Overlay () {
            child = frame
        };
        main_overlay.add_overlay (remove_vpn_toast);

        child = main_overlay;

        add_button.clicked.connect (() => {
            var connection_dialog = new VPNConnectionDialog () {
                transient_for = (Gtk.Window) get_root ()
            };
            connection_dialog.present ();
        });

        remove_vpn_toast.default_action.connect (() => {
            GLib.Source.remove (timeout_id);
            timeout_id = 0;
            sel_row.show ();
        });

        vpn_list.row_activated.connect (row => {
            if (((VPNMenuItem) row).state == NM.DeviceState.ACTIVATED) {
                disconnect_vpn_cb ((VPNMenuItem) row);
            } else {
                connect_vpn_cb ((VPNMenuItem) row);
            }
        });

        active_connections = new Gee.ArrayList<NM.ActiveConnection> ();

        update ();
        unowned NetworkManager network_manager = NetworkManager.get_default ();
        network_manager.client.notify["active-connections"].connect (update_active_connections);
    }

    protected override void update () {
        update_active_connections ();

        VPNMenuItem? item = null;
        foreach (var ac in active_connections) {
            if (ac != null) {
                unowned string connection_type = ac.get_connection_type ();
                if (connection_type == NM.SettingVpn.SETTING_NAME) {
                    switch (((NM.VpnConnection)ac).vpn_state) {
                        case NM.VpnConnectionState.UNKNOWN:
                        case NM.VpnConnectionState.DISCONNECTED:
                            state = NM.DeviceState.DISCONNECTED;
                            break;
                        case NM.VpnConnectionState.PREPARE:
                        case NM.VpnConnectionState.NEED_AUTH:
                        case NM.VpnConnectionState.IP_CONFIG_GET:
                        case NM.VpnConnectionState.CONNECT:
                            state = NM.DeviceState.PREPARE;
                            break;
                        case NM.VpnConnectionState.FAILED:
                            state = NM.DeviceState.FAILED;
                            break;
                        case NM.VpnConnectionState.ACTIVATED:
                            state = NM.DeviceState.ACTIVATED;
                            break;
                    }
                } else if (connection_type == NM.SettingWireGuard.SETTING_NAME) {
                    switch (ac.get_state ()) {
                        case NM.ActiveConnectionState.UNKNOWN:
                        case NM.ActiveConnectionState.DEACTIVATED:
                        case NM.ActiveConnectionState.DEACTIVATING:
                            state = NM.DeviceState.DISCONNECTED;
                            break;
                        case NM.ActiveConnectionState.ACTIVATING:
                            state = NM.DeviceState.PREPARE;
                            break;
                        case NM.ActiveConnectionState.ACTIVATED:
                            state = NM.DeviceState.ACTIVATED;
                            break;
                    }
                }

                item = get_item_by_uuid (ac.get_uuid ());
            } else {
                state = NM.DeviceState.DISCONNECTED;
            }

            if (item != null) {
                item.state = state;
            }
        }

        switch (state) {
            case ACTIVATED:
                status_type = SUCCESS;
                break;
            case DISCONNECTED:
                status_type = OFFLINE;
                break;
            case FAILED:
                status_type = ERROR;
                break;
            default:
                status_type = WARNING;
                break;
        }

        status = Utils.state_to_string (state);
    }

    protected override void update_switch () {

    }

    protected override void control_switch_activated () {

    }

    public void add_connection (NM.RemoteConnection connection) {
        var item = new VPNMenuItem (connection);
        item.remove_request.connect (() => {
            sel_row = item;
            remove_vpn_toast.send_notification ();
            timeout_id = GLib.Timeout.add (3600, () => {
                timeout_id = 0;
                delete_connection (item);
                return GLib.Source.REMOVE;
            });
        });

        vpn_list.append (item);
        update ();
    }

    public void remove_connection (NM.RemoteConnection connection) {
        var item = get_item_by_uuid (connection.get_uuid ());
        item.destroy ();
    }

    private VPNMenuItem? get_item_by_uuid (string uuid) {
        VPNMenuItem? item = null;

        unowned var child = vpn_list.get_first_child ();
        while (child != null && item == null) {
            if (child is VPNMenuItem) {
                var _item = (VPNMenuItem) child;
                if (_item.connection != null && _item.connection.get_uuid () == uuid) {
                    item = (VPNMenuItem) child;
                }
            }

            child = child.get_next_sibling ();
        }

        return item;
    }

    private void update_active_connections () {
        active_connections.clear ();
        unowned NetworkManager network_manager = NetworkManager.get_default ();
        network_manager.client.get_active_connections ().foreach ((ac) => {
            unowned string connection_type = ac.get_connection_type ();
            /* In both case, make sure to disconnect first any previously
             * connected signal to avoid spamming the CPU once you pass several
             * time into this function. */
            if (connection_type == NM.SettingVpn.SETTING_NAME) {
                /* We cannot rely on the sole state_changed signal, as it will
                 * silently ignore sub-vpn specific states, like tun/tap
                 * interface connection etc. That's why we keep a separate
                 * implementation for the signal handlers. */
                var _connection = (NM.VpnConnection) ac;
                _connection.vpn_state_changed.disconnect (update);
                _connection.vpn_state_changed.connect (update);
            } else if (connection_type == NM.SettingWireGuard.SETTING_NAME) {
                ac.state_changed.disconnect (update);
                ac.state_changed.connect (update);
            } else {
                // Neither a VPN, nor a Wireguard connection, do not add it to
                // the active_connection list.
                return;
            }
            // Either a VPN or a Wireguard connection
            active_connections.add (ac);
        });
    }

    private void connect_vpn_cb (VPNMenuItem item) {
        unowned NetworkManager network_manager = NetworkManager.get_default ();
        network_manager.client.activate_connection_async.begin (
            item.connection, null, null, null,
            (obj, res) => {
                try {
                    network_manager.client.activate_connection_async.end (res);
                } catch (Error e) {
                    warning (e.message);
                }
                update ();
            }
        );
    }

    private void disconnect_vpn_cb (VPNMenuItem item) {
        update_active_connections ();
        unowned NetworkManager network_manager = NetworkManager.get_default ();
        foreach (var ac in active_connections) {
            if (ac.get_connection () == item.connection) {
                network_manager.client.deactivate_connection_async.begin (ac, null, (obj, res) => {
                    try {
                        network_manager.client.deactivate_connection_async.end (res);
                    } catch (Error e) {
                        warning (e.message);
                    }
                    update ();
                });
                break;
            }
        }
    }

    private void delete_connection (VPNMenuItem item) {
        if (sel_row != null && sel_row == item) {
            try {
                item.connection.delete (null);
            } catch (Error e) {
                warning (e.message);
                var dialog = new Granite.MessageDialog (
                    _("Failed to remove VPN connection"),
                    "",
                    new ThemedIcon ("network-vpn"),
                    Gtk.ButtonsType.CLOSE
                ) {
                    badge_icon = new ThemedIcon ("dialog-error"),
                    modal = true,
                    transient_for = (Gtk.Window) get_root ()
                };
                dialog.show_error_details (e.message);
                dialog.present ();
                dialog.response.connect (dialog.destroy);
            }
        } else {
            warning ("Row selection changed between operations. Cancelling removal of VPN.");
            GLib.Source.remove (timeout_id);
            timeout_id = 0;
            sel_row.show ();
        }
    }

    [CCode (instance_pos = -1)]
    private int compare_rows (VPNMenuItem row1, VPNMenuItem row2) {
        unowned NM.SettingConnection vpn_menu_item1 = row1.connection.get_setting_connection ();
        unowned NM.SettingConnection vpn_menu_item2 = row2.connection.get_setting_connection ();

        if (vpn_menu_item1 != null && vpn_menu_item2 != null) {
            if (vpn_menu_item1.get_timestamp () > vpn_menu_item2.get_timestamp ()) {
                return -1;
            }
        }

        return 1;
    }
}
