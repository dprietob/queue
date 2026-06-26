# config.h se genera en _build/src/, que el compilador C ya tiene en su -I path
conf = configuration_data()
conf.set_quoted('CONFIG_APP_ID', 'com.dprietob.collie')
conf.set_quoted('CONFIG_GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('CONFIG_LOCALEDIR', get_option('prefix') / get_option('localedir'))
conf.set_quoted('CONFIG_VERSION', meson.project_version())
configure_file(output: 'config.h', configuration: conf)

collie_sources = files(
  'Main.vala',
)

cc = meson.get_compiler('c')

collie_deps = [
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.4'),
  cc.find_library('m'),
]

# Recursos (iconos svg)
collie_resources = gnome.compile_resources(
  'collie-resources',
  '../data/resources.gresource.xml',
  source_dir: '../data',
)

executable(
  'collie',
  collie_sources + collie_resources,
  files('Config.vapi'),
  dependencies: collie_deps,
  vala_args: ['--target-glib=2.76'],
  install: true,
)