namespace Collie.Tasks {

    public class CreateTaskAction : Object
    {

        private Database database;

        public CreateTaskAction (Database database)
        {
            this.database = database;
        }

        public Task execute(int group_id, string title)
        {
            return Task.create(database, group_id, title);
        }
    }
}
