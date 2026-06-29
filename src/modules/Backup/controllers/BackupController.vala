namespace Queue.Backup {

    public delegate void ProgressFunc(double fraction);
    // Reports completion: error is null on success, or a message on failure.
    public delegate void DoneFunc(string ? error);

    // Coordinates exporting and importing backups, reporting progress as each
    // group is processed so the UI can show a progress bar.
    public class BackupController : Object
    {

        private Groups.ListGroupsAction list_groups_action;
        private Tasks.ListTasksByGroupAction list_tasks_action;
        private WipeDataAction wipe_data_action;
        private ImportGroupAction import_group_action;
        private BackupSerializer serializer;

        public BackupController (Database database)
        {
            list_groups_action = new Groups.ListGroupsAction(database);
            list_tasks_action = new Tasks.ListTasksByGroupAction(database);
            wipe_data_action = new WipeDataAction(database);
            import_group_action = new ImportGroupAction(database);
            serializer = new BackupSerializer();
        }

        // Reads every group and its tasks (one group per main-loop iteration),
        // then writes the resulting JSON to the chosen file.
        public void export(File file, owned ProgressFunc progress, owned DoneFunc done)
        {
            Queue.Groups.Group[] groups = {};
            foreach (var group in list_groups_action.execute()) {
                groups += group;
            }

            BackupGroup[] backup = {};
            uint index = 0;

            Idle.add(() => {
                if (index >= groups.length) {
                    try {
                        write_file(file, serializer.to_json(backup));
                        progress(1.0);
                        done(null);
                    } catch (Error error) {
                        done(error.message);
                    }
                    return Source.REMOVE;
                }

                backup += build_backup_group(groups[index]);
                index++;
                progress((double) index / (double) groups.length);
                return Source.CONTINUE;
            });
        }

        // Replaces all data with the contents of the backup file, inserting one
        // group (with its tasks) per main-loop iteration.
        public void import(File file, owned ProgressFunc progress, owned DoneFunc done)
        {
            BackupGroup[] groups;
            try {
                uint8[] contents;
                file.load_contents(null, out contents, null);
                groups = serializer.from_json((string) contents);
            } catch (Error error) {
                done(error.message);
                return;
            }

            wipe_data_action.execute();
            uint index = 0;

            Idle.add(() => {
                if (index >= groups.length) {
                    progress(1.0);
                    done(null);
                    return Source.REMOVE;
                }

                import_group_action.execute(groups[index]);
                index++;
                progress((double) index / (double) (groups.length == 0 ? 1 : groups.length));
                return Source.CONTINUE;
            });
        }

        private BackupGroup build_backup_group(Queue.Groups.Group group)
        {
            var backup_group = new BackupGroup();
            backup_group.name = group.name;
            backup_group.color = group.color;

            BackupTask[] tasks = {};
            foreach (var task in list_tasks_action.execute(group.id)) {
                var backup_task = new BackupTask();
                backup_task.title = task.title;
                backup_task.description = task.description;
                backup_task.done = task.done;
                backup_task.important = task.important;
                backup_task.completed_at = task.completed_at;
                tasks += backup_task;
            }
            backup_group.tasks = tasks;
            return backup_group;
        }

        private void write_file(File file, string contents) throws Error
        {
            string new_etag;
            file.replace_contents(contents.data, null, false,
                FileCreateFlags.REPLACE_DESTINATION, out new_etag, null);
        }
    }
}
