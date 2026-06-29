namespace Queue.Tasks {

    // Data layer for tasks. The only place that runs SQL for tasks.
    public class Task : Object
    {

        public int id { get; set; }
        public int group_id { get; set; }
        public string title { get; set; }
        public string description { get; set; default = ""; }
        public bool done { get; set; }
        public bool important { get; set; default = false; }
        public string completed_at { get; set; default = ""; }

        public static GLib.List<Task> for_group(Database database, int group_id)
        {
            var tasks = new GLib.List<Task> ();

            Sqlite.Statement statement;
            database.connection.prepare_v2(
                "SELECT id, group_id, title, description, done, important, completed_at FROM tasks WHERE group_id = ? ORDER BY position, id;",
                -1,
                out statement);
            statement.bind_int(1, group_id);

            while (statement.step() == Sqlite.ROW) {
                var task = new Task();
                task.id = statement.column_int(0);
                task.group_id = statement.column_int(1);
                task.title = statement.column_text(2);
                task.description = statement.column_text(3);
                task.done = statement.column_int(4) != 0;
                task.important = statement.column_int(5) != 0;
                task.completed_at = statement.column_text(6);
                tasks.append(task);
            }

            return tasks;
        }

        public static Task create(Database database, int group_id, string title, string description,
            bool important)
        {
            Sqlite.Statement statement;
            database.connection.prepare_v2(
                "INSERT INTO tasks (group_id, title, description, important, position) VALUES (?, ?, ?, ?, "
                + "(SELECT COALESCE(MAX(position), -1) + 1 FROM tasks WHERE group_id = ?));",
                -1, out statement);
            statement.bind_int(1, group_id);
            statement.bind_text(2, title);
            statement.bind_text(3, description);
            statement.bind_int(4, important ? 1 : 0);
            statement.bind_int(5, group_id);
            statement.step();

            var task = new Task();
            task.id = (int) database.connection.last_insert_rowid();
            task.group_id = group_id;
            task.title = title;
            task.description = description;
            task.done = false;
            task.important = important;
            return task;
        }

        public static void update(Database database, int id, string title, string description,
            bool important)
        {
            Sqlite.Statement statement;
            database.connection.prepare_v2(
                "UPDATE tasks SET title = ?, description = ?, important = ? WHERE id = ?;",
                -1, out statement);
            statement.bind_text(1, title);
            statement.bind_text(2, description);
            statement.bind_int(3, important ? 1 : 0);
            statement.bind_int(4, id);
            statement.step();
        }

        public static void mark_done(Database database, int id, bool done)
        {
            Sqlite.Statement statement;
            database.connection.prepare_v2(
                "UPDATE tasks SET done = ?, completed_at = CASE WHEN ? = 1 THEN datetime('now') ELSE '' END WHERE id = ?;",
                -1, out statement);
            statement.bind_int(1, done ? 1 : 0);
            statement.bind_int(2, done ? 1 : 0);
            statement.bind_int(3, id);
            statement.step();
        }

        // Restores the completion state verbatim, keeping the original
        // completed_at timestamp instead of stamping the current time. Used
        // when importing a backup.
        public static void restore_completion(Database database, int id, bool done, string completed_at)
        {
            Sqlite.Statement statement;
            database.connection.prepare_v2(
                "UPDATE tasks SET done = ?, completed_at = ? WHERE id = ?;", -1, out statement);
            statement.bind_int(1, done ? 1 : 0);
            statement.bind_text(2, completed_at);
            statement.bind_int(3, id);
            statement.step();
        }

        public static void destroy(Database database, int id)
        {
            Sqlite.Statement statement;
            database.connection.prepare_v2(
                "DELETE FROM tasks WHERE id = ?;", -1, out statement);
            statement.bind_int(1, id);
            statement.step();
        }

        // Stores the given identifiers as the new ordering (index = position).
        public static void reorder(Database database, int[] ordered_ids)
        {
            database.connection.exec("BEGIN TRANSACTION;");

            Sqlite.Statement statement;
            database.connection.prepare_v2(
                "UPDATE tasks SET position = ? WHERE id = ?;", -1, out statement);
            for (int position = 0; position < ordered_ids.length; position++) {
                statement.reset();
                statement.bind_int(1, position);
                statement.bind_int(2, ordered_ids[position]);
                statement.step();
            }

            database.connection.exec("COMMIT;");
        }
    }
}
