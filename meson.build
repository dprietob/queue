project(
  'collie',
  ['vala', 'c'],
  version: '1.0.0',
  meson_version: '>= 0.62.0',
  default_options: ['warning_level=2'],
)

gnome = import('gnome')
i18n = import('i18n')

add_project_arguments(
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  language: 'c',
)

subdir('data')
subdir('po')
subdir('src')