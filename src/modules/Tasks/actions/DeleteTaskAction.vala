namespace Collie.Tasks {

    public class DeleteTaskAction : Object
    {

        private Database database;

        public DeleteTaskAction (Database database)
        {
            this.database = database;
        }

        public void execute(int id)
        {
            Task.destroy(database, id);
        }
    }
}
