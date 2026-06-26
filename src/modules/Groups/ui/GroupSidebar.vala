namespace Collie.Groups {

    // Presents the list of groups and turns user gestures into controller calls.
    // It also owns a display-wide CSS provider that paints each group row with
    // its assigned background color.
    [GtkTemplate(ui = "/com/dprietob/collie/ui/group-sidebar.ui")]
    public class GroupSidebar : Adw.NavigationPage
    {

        [GtkChild]
        private unowned Gtk.Button add_button;
        [GtkChild]
        private unowned Gtk.ListBox list_box;

        private GroupSidebarController controller;
        private GLib.ListStore groups;
        private Gtk.CssProvider color_provider = new Gtk.CssProvider();

        public signal void group_selected(Group group);
        public signal void create_requested();
        public signal void edit_requested(Group group);
        public signal void delete_requested(Group group);

        public GroupSidebar (GroupSidebarController controller)
        {
            this.controller = controller;
            groups = controller.groups;

            var display = Gdk.Display.get_default();
            if (display != null) {
                // add_provider_for_display is the recommended way to register
                // global CSS; GTK keeps it supported despite GtkStyleContext
                // being otherwise deprecated, so this warning is expected.
                Gtk.StyleContext.add_provider_for_display(
                    display, color_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            }

            list_box.bind_model(groups, build_row);
            groups.items_changed.connect(() => refresh_colors());
            refresh_colors();

            add_button.clicked.connect(() => create_requested());
            list_box.row_selected.connect(on_row_selected);
        }

        // Selects the row of the given group, which also drives the task panel.
        public void select_group(Group group)
        {
            var row = find_row(group);
            if (row != null) {
                list_box.select_row(row);
            }
        }

        // CSS class that identifies a group's row regardless of its color.
        public static string color_class_for(int group_id)
        {
            return "group-color-%d".printf(group_id);
        }

        private GroupRow? find_row(Group group)
        {
            var child = list_box.get_first_child();
            while (child != null) {
                if (child is GroupRow && ((GroupRow) child).group == group) {
                    return (GroupRow) child;
                }
                child = child.get_next_sibling();
            }
            return null;
        }

        private Gtk.Widget build_row(Object item)
        {
            var group = (Group) item;
            var row = new GroupRow(group);
            group.notify["color"].connect(() => refresh_colors());
            row.edit_requested.connect((target) => edit_requested(target));
            row.delete_requested.connect((target) => delete_requested(target));
            enable_drag_and_drop(row, group);
            return row;
        }

        // Lets the user reorder groups by dragging a row onto another one.
        private void enable_drag_and_drop(GroupRow row, Group group)
        {
            var source = new Gtk.DragSource() {
                actions = Gdk.DragAction.MOVE
            };
            source.prepare.connect((x, y) => {
                var value = Value(typeof (Group));
                value.set_object(group);
                return new Gdk.ContentProvider.for_value(value);
            });
            source.drag_begin.connect((drag) => {
                source.set_icon(new Gtk.WidgetPaintable(row), 0, 0);
            });
            row.add_controller(source);

            var target = new Gtk.DropTarget(typeof (Group), Gdk.DragAction.MOVE);
            target.drop.connect((value, x, y) => {
                var dragged = value.get_object() as Group;
                if (dragged == null) {
                    return false;
                }
                var selected_before = selected_group();
                controller.move(dragged, group, y > row.get_height() / 2);
                if (selected_before == dragged) {
                    select_group(dragged);
                }
                return true;
            });
            row.add_controller(target);
        }

        private Group? selected_group()
        {
            var row = list_box.get_selected_row();
            return (row is GroupRow) ? ((GroupRow) row).group : null;
        }

        private void on_row_selected(Gtk.ListBoxRow? row)
        {
            if (row is GroupRow) {
                group_selected(((GroupRow) row).group);
            }
        }

        // Rebuilds the stylesheet so every group paints its row background and,
        // when selected, shows a border in a darker shade of that background so
        // the selection stays visible even on colored rows.
        private void refresh_colors()
        {
            var stylesheet = new StringBuilder();
            for (uint index = 0; index < groups.get_n_items(); index++) {
                var group = (Group) groups.get_item(index);
                var selector = ".%s".printf(color_class_for(group.id));

                if (group.color != "") {
                    stylesheet.append("%s { background-color: %s; }\n"
                        .printf(selector, group.color));
                    stylesheet.append("%s:selected { box-shadow: inset 0 0 0 3px shade(%s, 0.7); }\n"
                        .printf(selector, group.color));
                } else {
                    stylesheet.append("%s:selected { box-shadow: inset 0 0 0 3px shade(@view_bg_color, 0.5); }\n"
                        .printf(selector));
                }
            }
            color_provider.load_from_string(stylesheet.str);
        }
    }
}
