plug_files = files(
    'Utils.vala',
    'rfkill.vala',
    'Plug.vala',
    'MainView.vala',
    'NetworkManager.vala',
    'Views/EthernetPage.vala',
    'Views/HotspotPage.vala',
    'Views/ModemPage.vala',
    'Views/ProxyPage.vala',
    'Views/VPNPage.vala',
    'Views/WifiPage.vala',
    'Widgets/Page.vala',
    'Widgets/InfoBox.vala',
    'Widgets/DeviceItem.vala',
    'Widgets/WifiMenuItem.vala',
    'Widgets/Proxy/ProxyExceptionsPage.vala',
    'Widgets/Proxy/ProxyConfigurationPage.vala',
    'Widgets/VPN/VPNConnectionDialog.vala',
    'Widgets/VPN/VPNInfoDialog.vala',
    'Widgets/VPN/VPNMenuItem.vala'
)

switchboard_dep = dependency('switchboard-3')
switchboard_plugsdir = switchboard_dep.get_pkgconfig_variable('plugsdir', define_variable: ['libdir', libdir])

libnm_dep = dependency('libnm', version: '>=1.24')

args = []
if libnm_dep.version().version_compare('>=1.43.3')
    args += '--define=HAS_NM_1_43'
endif

shared_module(
    meson.project_name(),
    plug_files,
    config_file,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite-7', version: '>=7.4.0'),
        dependency('gtk4'),
        dependency('libadwaita-1', version: '>=1.4'),
        libnm_dep,
        dependency('libnma-gtk4'),
        meson.get_compiler('vala').find_library('posix'),
        switchboard_dep
    ],
    vala_args: args,
    install: true,
    install_dir : join_paths(switchboard_plugsdir, 'network')
)
