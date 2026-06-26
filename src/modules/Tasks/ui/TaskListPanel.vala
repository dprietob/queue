using Collie.Groups;

namespace Collie.Tasks {

    // Presents the tasks of the selected group and turns user gestures into
    // controller calls. Shows an empty state when no group is selected.
    [GtkTemplate(ui = "/com/dprietob/collie/ui/task-list-panel.ui")]
    public class TaskListPanel : Adw.NavigationPage
    {

        [GtkChild]
        private unowned Gtk.Button add_button;
        [GtkChild]
        private unowned Gtk.Stack stack;
        [GtkChild]
        private unowned Gtk.ListBox list_box;

        private TaskListController controller;

        public signal void create_requested();
        public signal void edit_requested(Task task);
        public signal void delete_requested(Task task);

        public TaskListPanel (TaskListController controller)
        {
            this.controller = controller;
            list_box.bind_model(controller.tasks, build_row);
            add_button.clicked.connect(() => create_requested());
        }

        public void show_group(Group group)
        {
            title = group.name;
            controller.load_group(group.id);
            add_button.sensitive = true;
            stack.visible_child_name = "tasks";
        }

        public void show_empty()
        {
            controller.clear();
            title = _("Tasks");
            add_button.sensitive = false;
            stack.visible_child_name = "empty";
        }

        public int current_group_id()
        {
            return controller.group_id;
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
