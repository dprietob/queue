namespace Queue {

    public class AddCompletedAtToTasks : Object, Migration
    {

        public int version {
            get { return 3; }
        }

        public string up()
        {
            return
                """
                ALTER TABLE tasks ADD COLUMN completed_at TEXT NOT NULL DEFAULT '';
            """;
        }
    }
}
