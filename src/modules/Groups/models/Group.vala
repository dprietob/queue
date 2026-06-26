namespace Collie.Groups {

    // Data layer for task groups. The only place that runs SQL for groups.
    public class Group : Object
    {

        public int id { get; set; }
        public string name { get; set; }

        public static GLib.List<Group> all(Database database)
        {
            var groups = new GLib.List<Group> ();

            Sqlite.Statement statement;
            database.connection.prepare_v2(
                "SELECT id, name FROM groups ORDER BY name COLLATE NOCASE;", -1, out statement);

            while (statement.step() == Sqlite.ROW) {
                var group = new Group();
                group.id = statement.column_int(0);
                group.name = statement.column_text(1);
                groups.append(group);
            }

            return groups;
        }

        public static Group create(Database database, string name)
        {
            Sqlite.Statement statement;
            database.connection.prepare_v2(
                "INSERT INTO groups (name) VALUES (?);", -1, out statement);
            statement.bind_text(1, name);
            statement.step();

            var group = new Group();
            group.id = (int) database.connection.last_insert_rowid();
            group.name = name;
            return group;
        }

        public static void rename(Database database, int id, string name)
        {
            Sqlite.Statement statement;
            database.connection.prepare_v2(
                "UPDATE groups SET name = ? WHERE id = ?;", -1, out statement);
            statement.bind_text(1, name);
            statement.bind_int(2, id);
            statement.step();
        }

        public static void destroy(Database database, int id)
        {
            Sqlite.Statement statement;
            database.connection.prepare_v2(
                "DELETE FROM groups WHERE id = ?;", -1, out statement);
            statement.bind_int(1, id);
            statement.step();
        }
    }
}
