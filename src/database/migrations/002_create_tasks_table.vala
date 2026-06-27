namespace Queue {

    public class CreateTasksTable : Object, Migration
    {

        public int version {
            get { return 2; }
        }

        public string up()
        {
            return
                """
                CREATE TABLE tasks (
                    id          INTEGER PRIMARY KEY AUTOINCREMENT,
                    group_id    INTEGER NOT NULL,
                    title       TEXT    NOT NULL,
                    description TEXT    NOT NULL DEFAULT '',
                    done        INTEGER NOT NULL DEFAULT 0,
                    important   INTEGER NOT NULL DEFAULT 0,
                    position   INTEGER NOT NULL DEFAULT 0,
                    created_at TEXT    NOT NULL DEFAULT (datetime('now')),
                    FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
                );
            """;
        }
    }
}
