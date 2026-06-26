namespace Collie.Groups {

    // Presents the list of groups and turns user gestures into controller calls.
    [GtkTemplate(ui = "/com/dprietob/collie/ui/group-sidebar.ui")]
    public class GroupSidebar : Adw.NavigationPage
    {

        [GtkChild]
        private unowned Gtk.Button add_button;
        [GtkChild]
        private unowned Gtk.ListBox list_box;

        public signal void group_selected(Group group);
        public signal void create_requested();
        public signal void edit_requested(Group group);
        public signal void delete_requested(Group group);

        public GroupSidebar (GroupSidebarController controller)
        {
            list_box.bind_model(controller.groups, build_row);
            add_button.clicked.connect(() => create_requested());
            list_box.row_selected.connect(on_row_selected);
        }

        private Gtk.Widget build_row(Object item)
        {
            var row = new GroupRow((Group) item);
            row.edit_requested.connect((group) => edit_requested(group));
            row.delete_requested.connect((group) => delete_requested(group));
            return row;
        }

        private void on_row_selected(Gtk.ListBoxRow? row)
        {
            if (row is GroupRow) {
                group_selected(((GroupRow) row).group);
            }
        }
    }
}
