using Collie.Groups;

namespace Collie.Tasks {

    // Presents the tasks of the selected group and turns user gestures into
    // controller calls. Shows an empty state when no group is selected and a
    // placeholder when the selected group has no tasks yet.
    [GtkTemplate(ui = "/com/dprietob/collie/ui/task-list-panel.ui")]
    public class TaskListPanel : Adw.NavigationPage
    {

        [GtkChild]
        private unowned Gtk.Button add_button;
        [GtkChild]
        private unowned Gtk.Button add_first_task_button;
        [GtkChild]
        private unowned Gtk.Stack stack;
        [GtkChild]
        private unowned Gtk.ListBox list_box;

        private TaskListController controller;
        private bool group_selected = false;

        public signal void create_requested();
        public signal void edit_requested(Task task);
        public signal void delete_requested(Task task);

        public TaskListPanel (TaskListController controller)
        {
            this.controller = controller;
            list_box.bind_model(controller.tasks, build_row);
            controller.tasks.items_changed.connect(() => update_view());
            add_button.clicked.connect(() => create_requested());
            add_first_task_button.clicked.connect(() => create_requested());
        }

        public void show_group(Group group)
        {
            title = group.name;
            group_selected = true;
            controller.load_group(group.id);
            add_button.sensitive = true;
            update_view();
        }

        public void show_empty()
        {
            controller.clear();
            title = _("Tasks");
            group_selected = false;
            add_button.sensitive = false;
            update_view();
        }

        public int current_group_id()
        {
            return controller.group_id;
        }

        // Chooses the visible page: no group, an empty group, or the task list.
        private void update_view()
        {
            if (!group_selected) {
                stack.visible_child_name = "empty";
            } else if (controller.tasks.get_n_items() == 0) {
                stack.visible_child_name = "no-tasks";
            } else {
                stack.visible_child_name = "tasks";
            }
        }

        private Gtk.Widget build_row(Object item)
        {
            var row = new TaskRow((Task) item);
            row.toggle_requested.connect((task) => controller.toggle(task));
            row.edit_requested.connect((task) => edit_requested(task));
            row.delete_requested.connect((task) => delete_requested(task));
            return row;
        }
    }
}
