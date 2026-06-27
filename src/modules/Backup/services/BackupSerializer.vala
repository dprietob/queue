namespace Queue.Backup {

    // In-memory representation of a backed-up task.
    public class BackupTask : Object
    {
        public string title { get; set; default = ""; }
        public string description { get; set; default = ""; }
        public bool done { get; set; default = false; }
        public bool important { get; set; default = false; }
    }

    // In-memory representation of a backed-up group with its tasks.
    public class BackupGroup : Object
    {
        public string name { get; set; default = ""; }
        public string color { get; set; default = ""; }
        public BackupTask[] tasks;
    }

    // Converts the backup data to and from its JSON representation.
    public class BackupSerializer : Object
    {

        private const int FORMAT_VERSION = 1;

        public string to_json(BackupGroup[] groups)
        {
            var builder = new Json.Builder();
            builder.begin_object();

            builder.set_member_name("version");
            builder.add_int_value(FORMAT_VERSION);

            builder.set_member_name("groups");
            builder.begin_array();
            foreach (var group in groups) {
                write_group(builder, group);
            }
            builder.end_array();

            builder.end_object();

            var generator = new Json.Generator();
            generator.set_root(builder.get_root());
            generator.pretty = true;
            return generator.to_data(null);
        }

        public BackupGroup[] from_json(string contents) throws Error
        {
            var parser = new Json.Parser();
            parser.load_from_data(contents);

            var root = parser.get_root();
            if (root == null || root.get_node_type() != Json.NodeType.OBJECT) {
                throw new IOError.INVALID_DATA(_("The backup file is not valid."));
            }

            var root_object = root.get_object();
            if (!root_object.has_member("groups")) {
                return {};
            }

            BackupGroup[] groups = {};
            foreach (var group_node in root_object.get_array_member("groups").get_elements()) {
                groups += read_group(group_node.get_object());
            }
            return groups;
        }

        private void write_group(Json.Builder builder, BackupGroup group)
        {
            builder.begin_object();

            builder.set_member_name("name");
            builder.add_string_value(group.name);
            builder.set_member_name("color");
            builder.add_string_value(group.color);

            builder.set_member_name("tasks");
            builder.begin_array();
            foreach (var task in group.tasks) {
                builder.begin_object();
                builder.set_member_name("title");
                builder.add_string_value(task.title);
                builder.set_member_name("description");
                builder.add_string_value(task.description);
                builder.set_member_name("done");
                builder.add_boolean_value(task.done);
                builder.set_member_name("important");
                builder.add_boolean_value(task.important);
                builder.end_object();
            }
            builder.end_array();

            builder.end_object();
        }

        private BackupGroup read_group(Json.Object group_object)
        {
            var group = new BackupGroup();
            if (group_object.has_member("name")) {
                group.name = group_object.get_string_member("name");
            }
            if (group_object.has_member("color")) {
                group.color = group_object.get_string_member("color");
            }

            BackupTask[] tasks = {};
            if (group_object.has_member("tasks")) {
                foreach (var task_node in group_object.get_array_member("tasks").get_elements()) {
                    tasks += read_task(task_node.get_object());
                }
            }
            group.tasks = tasks;
            return group;
        }

        private BackupTask read_task(Json.Object task_object)
        {
            var task = new BackupTask();
            if (task_object.has_member("title")) {
                task.title = task_object.get_string_member("title");
            }
            if (task_object.has_member("description")) {
                task.description = task_object.get_string_member("description");
            }
            if (task_object.has_member("done")) {
                task.done = task_object.get_boolean_member("done");
            }
            if (task_object.has_member("important")) {
                task.important = task_object.get_boolean_member("important");
            }
            return task;
        }
    }
}
