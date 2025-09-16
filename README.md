# Networking Settings
[![Packaging status](https://repology.org/badge/tiny-repos/switchboard-plug-networking.svg)](https://repology.org/project/switchboard-plug-networking/versions)
[![Translation status](https://l10n.elementaryos.org/widget/settings/network/svg-badge.svg)](https://l10n.elementaryos.org/engage/settings/)

![screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* libgranite-7-dev >= 7.4.0
* libnm-dev
* libnma-gtk4-dev
* libswitchboard-3-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    ninja install
