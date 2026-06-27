i18n.merge_file(
  input: 'com.dprietob.queue.desktop.in',
  output: 'com.dprietob.queue.desktop',
  type: 'desktop',
  po_dir: '../po',
  install: true,
  install_dir: get_option('datadir') / 'applications',
)

i18n.merge_file(
  input: 'com.dprietob.queue.appdata.xml.in',
  output: 'com.dprietob.queue.appdata.xml',
  po_dir: '../po',
  install: true,
  install_dir: get_option('datadir') / 'metainfo',
)

install_data(
  'icons/hicolor/256x256/apps/com.dprietob.queue.png',
  install_dir: get_option('datadir') / 'icons/hicolor/256x256/apps',
)

install_data(
  'com.dprietob.queue.gschema.xml',
  install_dir: get_option('datadir') / 'glib-2.0' / 'schemas',
)

# Compile the schema into the build tree so the app runs uninstalled, and
# recompile the installed schemas after `ninja install`.
gnome.compile_schemas(
  build_by_default: true,
  depend_files: files('com.dprietob.queue.gschema.xml'),
)
gnome.post_install(glib_compile_schemas: true)