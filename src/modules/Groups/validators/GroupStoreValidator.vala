namespace Queue.Groups {

    // Validates the data used to create or rename a group. The names of the
    // other existing groups are provided so duplicates can be rejected.
    public class GroupStoreValidator : Object
    {

        public const int MAXIMUM_LENGTH = 100;

        private string name;
        private string[] existing_names;

        public GroupStoreValidator (string name, string[] existing_names)
        {
            this.name = name;
            this.existing_names = existing_names;
        }

        public HashTable<string, string> rules()
        {
            var rules = new HashTable<string, string> (str_hash, str_equal);
            rules.set("name", "required|max:%d|unique".printf(MAXIMUM_LENGTH));
            return rules;
        }

        public HashTable<string, string> messages()
        {
            var messages = new HashTable<string, string> (str_hash, str_equal);
            messages.set("name.required", _("The group name cannot be empty."));
            messages.set("name.max",
                _("The group name must be at most %d characters.").printf(MAXIMUM_LENGTH));
            messages.set("name.unique", _("A group with this name already exists."));
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
            if (is_duplicate(value)) {
                return messages.get("name.unique");
            }
            return null;
        }

        // Compares case-insensitively against the other groups' names.
        private bool is_duplicate(string value)
        {
            var folded = value.casefold();
            foreach (var existing in existing_names) {
                if (existing.strip().casefold() == folded) {
                    return true;
                }
            }
            return false;
        }
    }
}
