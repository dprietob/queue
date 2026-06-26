namespace Collie.Tasks {

    public class UpdateTaskAction : Object
    {

        private Database database;

        public UpdateTaskAction (Database database)
        {
            this.database = database;
        }

        public void execute(int id, string title)
        {
            Task.rename(database, id, title);
        }
    }
}
