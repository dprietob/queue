namespace Collie.Tasks {

    public class UpdateTaskAction : Object
    {

        private Database database;

        public UpdateTaskAction (Database database)
        {
            this.database = database;
        }

        public void execute(int id, string title, string description)
        {
            Task.update(database, id, title, description);
        }
    }
}
