using Queue.Groups;

namespace Queue.Tasks {

    // Presents the tasks of the selected group and turns user gestures into
    // controller calls. Shows an empty state when no group is selected, a
    // placeholder when the group has no tasks, and a status bar with metrics.
    [GtkTemplate(ui = "/com/dprietob/queue/ui/task-list-panel.ui")]
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
        private unowned Gtk.ToggleButton search_button;
        [GtkChild]
        private unowned Gtk.SearchBar search_bar;
        [GtkChild]
        private unowned Gtk.SearchEntry search_entry;
        [GtkChild]
        private unowned Gtk.DropDown state_filter;
        [GtkChild]
        private unowned Gtk.Box status_bar;
        [GtkChild]
        private unowned Gtk.Label total_label;
        [GtkChild]
        private unowned Gtk.Label pending_label;
        [GtkChild]
        private unowned Gtk.Label completed_label;
        [GtkChild]
        private unowned Gtk.Label important_label;

        // Options of the status drop-down, matching the order in the .ui file.
        private const uint STATE_ALL = 0;
        private const uint STATE_PENDING = 1;
        private const uint STATE_COMPLETED = 2;

        private TaskListController controller;
        private bool group_selected = false;

        public signal void create_requested();
        public signal void edit_requested(Task task);
        public signal void delete_requested(Task task);

        public TaskListPanel (TaskListController controller)
        {
            this.controller = controller;
            list_box.bind_model(controller.tasks, build_row);
            list_box.set_filter_func(filter_row);
            controller.tasks.items_changed.connect(() => refresh());
            add_button.clicked.connect(() => create_requested());
            add_first_task_button.clicked.connect(() => create_requested());

            search_bar.connect_entry(search_entry);
            search_bar.key_capture_widget = this;
            search_button.bind_property("active", search_bar, "search-mode-enabled",
                BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
            search_entry.search_changed.connect(() => list_box.invalidate_filter());
            state_filter.notify["selected"].connect(() => list_box.invalidate_filter());
        }

        public void show_group(Group group)
        {
            title = group.name;
            group_selected = true;
            reset_search();
            controller.load_group(group.id);
            add_button.sensitive = true;
            refresh();
        }

        public void show_empty()
        {
            group_selected = false;
            reset_search();
            controller.clear();
            title = _("Tasks");
            add_button.sensitive = false;
            refresh();
        }

        // Resets the search and status filters when the panel content changes.
        private void reset_search()
        {
            search_entry.text = "";
            search_button.active = false;
            state_filter.selected = STATE_ALL;
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
            search_button.sensitive = group_selected;
            state_filter.sensitive = group_selected;
        }

        // Filters rows by completion status and by the search query (title).
        private bool filter_row(Gtk.ListBoxRow row)
        {
            var task = ((TaskRow) row).task;

            if (state_filter.selected == STATE_PENDING && task.done) {
                return false;
            }
            if (state_filter.selected == STATE_COMPLETED && !task.done) {
                return false;
            }

            var query = search_entry.text.strip();
            if (query != "" && !task.title.casefold().contains(query.casefold())) {
                return false;
            }
            return true;
        }

        // Recomputes the task metrics shown in the status bar.
        private void update_metrics()
        {
            uint total = controller.tasks.get_n_items();
            uint completed = 0;
            uint important = 0;
            for (uint index = 0; index < total; index++) {
                var task = (Task) controller.tasks.get_item(index);
                if (task.done) {
                    completed++;
                }
                if (task.important) {
                    important++;
                }
            }
            uint pending = total - completed;

            total_label.label = _("Total: %u").printf(total);
            pending_label.label = _("Pending: %u").printf(pending);
            completed_label.label = _("Completed: %u").printf(completed);
            important_label.label = _("Important: %u").printf(important);
        }

        private Gtk.Widget build_row(Object item)
        {
            var task = (Task) item;
            var row = new TaskRow(task);
            task.notify["done"].connect(() => {
                update_metrics();
                list_box.invalidate_filter();
            });
            task.notify["important"].connect(() => update_metrics());
            row.toggle_requested.connect((target) => controller.toggle(target));
            row.edit_requested.connect((target) => edit_requested(target));
            row.delete_requested.connect((target) => delete_requested(target));
            enable_drag_and_drop(row, task);
            return row;
        }

        // Lets the user reorder tasks by dragging a row onto another one.
        private void enable_drag_and_drop(TaskRow row, Task task)
        {
            var source = new Gtk.DragSource() {
                actions = Gdk.DragAction.MOVE
            };
            source.prepare.connect((x, y) => {
                var value = Value(typeof (Task));
                value.set_object(task);
                return new Gdk.ContentProvider.for_value(value);
            });
            source.drag_begin.connect((drag) => {
                source.set_icon(new Gtk.WidgetPaintable(row), 0, 0);
            });
            row.add_controller(source);

            var target = new Gtk.DropTarget(typeof (Task), Gdk.DragAction.MOVE);
            target.drop.connect((value, x, y) => {
                var dragged = value.get_object() as Task;
                if (dragged == null) {
                    return false;
                }
                controller.move(dragged, task, y > row.get_height() / 2);
                return true;
            });
            row.add_controller(target);
        }
    }
}
