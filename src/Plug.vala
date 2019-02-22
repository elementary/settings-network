/*-
 * Copyright (c) 2015-2016 elementary LLC.
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

/* Strings */
const string SUFFIX = " ";

namespace Network {
    public class MainBox : Network.Widgets.NMVisualizer {
        private NM.Device current_device = null;
        private Gtk.Stack content;
        private Gtk.ScrolledWindow scrolled_window;
        private WidgetNMInterface page;
        private Widgets.DeviceList device_list;
        private Granite.Widgets.AlertView no_devices;

        protected override void add_interface (WidgetNMInterface widget_interface) {
            device_list.add_iface_to_list (widget_interface);

            update_networking_state ();
            show_all ();
        }

        protected override void remove_interface (WidgetNMInterface widget_interface) {
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

        protected override void add_connection (NM.RemoteConnection connection) {
            device_list.add_connection (connection);
        }

        protected override void remove_connection (NM.RemoteConnection connection) {
            device_list.remove_connection (connection);
        }

        private void select_first () {
            device_list.select_first_item ();
        }

        protected override void build_ui () {
            var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            paned.width_request = 250;

            content = new Gtk.Stack ();
            content.hexpand = true;

            var sidebar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
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

            no_devices = new Granite.Widgets.AlertView (
                _("There is nothing to do"),
                _("There are no available Wi-Fi connections or Wi-Fi devices connected to this computer.\n") +
                _("Please connect at least one device to begin configuring the network."),
                "dialog-cancel"
            );

            no_devices.show_all ();

            content.add_named (airplane_mode, "airplane-mode-info");
            content.add_named (no_devices, "no-devices-info");

            scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.add (device_list);
            scrolled_window.vexpand = true;

            sidebar.pack_start (scrolled_window, true, true);
            sidebar.pack_start (footer, false, false);

            paned.pack1 (sidebar, false, false);
            paned.pack2 (content, true, false);
            paned.set_position (240);

            connect_signals ();

            var main_grid = new Gtk.Grid ();
            main_grid.add (paned);
            main_grid.show_all ();
            add (main_grid);

            update_networking_state ();
        }

        /* Main function to connect all the signals */
        private void connect_signals () {
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

    public class Plug : Switchboard.Plug {
        MainBox? main_box = null;
        public Plug () {
            var settings = new Gee.TreeMap<string, string?> (null, null);
            settings.set ("network", null);
            Object (category: Category.NETWORK,
                    code_name: "pantheon-network",
                    display_name: _("Network"),
                    description: _("Manage network devices and connectivity"),
                    icon: "preferences-system-network",
                    supported_settings: settings);
        }

        public override Gtk.Widget get_widget () {
            if (main_box == null) {
                main_box = new MainBox ();
            }

            return main_box;
        }

        public override void shown () {

        }

        public override void hidden () {

        }

        public override void search_callback (string location) {

        }

        // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
        public override async Gee.TreeMap<string, string> search (string search) {
            var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)strcmp, (Gee.EqualDataFunc<string>)str_equal);
            search_results.set ("%s → %s".printf (display_name, _("Ethernet")), "");
            search_results.set ("%s → %s".printf (display_name, _("LAN")), "");
            search_results.set ("%s → %s".printf (display_name, _("Wireless")), "");
            search_results.set ("%s → %s".printf (display_name, _("Wi-Fi")), "");
            search_results.set ("%s → %s".printf (display_name, _("WLAN")), "");
            search_results.set ("%s → %s".printf (display_name, _("Proxy")), "");
            search_results.set ("%s → %s".printf (display_name, _("Airplane Mode")), "");
            search_results.set ("%s → %s".printf (display_name, _("IP Address")), "");
            search_results.set ("%s → %s".printf (display_name, _("Hotspot")), "");
            search_results.set ("%s → %s".printf (display_name, _("VPN")), "");
            return search_results;
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Network plug");

    var plug = new Network.Plug ();
    return plug;
}
