namespace Collie.Groups {

    public class CreateGroupAction : Object
    {

        private Database database;

        public CreateGroupAction (Database database)
        {
            this.database = database;
        }

        public Group execute(string name)
        {
            return Group.create(database, name);
        }
    }
}
