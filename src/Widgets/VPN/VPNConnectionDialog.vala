/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class Network.VPNConnectionDialog : Gtk.Window {
    construct {
        var title_label = new Gtk.Label (_("Choose a VPN Connection type")) {
            hexpand = true,
            selectable = true,
            max_width_chars = 50,
            wrap = true,
            xalign = 0
        };
        title_label.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);

        var import_button = new Gtk.Button.with_label (_("Import configuration file"));

        var content_area = new Gtk.Box (VERTICAL, 0);
        content_area.append (title_label);
        content_area.append (import_button);
        content_area.add_css_class ("dialog-content-area");

        var create_button = new Gtk.Button.with_label (_("Create…")) {
            sensitive = false
        };

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));

        var action_area = new Gtk.Box (HORIZONTAL, 0) {
            margin_top = 24,
            halign = END,
            valign = END,
            vexpand = true,
            homogeneous = true
        };
        action_area.append (cancel_button);
        action_area.append (create_button);
        action_area.add_css_class ("dialog-action-area");

        var vbox = new Gtk.Box (VERTICAL, 0);
        vbox.append (content_area);
        vbox.append (action_area);
        vbox.add_css_class ("dialog-vbox");

        var window_handle = new Gtk.WindowHandle () {
            child = vbox
        };

        add_css_class ("dialog");
        add_css_class ("message");
        default_height = 400;
        default_width = 300;
        modal = true;
        child = window_handle;
        titlebar = new Gtk.Grid () { visible = false };

        import_button.clicked.connect (import_config_file);

        cancel_button.clicked.connect (() => close ());
    }

    private async void import_config_file () {
        var dialog = new Gtk.FileDialog () {
            modal = true,
            title = _("Select file to import")
        };


        GLib.File file = null;
        try {
            file = yield dialog.open (this, null);
        } catch (Error e) {
            critical (e.message);
        }

        var filename = file.get_path ();

        NM.Connection connection = null;

        try {
            connection = NM.conn_wireguard_import (filename);
        } catch (Error e) {
            critical (e.message);
        }

        try {
            var plugin_info_list = NM.VpnPluginInfo.list_load ();
            foreach (unowned var plugin_info in plugin_info_list) {
                if (connection != null) {
                    break;
                }

                var plugin = plugin_info.get_editor_plugin ();
                connection = plugin.import (filename);
            }
        } catch (Error e) {
            critical (e.message);
        }

        // try {
        //     yield ((NM.RemoteConnection) connection).save_async (null);
        // } catch (Error e) {
        //     critical (e.message);
        // }

        close ();
    }
}














            // try_connection_editor ("--create --type=vpn");
    // private void try_connection_editor (string args) {
    //     try {
    //         var appinfo = AppInfo.create_from_commandline (
    //             "nm-connection-editor %s".printf (args),
    //             null,
    //             GLib.AppInfoCreateFlags.NONE
    //         );
    //         appinfo.launch (null, null);
    //     } catch (Error error) {
    //         var dialog = new Granite.MessageDialog (
    //             _("Failed to run Connection Editor"),
    //             _("The program \"nm-connection-editor\" may not be installed."),
    //             new ThemedIcon ("network-vpn"),
    //             Gtk.ButtonsType.CLOSE
    //         ) {
    //             badge_icon = new ThemedIcon ("dialog-error"),
    //             modal = true,
    //             transient_for = (Gtk.Window) get_root ()
    //         };
    //         dialog.show_error_details (error.message);
    //         dialog.present ();
    //         dialog.response.connect (dialog.destroy);
    //     }
    // }
