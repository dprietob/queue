namespace Queue {

    // Owns the SQLite connection and keeps the schema up to date.
    // It is the single entry point models use to reach the database.
    public class Database : Object
    {

        public Sqlite.Database connection;

        public Database () throws Error
        {
            open_connection();
            connection.exec("PRAGMA foreign_keys = ON;");
            migrate();
        }

        private void open_connection() throws Error
        {
            var directory = Path.build_filename(Environment.get_user_data_dir(), "queue");
            DirUtils.create_with_parents(directory, 0755);

            var path = Path.build_filename(directory, "queue.db");
            if (Sqlite.Database.open_v2(path, out connection) != Sqlite.OK) {
                throw new IOError.FAILED(
                          "Unable to open the database: %s".printf(connection.errmsg()));
            }
        }

        // Applies every migration whose version is newer than the one stored
        // in the database, tracking progress with PRAGMA user_version.
        private void migrate() throws Error
        {
            Migration[] migrations = {
                new CreateGroupsTable(),
                new CreateTasksTable(),
                new AddCompletedAtToTasks(),
            };

            var applied_version = current_version();
            foreach (var migration in migrations) {
                if (migration.version <= applied_version) {
                    continue;
                }
                if (connection.exec(migration.up()) != Sqlite.OK) {
                    throw new IOError.FAILED(
                              "Migration %d failed: %s".printf(migration.version, connection.errmsg()));
                }
                // The version is an internal integer, never user input.
                connection.exec("PRAGMA user_version = %d;".printf(migration.version));
            }
        }

        private int current_version()
        {
            Sqlite.Statement statement;
            connection.prepare_v2("PRAGMA user_version;", -1, out statement);
            statement.step();
            return statement.column_int(0);
        }
    }
}
