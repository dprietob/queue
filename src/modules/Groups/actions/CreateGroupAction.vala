namespace Queue.Groups {

    public class CreateGroupAction : Object
    {

        private Database database;

        public CreateGroupAction (Database database)
        {
            this.database = database;
        }

        public Group execute(string name, string color)
        {
            return Group.create(database, name, color);
        }
    }
}
