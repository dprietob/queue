namespace Collie.Groups {

    // Validates the data used to create or rename a group.
    public class GroupStoreValidator : Object
    {

        private const int MAXIMUM_LENGTH = 100;

        private string name;

        public GroupStoreValidator (string name)
        {
            this.name = name;
        }

        public HashTable<string, string> rules()
        {
            var rules = new HashTable<string, string> (str_hash, str_equal);
            rules.set("name", "required|max:%d".printf(MAXIMUM_LENGTH));
            return rules;
        }

        public HashTable<string, string> messages()
        {
            var messages = new HashTable<string, string> (str_hash, str_equal);
            messages.set("name.required", _("The group name cannot be empty."));
            messages.set("name.max",
                _("The group name must be at most %d characters.").printf(MAXIMUM_LENGTH));
            return messages;
        }

        // Returns the first validation error message, or null when the data is valid.
        public string? validate()
        {
            var value = name.strip();
            var messages = this.messages();

            if (value == "") {
                return messages.get("name.required");
            }
            if (value.char_count() > MAXIMUM_LENGTH) {
                return messages.get("name.max");
            }
            return null;
        }
    }
}
