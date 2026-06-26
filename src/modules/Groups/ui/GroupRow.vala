namespace Collie.Groups {

    [GtkTemplate(ui = "/com/dprietob/collie/ui/group-row.ui")]
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
            group.bind_property("name", name_label, "label", BindingFlags.SYNC_CREATE);
            edit_button.clicked.connect(() => edit_requested(group));
            delete_button.clicked.connect(() => delete_requested(group));
        }
    }
}
