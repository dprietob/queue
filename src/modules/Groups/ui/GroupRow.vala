namespace Queue.Groups {

    [GtkTemplate(ui = "/io/github/dprietob/queue/ui/group-row.ui")]
    public class GroupRow : Gtk.ListBoxRow
    {

        [GtkChild]
        private unowned Gtk.Label name_label;

        public Group group { get; private set; }

        public signal void edit_requested(Group group);
        public signal void delete_requested(Group group);

        public GroupRow (Group group)
        {
            this.group = group;
            // Stable per-group class; the actual color rule lives in the
            // sidebar's display-wide CSS provider, refreshed when colors change.
            add_css_class(GroupSidebar.color_class_for(group.id));
            group.bind_property("name", name_label, "label", BindingFlags.SYNC_CREATE);
            install_menu_actions();
        }

        private void install_menu_actions()
        {
            var actions = new SimpleActionGroup();

            var edit_action = new SimpleAction("edit", null);
            edit_action.activate.connect(() => edit_requested(group));
            actions.add_action(edit_action);

            var delete_action = new SimpleAction("delete", null);
            delete_action.activate.connect(() => delete_requested(group));
            actions.add_action(delete_action);

            insert_action_group("row", actions);
        }
    }
}
