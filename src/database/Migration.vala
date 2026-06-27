namespace Queue {

    // Represents a single, ordered schema change applied to the SQLite database.
    public interface Migration : Object
    {

        public abstract int version { get; }

        // Returns the SQL statements that apply this migration.
        public abstract string up();
    }
}
