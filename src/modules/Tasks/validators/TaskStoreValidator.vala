namespace Collie.Tasks {

    // Validates the data used to create or edit a task.
    public class TaskStoreValidator : Object
    {

        public const int MAXIMUM_TITLE_LENGTH = 255;
        public const int MAXIMUM_DESCRIPTION_LENGTH = 500;

        private string title;
        private string description;

        public TaskStoreValidator (string title, string description)
        {
            this.title = title;
            this.description = description;
        }

        public HashTable<string, string> rules()
        {
            var rules = new HashTable<string, string> (str_hash, str_equal);
            rules.set("title", "required|max:%d".printf(MAXIMUM_TITLE_LENGTH));
            rules.set("description", "max:%d".printf(MAXIMUM_DESCRIPTION_LENGTH));
            return rules;
        }

        public HashTable<string, string> messages()
        {
            var messages = new HashTable<string, string> (str_hash, str_equal);
            messages.set("title.required", _("The task title cannot be empty."));
            messages.set("title.max",
                _("The task title must be at most %d characters.").printf(MAXIMUM_TITLE_LENGTH));
            messages.set("description.max",
                _("The description must be at most %d characters.").printf(MAXIMUM_DESCRIPTION_LENGTH));
            return messages;
        }

        // Returns the first validation error message, or null when the data is valid.
        public string? validate()
        {
            var title_value = title.strip();
            var messages = this.messages();

            if (title_value == "") {
                return messages.get("title.required");
            }
            if (title_value.char_count() > MAXIMUM_TITLE_LENGTH) {
                return messages.get("title.max");
            }
            if (description.strip().char_count() > MAXIMUM_DESCRIPTION_LENGTH) {
                return messages.get("description.max");
            }
            return null;
        }
    }
}
