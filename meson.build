project(
  'queue',
  ['vala', 'c'],
  version: '1.1.0',
  meson_version: '>= 0.62.0',
  default_options: ['warning_level=2'],
)

gnome = import('gnome')
i18n = import('i18n')

config_data = configuration_data()
config_data.set_quoted('CONFIG_APP_ID', 'io.github.dprietob.queue')
config_data.set_quoted('CONFIG_GETTEXT_PACKAGE', meson.project_name())
config_data.set_quoted('CONFIG_LOCALEDIR', get_option('prefix') / get_option('localedir'))
config_data.set_quoted('CONFIG_VERSION', meson.project_version())
configure_file(output: 'config.h', configuration: config_data)

add_project_arguments(
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-I' + meson.current_build_dir(),
  language: 'c',
)

subdir('data')
subdir('po')

queue_sources = files(
  'src/Main.vala',
  'src/Window.vala',
  'src/database/Migration.vala',
  'src/database/Database.vala',
  'src/database/migrations/001_create_groups_table.vala',
  'src/database/migrations/002_create_tasks_table.vala',
  'src/database/migrations/003_add_completed_at_to_tasks.vala',
  'src/modules/Groups/models/Group.vala',
  'src/modules/Groups/validators/GroupStoreValidator.vala',
  'src/modules/Groups/actions/ListGroupsAction.vala',
  'src/modules/Groups/actions/CreateGroupAction.vala',
  'src/modules/Groups/actions/UpdateGroupAction.vala',
  'src/modules/Groups/actions/DeleteGroupAction.vala',
  'src/modules/Groups/actions/ReorderGroupsAction.vala',
  'src/modules/Groups/controllers/GroupSidebarController.vala',
  'src/modules/Groups/ui/GroupRow.vala',
  'src/modules/Groups/ui/GroupSidebar.vala',
  'src/modules/Tasks/models/Task.vala',
  'src/modules/Tasks/validators/TaskStoreValidator.vala',
  'src/modules/Tasks/actions/ListTasksByGroupAction.vala',
  'src/modules/Tasks/actions/CreateTaskAction.vala',
  'src/modules/Tasks/actions/UpdateTaskAction.vala',
  'src/modules/Tasks/actions/ToggleTaskAction.vala',
  'src/modules/Tasks/actions/DeleteTaskAction.vala',
  'src/modules/Tasks/actions/ReorderTasksAction.vala',
  'src/modules/Tasks/controllers/TaskListController.vala',
  'src/modules/Tasks/ui/TaskDescriptionMarkup.vala',
  'src/modules/Tasks/ui/DescriptionEditor.vala',
  'src/modules/Tasks/ui/TaskRow.vala',
  'src/modules/Tasks/ui/TaskListPanel.vala',
  'src/modules/Backup/services/BackupSerializer.vala',
  'src/modules/Backup/actions/WipeDataAction.vala',
  'src/modules/Backup/actions/ImportGroupAction.vala',
  'src/modules/Backup/controllers/BackupController.vala',
)

queue_dependencies = [
  dependency('gtk4', version: '>= 4.12'),
  dependency('libadwaita-1', version: '>= 1.5'),
  dependency('sqlite3'),
  dependency('json-glib-1.0'),
  meson.get_compiler('c').find_library('m'),
]

queue_resources = gnome.compile_resources(
  'queue-resources',
  'data/resources.gresource.xml',
  source_dir: '.',
)

executable(
  'queue',
  queue_sources + queue_resources,
  files('src/Config.vapi'),
  dependencies: queue_dependencies,
  vala_args: ['--target-glib=2.76'],
  install: true,
)
