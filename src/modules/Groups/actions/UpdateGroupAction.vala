namespace Collie.Groups {

    public class UpdateGroupAction : Object
    {

        private Database database;

        public UpdateGroupAction (Database database)
        {
            this.database = database;
        }

        public void execute(int id, string name, string color)
        {
            Group.update(database, id, name, color);
        }
    }
}
