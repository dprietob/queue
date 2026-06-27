namespace Queue.Tasks {

    // Marks a task as completed or pending.
    public class ToggleTaskAction : Object
    {

        private Database database;

        public ToggleTaskAction (Database database)
        {
            this.database = database;
        }

        public void execute(int id, bool done)
        {
            Task.mark_done(database, id, done);
        }
    }
}
