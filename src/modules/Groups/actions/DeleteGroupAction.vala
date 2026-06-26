namespace Collie.Groups {

    public class DeleteGroupAction : Object
    {

        private Database database;

        public DeleteGroupAction (Database database)
        {
            this.database = database;
        }

        public void execute(int id)
        {
            Group.destroy(database, id);
        }
    }
}
