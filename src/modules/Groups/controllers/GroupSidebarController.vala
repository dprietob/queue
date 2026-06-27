namespace Queue.Groups {

    // Coordinates the group sidebar: it runs validators and actions, and keeps
    // the list model that the UI binds to in sync with the database.
    public class GroupSidebarController : Object
    {

        private ListGroupsAction list_groups_action;
        private CreateGroupAction create_group_action;
        private UpdateGroupAction update_group_action;
        private DeleteGroupAction delete_group_action;
        private ReorderGroupsAction reorder_groups_action;

        public GLib.ListStore groups { get; private set; }

        public GroupSidebarController (Database database)
        {
            list_groups_action = new ListGroupsAction(database);
            create_group_action = new CreateGroupAction(database);
            update_group_action = new UpdateGroupAction(database);
            delete_group_action = new DeleteGroupAction(database);
            reorder_groups_action = new ReorderGroupsAction(database);

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

        // Moves a group before or after a target group and persists the order.
        public void move(Group dragged, Group target, bool after)
        {
            if (dragged == target) {
                return;
            }

            uint from;
            if (!groups.find(dragged, out from)) {
                return;
            }
            groups.remove(from);

            uint target_index;
            if (groups.find(target, out target_index)) {
                groups.insert(after ? target_index + 1 : target_index, dragged);
            } else {
                groups.append(dragged);
            }

            persist_order();
        }

        private void persist_order()
        {
            int[] ordered_ids = {};
            for (uint index = 0; index < groups.get_n_items(); index++) {
                ordered_ids += ((Group) groups.get_item(index)).id;
            }
            reorder_groups_action.execute(ordered_ids);
        }
    }
}
