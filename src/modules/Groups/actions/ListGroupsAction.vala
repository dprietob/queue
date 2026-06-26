namespace Collie.Groups {

    public class ListGroupsAction : Object
    {

        private Database database;

        public ListGroupsAction (Database database)
        {
            this.database = database;
        }

        public GLib.List<Group> execute()
        {
            return Group.all(database);
        }
    }
}
