/*
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

public class Network.MainView : Gtk.Paned {
    protected GLib.List<WidgetNMInterface>? network_interface;

    public Network.State state { private set; get; default = Network.State.CONNECTING_WIRED; }

    private NM.Device current_device = null;
    private Gtk.Stack content;
    private WidgetNMInterface page;
    private Widgets.DeviceList device_list;

    construct {
        network_interface = new GLib.List<WidgetNMInterface>();

        device_list = new Widgets.DeviceList ();

        var footer = new Widgets.Footer ();

        var airplane_mode = new Granite.Widgets.AlertView (
            _("Airplane Mode Is Enabled"),
            _("While in Airplane Mode your device's Internet access and any wireless and ethernet connections, will be suspended.\n\n") +
            _("You will be unable to browse the web or use applications that require a network connection or Internet access.\n") +
            _("Applications and other functions that do not require the Internet will be unaffected."),
            "airplane-mode"
        );

        airplane_mode.show_all ();

        var no_devices = new Granite.Widgets.AlertView (
            _("There is nothing to do"),
            _("There are no available Wi-Fi connections or Wi-Fi devices connected to this computer.\n") +
            _("Please connect at least one device to begin configuring the network."),
            "dialog-cancel"
        );

        no_devices.show_all ();

        content = new Gtk.Stack ();
        content.hexpand = true;
        content.add_named (airplane_mode, "airplane-mode-info");
        content.add_named (no_devices, "no-devices-info");

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.add (device_list);
        scrolled_window.expand = true;

        var sidebar = new Gtk.Grid ();
        sidebar.orientation = Gtk.Orientation.VERTICAL;
        sidebar.add (scrolled_window);
        sidebar.add (footer);

        position = 240;
        pack1 (sidebar, false, false);
        pack2 (content, true, false);

        device_list.row_activated.connect ((row) => {
            var page = ((Widgets.DeviceItem)row).page;
            if (content.get_children ().find (page) == null) {
                content.add (page);
            }

            content.visible_child = page;
        });

        device_list.show_no_devices.connect ((show) => {
            scrolled_window.sensitive = !show;
            if (show) {
                content.set_visible_child (no_devices);
            } else {
                content.set_visible_child (page);
            }
        });

        unowned NetworkManager network_manager = NetworkManager.get_default ();
        network_manager.client.notify["networking-enabled"].connect (update_networking_state);

        update_networking_state ();

        /* Monitor network manager */
        unowned NetworkManager nm_manager = NetworkManager.get_default ();
        unowned NM.Client nm_client = nm_manager.client;
        nm_client.connection_added.connect (connection_added_cb);
        nm_client.connection_removed.connect (connection_removed_cb);

        nm_client.device_added.connect (device_added_cb);
        nm_client.device_removed.connect (device_removed_cb);

        nm_client.get_devices ().foreach ((device) => device_added_cb (device));
        nm_client.get_connections ().foreach ((connection) => add_connection (connection));

        show_all();
    }

    private void device_removed_cb (NM.Device device) {
        foreach (var widget_interface in network_interface) {
            if (widget_interface.device == device) {
                network_interface.remove (widget_interface);

                // Implementation call
                remove_interface (widget_interface);
                break;
            }
        }

        update_interfaces_names ();
    }

    private void update_interfaces_names () {
        var count_type = new Gee.HashMap<string, int?> ();
        foreach (var iface in network_interface) {
            var type = iface.get_type ().name ();
            if (count_type.has_key (type)) {
                count_type[type] = count_type[type] + 1;
            } else {
                count_type[type] = 1;
            }
        }

        foreach (var iface in network_interface) {
            var type = iface.get_type ().name ();
            iface.update_name (count_type [type]);
        }
    }

    private void connection_added_cb (Object obj) {
        var connection = (NM.RemoteConnection)obj;

        add_connection (connection);
    }

    private void connection_removed_cb (Object obj) {
        var connection = (NM.RemoteConnection)obj;

        remove_connection (connection);
    }

    private void device_added_cb (NM.Device device) {
        if (device.get_iface ().has_prefix ("vmnet") ||
            device.get_iface ().has_prefix ("lo") ||
            device.get_iface ().has_prefix ("veth")) {
            return;
        }

        WidgetNMInterface? widget_interface = null;
        WidgetNMInterface? hotspot_interface = null;

        if (device is NM.DeviceWifi) {
            widget_interface = new Network.WifiInterface (device);
            hotspot_interface = new Network.Widgets.HotspotInterface ((WifiInterface)widget_interface);

            debug ("Wifi interface added");
        } else if (device is NM.DeviceEthernet) {
            widget_interface = new Network.Widgets.EtherInterface (device);
            debug ("Ethernet interface added");
        } else if (device is NM.DeviceModem) {
            widget_interface = new Network.Widgets.ModemInterface (device);
            debug ("Modem interface added");
        } else {
            debug ("Unknown device: %s\n", device.get_device_type().to_string());
        }

        if (widget_interface != null) {
            // Implementation call
            network_interface.append (widget_interface);
            add_interface(widget_interface);
            widget_interface.notify["state"].connect(update_state);

        }

        if (hotspot_interface != null) {
            // Implementation call
            network_interface.append (hotspot_interface);
            add_interface (hotspot_interface);
            hotspot_interface.notify["state"].connect(update_state);
        }

        update_interfaces_names ();
        update_all ();
        show_all ();
    }

    private void update_all () {
        foreach (var inter in network_interface) {
            inter.update ();
        }
    }

    private void update_state () {
        var next_state = Network.State.DISCONNECTED;
        foreach (var inter in network_interface) {
            if (inter.state != Network.State.DISCONNECTED) {
                next_state = inter.state;
            }
        }

        state = next_state;
    }

    private void add_interface (WidgetNMInterface widget_interface) {
        device_list.add_iface_to_list (widget_interface);

        update_networking_state ();
        show_all ();
    }

    private void remove_interface (WidgetNMInterface widget_interface) {
        if (content.get_visible_child () == widget_interface) {
            var row = device_list.get_selected_row ();
            int index = device_list.get_selected_row ().get_index ();
            device_list.remove_iface_from_list (widget_interface);

            if (row != null && row.get_index () >= 0) {
                device_list.get_row_at_index (index).activate ();
            } else {
                select_first ();
            }
        } else {
            device_list.remove_iface_from_list (widget_interface);
        }

        widget_interface.destroy ();

        show_all ();
    }

    private void add_connection (NM.RemoteConnection connection) {
        device_list.add_connection (connection);
    }

    private void remove_connection (NM.RemoteConnection connection) {
        device_list.remove_connection (connection);
    }

    private void select_first () {
        device_list.select_first_item ();
    }

    private void update_networking_state () {
        unowned NetworkManager network_manager = NetworkManager.get_default ();
        if (network_manager.client.networking_get_enabled ()) {
            device_list.sensitive = true;
            device_list.select_first_item ();
        } else {
            device_list.sensitive = false;
            current_device = null;
            device_list.select_row (null);
            content.set_visible_child_name ("airplane-mode-info");
        }
    }
}
