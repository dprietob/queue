namespace Queue.Groups {

    public class ReorderGroupsAction : Object
    {

        private Database database;

        public ReorderGroupsAction (Database database)
        {
            this.database = database;
        }

        public void execute(int[] ordered_ids)
        {
            Group.reorder(database, ordered_ids);
        }
    }
}
