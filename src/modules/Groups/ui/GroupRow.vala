namespace Queue.Groups {

    [GtkTemplate(ui = "/io/github/dprietob/queue/ui/group-row.ui")]
    public class GroupRow : Gtk.ListBoxRow
    {

        [GtkChild]
        private unowned Gtk.Label name_label;
        [GtkChild]
        private unowned Gtk.Button edit_button;
        [GtkChild]
        private unowned Gtk.Button delete_button;

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
            edit_button.clicked.connect(() => edit_requested(group));
            delete_button.clicked.connect(() => delete_requested(group));
        }
    }
}
