project(
    'network',
    'vala', 'c',
    version: '8.2.0'
)

gettext_name = 'io.elementary.settings.' + meson.project_name()
gnome = import('gnome')
i18n = import('i18n')

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
libdir = join_paths(prefix, get_option('libdir'))

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
    '-DG_LOG_DOMAIN="@0@"'.format(gettext_name),
    language:'c'
)

add_project_arguments(
    '--vapidir', join_paths(meson.current_source_dir(), 'vapi'),
    language: 'vala'
)

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
config_data.set_quoted('GETTEXT_PACKAGE', gettext_name)
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

subdir('data')
subdir('src')
subdir('po')

vapigen = find_program('vapigen', required: false)
g_ir_dep = dependency('gobject-introspection-1.0', required: false)
if vapigen.found() and g_ir_dep.found()
    subdir('vapi')
endif
