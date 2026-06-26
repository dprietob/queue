i18n.merge_file(
  input: 'com.dprietob.collie.desktop.in',
  output: 'com.dprietob.collie.desktop',
  type: 'desktop',
  po_dir: '../po',
  install: true,
  install_dir: get_option('datadir') / 'applications',
)

i18n.merge_file(
  input: 'com.dprietob.collie.appdata.xml.in',
  output: 'com.dprietob.collie.appdata.xml',
  po_dir: '../po',
  install: true,
  install_dir: get_option('datadir') / 'metainfo',
)

install_data(
  'icons/hicolor/scalable/apps/com.dprietob.collie.svg',
  install_dir: get_option('datadir') / 'icons/hicolor/scalable/apps',
)

install_data(
  'com.dprietob.collie.gschema.xml',
  install_dir: get_option('datadir') / 'glib-2.0' / 'schemas',
)

# Compile the schema into the build tree so the app runs uninstalled, and
# recompile the installed schemas after `ninja install`.
gnome.compile_schemas(
  build_by_default: true,
  depend_files: files('com.dprietob.collie.gschema.xml'),
)
gnome.post_install(glib_compile_schemas: true)