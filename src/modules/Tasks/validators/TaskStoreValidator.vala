namespace Collie.Tasks {

    // Validates the data used to create or edit a task.
    public class TaskStoreValidator : Object
    {

        private const int MAXIMUM_LENGTH = 255;

        private string title;

        public TaskStoreValidator (string title)
        {
            this.title = title;
        }

        public HashTable<string, string> rules()
        {
            var rules = new HashTable<string, string> (str_hash, str_equal);
            rules.set("title", "required|max:%d".printf(MAXIMUM_LENGTH));
            return rules;
        }

        public HashTable<string, string> messages()
        {
            var messages = new HashTable<string, string> (str_hash, str_equal);
            messages.set("title.required", _("The task description cannot be empty."));
            messages.set("title.max",
                _("The task description must be at most %d characters.").printf(MAXIMUM_LENGTH));
            return messages;
        }

        // Returns the first validation error message, or null when the data is valid.
        public string? validate()
        {
            var value = title.strip();
            var messages = this.messages();

            if (value == "") {
                return messages.get("title.required");
            }
            if (value.char_count() > MAXIMUM_LENGTH) {
                return messages.get("title.max");
            }
            return null;
        }
    }
}
