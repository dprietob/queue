namespace Queue.Tasks {

    public class ReorderTasksAction : Object
    {

        private Database database;

        public ReorderTasksAction (Database database)
        {
            this.database = database;
        }

        public void execute(int[] ordered_ids)
        {
            Task.reorder(database, ordered_ids);
        }
    }
}
