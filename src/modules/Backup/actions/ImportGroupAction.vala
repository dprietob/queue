namespace Collie.Backup {

    // Persists a single backed-up group together with all of its tasks.
    public class ImportGroupAction : Object
    {

        private Database database;

        public ImportGroupAction (Database database)
        {
            this.database = database;
        }

        public void execute(BackupGroup group)
        {
            var created = Collie.Groups.Group.create(database,
                    group.name,
                    group.color);
            foreach (var task in group.tasks) {
                var stored = Collie.Tasks.Task.create(database, created.id, task.title, task.description,
                        task.important);
                if (task.done) {
                    Collie.Tasks.Task.mark_done(database, stored.id, true);
                }
            }
        }
    }
}
