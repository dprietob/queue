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

        public string? create(string name, string color)
        {
            var error = new GroupStoreValidator(name).validate();
            if (error != null) {
                return error;
            }
            groups.append(create_group_action.execute(name.strip(), color));
            return null;
        }

        public string? update(Group group, string name, string color)
        {
            var error = new GroupStoreValidator(name).validate();
            if (error != null) {
                return error;
            }
            update_group_action.execute(group.id, name.strip(), color);
            group.name = name.strip();
            group.color = color;
            return null;
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
