namespace Collie.Groups {

    // Coordinates the group sidebar: it runs validators and actions, and keeps
    // the list model that the UI binds to in sync with the database.
    public class GroupSidebarController : Object
    {

        private ListGroupsAction list_groups_action;
        private CreateGroupAction create_group_action;
        private UpdateGroupAction update_group_action;
        private DeleteGroupAction delete_group_action;

        public GLib.ListStore groups { get; private set; }

        public GroupSidebarController (Database database)
        {
            list_groups_action = new ListGroupsAction(database);
            create_group_action = new CreateGroupAction(database);
            update_group_action = new UpdateGroupAction(database);
            delete_group_action = new DeleteGroupAction(database);

            groups = new GLib.ListStore(typeof (Group));
            load();
        }

        public void load()
        {
            groups.remove_all();
            foreach (var group in list_groups_action.execute()) {
                groups.append(group);
            }
        }

        public string? create(string name, string color, out Group ? created)
        {
            created = null;
            var error = new GroupStoreValidator(name, names_except(null)).validate();
            if (error != null) {
                return error;
            }
            created = create_group_action.execute(name.strip(), color);
            groups.append(created);
            return null;
        }

        public string? update(Group group, string name, string color)
        {
            var error = new GroupStoreValidator(name, names_except(group)).validate();
            if (error != null) {
                return error;
            }
            update_group_action.execute(group.id, name.strip(), color);
            group.name = name.strip();
            group.color = color;
            return null;
        }

        // Names of all groups except the given one, used to detect duplicates.
        private string[] names_except(Group ? excluded)
        {
            string[] names = {};
            for (uint index = 0; index < groups.get_n_items(); index++) {
                var group = (Group) groups.get_item(index);
                if (excluded != null && group.id == excluded.id) {
                    continue;
                }
                names += group.name;
            }
            return names;
        }

        public void remove(Group group)
        {
            delete_group_action.execute(group.id);

            uint position;
            if (groups.find(group, out position)) {
                groups.remove(position);
            }
        }
    }
}
