namespace Queue.Backup {

    // Deletes every group and, by cascade, every task.
    public class WipeDataAction : Object
    {

        private Database database;

        public WipeDataAction (Database database)
        {
            this.database = database;
        }

        public void execute()
        {
            Queue.Groups.Group.destroy_all(database);
        }
    }
}
