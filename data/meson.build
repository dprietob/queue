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