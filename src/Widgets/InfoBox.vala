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

namespace Network.Widgets {  
    public class InfoBox : Gtk.Grid {
        public signal void update_sidebar (DeviceItem item);
        public signal void info_changed ();
        private NM.Device device;
        private DeviceItem? owner;

        private Gtk.Label ip4address;
        private Gtk.Label ip6address;
        private Gtk.Label mask;
        private Gtk.Label router;
        private Gtk.Label broadcast;
        private Gtk.Label sent;
        private Gtk.Label received;

        private Gtk.Label ip6address_head;

        public InfoBox.from_device (NM.Device? _device) {
            owner = null;
            device = _device;

            init_box ();
        }

        public InfoBox.from_owner (DeviceItem? _owner) {
            owner = _owner;
            device = owner.get_item_device ();

            init_box ();
        }

        private void init_box () {
            column_spacing = 12;
            row_spacing = 6;

            var sent_head = new Gtk.Image.from_icon_name ("go-up-symbolic", Gtk.IconSize.BUTTON);
            sent = new Gtk.Label ("");

            var sent_grid = new Gtk.Grid ();
            sent_grid.column_spacing = 12;
            sent_grid.tooltip_text = (_("Sent"));
            sent_grid.add (sent_head);
            sent_grid.add (sent);

            var received_head = new Gtk.Image.from_icon_name ("go-down-symbolic", Gtk.IconSize.BUTTON);
            received = new Gtk.Label ("");

            var received_grid = new Gtk.Grid ();
            received_grid.column_spacing = 12;
            received_grid.tooltip_text = (_("Received"));
            received_grid.add (received_head);
            received_grid.add (received);

            var send_receive_grid = new Gtk.Grid ();
            send_receive_grid.halign = Gtk.Align.CENTER;
            send_receive_grid.column_spacing = 12;
            send_receive_grid.margin_top = 12;
            send_receive_grid.add (sent_grid);
            send_receive_grid.add (received_grid);

            var ip4address_head = new Gtk.Label (_("IP Address:"));
            ip4address_head.halign = Gtk.Align.END;

            ip4address = new Gtk.Label ("");
            ip4address.selectable = true;
            ip4address.xalign = 0;

            ip6address_head = new Gtk.Label (_("IPv6 Address:"));
            ip6address_head.no_show_all = true;
            ip6address_head.halign = Gtk.Align.END;

            ip6address = new Gtk.Label ("");
            ip6address.selectable = true;
            ip6address.no_show_all = true;
            ip6address.xalign = 0;

            var mask_head = new Gtk.Label (_("Subnet mask:"));
            mask_head.halign = Gtk.Align.END;

            mask = new Gtk.Label ("");
            mask.selectable = true;
            mask.xalign = 0;

            var router_head = new Gtk.Label (_("Router:"));
            router_head.halign = Gtk.Align.END;

            router = new Gtk.Label ("");
            router.selectable = true;
            router.xalign = 0;

            var broadcast_head = new Gtk.Label (_("Broadcast:"));
            broadcast_head.halign = Gtk.Align.END;

            broadcast = new Gtk.Label ("");
            broadcast.selectable = true;
            broadcast.xalign = 0;

            attach (ip4address_head, 0, 0);
            attach_next_to (ip4address, ip4address_head, Gtk.PositionType.RIGHT);

            attach_next_to (ip6address_head, ip4address_head, Gtk.PositionType.BOTTOM);
            attach_next_to (ip6address, ip6address_head, Gtk.PositionType.RIGHT);

            attach_next_to (mask_head, ip6address_head, Gtk.PositionType.BOTTOM);
            attach_next_to (mask, mask_head, Gtk.PositionType.RIGHT);

            attach_next_to (router_head, mask_head, Gtk.PositionType.BOTTOM);
            attach_next_to (router, router_head, Gtk.PositionType.RIGHT);

            attach_next_to (broadcast_head, router_head, Gtk.PositionType.BOTTOM);
            attach_next_to (broadcast, broadcast_head, Gtk.PositionType.RIGHT);

            attach_next_to (send_receive_grid, broadcast_head, Gtk.PositionType.BOTTOM, 4, 1);

            device.state_changed.connect (() => { 
                update_status ();
                info_changed ();
            });

            update_status ();

            show_all ();
        }

        public void update_activity (string sent_bytes, string received_bytes) {
            sent.label = sent_bytes ?? UNKNOWN_STR;
            received.label = received_bytes ?? UNKNOWN_STR;
        }

        public void update_status () {
            var ipv4 = device.get_ip4_config ();
            if (ipv4 != null) {
                unowned NM.IP4Address address = ipv4.get_addresses ().nth_data (0);
                if (address != null) {
                    var address_bytes = address.get_address ();
                    var source_addr = Posix.InAddr () { s_addr = address_bytes };
                    ip4address.label = (Posix.inet_ntoa (source_addr) ?? UNKNOWN_STR);
                    uint32 mask_addr = ~((uint32)0xffffffff << address.get_prefix ());
                    source_addr.s_addr = mask_addr;
                    mask.label = (Posix.inet_ntoa (source_addr) ?? UNKNOWN_STR);
                    source_addr.s_addr = address_bytes | (~mask_addr);
                    broadcast.label = (Posix.inet_ntoa (source_addr) ?? UNKNOWN_STR);
                }

                router.label =  (ipv4.get_gateway () ?? UNKNOWN_STR);
            } else {
                ip4address.label = UNKNOWN_STR;
                mask.label =  UNKNOWN_STR;
                router.label = UNKNOWN_STR;
                broadcast.label = UNKNOWN_STR;
            }

            var ip6 = device.get_ip6_config ();
            ip6address.visible = ip6address_head.visible = (ip6 != null);
            ip6address.label = "";
            if (ip6 != null) {
                int i = 1;
                SList<NM.IP6Address> addresses = ip6.get_addresses ().copy ();
                addresses.@foreach ((addr) => {
                    addr.@ref ();
                    var inet = new InetAddress.from_bytes (addr.get_address (), SocketFamily.IPV6);
                    string inet_str = inet.to_string () + "/" + addr.get_prefix ().to_string ();
                    ip6address.visible = ip6address_head.visible = (inet_str.strip () != "");
                    ip6address.label += inet_str;
                    if (i < addresses.length ()) {
                        ip6address.label += "\n";
                    }

                    i++;
                });         
            }


            if (owner != null) {
                update_sidebar (owner);
            }

            this.show_all ();
        }
    }
}
