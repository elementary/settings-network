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

public enum Network.State {
    DISCONNECTED,
    WIRED_UNPLUGGED,
    CONNECTED_WIRED,
    CONNECTED_VPN,
    CONNECTED_MOBILE,
    CONNECTED_WIFI,
    CONNECTED_WIFI_WEAK,
    CONNECTED_WIFI_OK,
    CONNECTED_WIFI_GOOD,
    CONNECTED_WIFI_EXCELLENT,
    CONNECTING_WIFI,
    CONNECTING_WIRED,
    CONNECTING_MOBILE,
    CONNECTING_VPN,
    FAILED_WIRED,
    FAILED_WIFI,
    FAILED_MOBILE,
    FAILED_VPN
}

namespace Network.Common.Utils {
    public string network_state_to_string (Network.State state) {
        switch(state) {
        case Network.State.DISCONNECTED:
            return _("Disconnected");
        case Network.State.CONNECTED_WIFI:
        case Network.State.CONNECTED_WIFI_WEAK:
        case Network.State.CONNECTED_WIFI_OK:
        case Network.State.CONNECTED_WIFI_GOOD:
        case Network.State.CONNECTED_WIFI_EXCELLENT:
        case Network.State.CONNECTED_WIRED:
        case Network.State.CONNECTED_VPN:
        case Network.State.CONNECTED_MOBILE:
            return _("Connected");
        case Network.State.FAILED_WIRED:
        case Network.State.FAILED_WIFI:
        case Network.State.FAILED_VPN:
        case Network.State.FAILED_MOBILE:
            return _("Failed");
        case Network.State.CONNECTING_WIFI:
        case Network.State.CONNECTING_WIRED:
        case Network.State.CONNECTING_VPN:
        case Network.State.CONNECTING_MOBILE:
            return _("Connecting");
        case Network.State.WIRED_UNPLUGGED:
            return _("Cable unplugged");
        }
        return UNKNOWN_STR;
    }
}

