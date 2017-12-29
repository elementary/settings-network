/*
 * Copyright (c) 2015 Wingpanel Developers (http://launchpad.net/wingpanel)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public abstract class Network.Widgets.NMVisualizer : Gtk.Box {
    protected NM.Client nm_client;

    protected GLib.List<WidgetNMInterface>? network_interface;

    public Network.State state { private set; get; default = Network.State.CONNECTING_WIRED; }

    construct {
        network_interface = new GLib.List<WidgetNMInterface>();

        build_ui ();

        /* Monitor network manager */
        try {
            nm_client = new NM.Client ();
            nm_client.connection_added.connect (connection_added_cb);
            nm_client.connection_removed.connect (connection_removed_cb);

            nm_client.device_added.connect (device_added_cb);
            nm_client.device_removed.connect (device_removed_cb);

            nm_client.get_devices ().foreach ((device) => device_added_cb (device));
            nm_client.get_connections ().foreach ((connection) => add_connection (connection));
        } catch (Error e) {
            warning (e.message);
        }

        show_all();
    }

    protected abstract void build_ui ();
    protected abstract void add_interface (WidgetNMInterface widget_interface);
    protected abstract void remove_interface (WidgetNMInterface widget_interface);
    protected abstract void add_connection (NM.RemoteConnection connection);
    protected abstract void remove_connection (NM.RemoteConnection connection);

    void device_removed_cb (NM.Device device) {
        foreach (var widget_interface in network_interface) {
            if (widget_interface.is_device (device)) {
                network_interface.remove (widget_interface);

                // Implementation call
                remove_interface (widget_interface);
                break;
            }
        }

        update_interfaces_names ();
    }

    void update_interfaces_names () {
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

    void connection_added_cb (Object obj) {
        var connection = (NM.RemoteConnection)obj;

        add_connection (connection);
    }

    void connection_removed_cb (Object obj) {
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
#if PLUG_NETWORK
        WidgetNMInterface? hotspot_interface = null;
#endif

        if (device is NM.DeviceWifi) {
            widget_interface = new WifiInterface (nm_client, device);
#if PLUG_NETWORK
            hotspot_interface = new HotspotInterface ((WifiInterface)widget_interface);
#endif

            debug ("Wifi interface added");
        } else if (device is NM.DeviceEthernet) {
            widget_interface = new EtherInterface (nm_client, device);
            debug ("Ethernet interface added");
        } else if (device is NM.DeviceModem) {
            widget_interface = new ModemInterface (nm_client, device);
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

#if PLUG_NETWORK
        if (hotspot_interface != null) {
            // Implementation call
            network_interface.append (hotspot_interface);
            add_interface (hotspot_interface);
            hotspot_interface.notify["state"].connect(update_state);
        }
#endif

        update_interfaces_names ();
        update_all ();
        show_all ();
    }

    void update_all () {
        foreach (var inter in network_interface) {
            inter.update ();
        }
    }

    void update_state () {
        var next_state = Network.State.DISCONNECTED;
        foreach (var inter in network_interface) {
            if (inter.state != Network.State.DISCONNECTED) {
                next_state = inter.state;
            }
        }

        state = next_state;
    }
}
