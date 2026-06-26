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
                    position   INTEGER NOT NULL DEFAULT 0,
                    created_at TEXT    NOT NULL DEFAULT (datetime('now'))
                );
            """;
        }
    }
}
