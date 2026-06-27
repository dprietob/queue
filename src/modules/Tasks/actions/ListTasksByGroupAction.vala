namespace Queue.Tasks {

    public class ListTasksByGroupAction : Object
    {

        private Database database;

        public ListTasksByGroupAction (Database database)
        {
            this.database = database;
        }

        public GLib.List<Task> execute(int group_id)
        {
            return Task.for_group(database, group_id);
        }
    }
}
