namespace Collie {

    public class CreateGroupsTable : Object, Migration
    {

        public int version {
            get { return 1; }
        }

        public string up()
        {
            return
                """
                CREATE TABLE groups (
                    id         INTEGER PRIMARY KEY AUTOINCREMENT,
                    name       TEXT    NOT NULL,
                    color      TEXT    NOT NULL DEFAULT '',
                    created_at TEXT    NOT NULL DEFAULT (datetime('now'))
                );
            """;
        }
    }
}
