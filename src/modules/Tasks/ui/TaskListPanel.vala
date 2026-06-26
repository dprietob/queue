using Collie.Groups;

namespace Collie.Tasks {

    // Presents the tasks of the selected group and turns user gestures into
    // controller calls. Shows an empty state when no group is selected, a
    // placeholder when the group has no tasks, and a status bar with metrics.
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
        [GtkChild]
        private unowned Gtk.Box status_bar;
        [GtkChild]
        private unowned Gtk.Label total_label;
        [GtkChild]
        private unowned Gtk.Label pending_label;
        [GtkChild]
        private unowned Gtk.Label completed_label;

        private TaskListController controller;
        private bool group_selected = false;

        public signal void create_requested();
        public signal void edit_requested(Task task);
        public signal void delete_requested(Task task);

        public TaskListPanel (TaskListController controller)
        {
            this.controller = controller;
            list_box.bind_model(controller.tasks, build_row);
            controller.tasks.items_changed.connect(() => refresh());
            add_button.clicked.connect(() => create_requested());
            add_first_task_button.clicked.connect(() => create_requested());
        }

        public void show_group(Group group)
        {
            title = group.name;
            group_selected = true;
            controller.load_group(group.id);
            add_button.sensitive = true;
            refresh();
        }

        public void show_empty()
        {
            group_selected = false;
            controller.clear();
            title = _("Tasks");
            add_button.sensitive = false;
            refresh();
        }

        public int current_group_id()
        {
            return controller.group_id;
        }

        private void refresh()
        {
            update_view();
            update_metrics();
        }

        // Chooses the visible page and shows the status bar only with a group.
        private void update_view()
        {
            if (!group_selected) {
                stack.visible_child_name = "empty";
            } else if (controller.tasks.get_n_items() == 0) {
                stack.visible_child_name = "no-tasks";
            } else {
                stack.visible_child_name = "tasks";
            }
            status_bar.visible = group_selected;
        }

        // Recomputes the task metrics shown in the status bar.
        private void update_metrics()
        {
            uint total = controller.tasks.get_n_items();
            uint completed = 0;
            for (uint index = 0; index < total; index++) {
                if (((Task) controller.tasks.get_item(index)).done) {
                    completed++;
                }
            }
            uint pending = total - completed;

            total_label.label = _("Total: %u").printf(total);
            pending_label.label = _("Pending: %u").printf(pending);
            completed_label.label = _("Completed: %u").printf(completed);
        }

        private Gtk.Widget build_row(Object item)
        {
            var task = (Task) item;
            var row = new TaskRow(task);
            task.notify["done"].connect(() => update_metrics());
            row.toggle_requested.connect((target) => controller.toggle(target));
            row.edit_requested.connect((target) => edit_requested(target));
            row.delete_requested.connect((target) => delete_requested(target));
            return row;
        }
    }
}
