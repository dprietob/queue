namespace Queue.Tasks {

    // Coordinates the task panel: it runs validators and actions for the
    // currently selected group, and keeps the bound list model up to date.
    public class TaskListController : Object
    {

        private ListTasksByGroupAction list_tasks_action;
        private CreateTaskAction create_task_action;
        private UpdateTaskAction update_task_action;
        private ToggleTaskAction toggle_task_action;
        private DeleteTaskAction delete_task_action;
        private ReorderTasksAction reorder_tasks_action;

        public GLib.ListStore tasks { get; private set; }
        public int group_id { get; private set; default = 0; }

        public TaskListController (Database database)
        {
            list_tasks_action = new ListTasksByGroupAction(database);
            create_task_action = new CreateTaskAction(database);
            update_task_action = new UpdateTaskAction(database);
            toggle_task_action = new ToggleTaskAction(database);
            delete_task_action = new DeleteTaskAction(database);
            reorder_tasks_action = new ReorderTasksAction(database);

            tasks = new GLib.ListStore(typeof (Task));
        }

        public void load_group(int group_id)
        {
            this.group_id = group_id;
            tasks.remove_all();
            foreach (var task in list_tasks_action.execute(group_id)) {
                tasks.append(task);
            }
        }

        public void clear()
        {
            group_id = 0;
            tasks.remove_all();
        }

        public string? create(string title, string description, bool important)
        {
            if (group_id == 0) {
                return null;
            }
            var error = new TaskStoreValidator(title, description).validate();
            if (error != null) {
                return error;
            }
            tasks.append(create_task_action.execute(group_id, title.strip(), description.strip(), important));
            return null;
        }

        public string? update(Task task, string title, string description, bool important)
        {
            var error = new TaskStoreValidator(title, description).validate();
            if (error != null) {
                return error;
            }
            update_task_action.execute(task.id, title.strip(), description.strip(), important);
            task.title = title.strip();
            task.description = description.strip();
            task.important = important;
            return null;
        }

        public void toggle(Task task)
        {
            var done = !task.done;
            task.completed_at = toggle_task_action.execute(task.id, done);
            task.done = done;
        }

        public void remove(Task task)
        {
            delete_task_action.execute(task.id);

            uint position;
            if (tasks.find(task, out position)) {
                tasks.remove(position);
            }
        }

        public void move(Task dragged, Task target, bool after)
        {
            if (dragged == target) {
                return;
            }

            uint from;
            if (!tasks.find(dragged, out from)) {
                return;
            }
            tasks.remove(from);

            uint target_index;
            if (tasks.find(target, out target_index)) {
                tasks.insert(after ? target_index + 1 : target_index, dragged);
            } else {
                tasks.append(dragged);
            }

            persist_order();
        }

        private void persist_order()
        {
            int[] ordered_ids = {};
            for (uint index = 0; index < tasks.get_n_items(); index++) {
                ordered_ids += ((Task) tasks.get_item(index)).id;
            }
            reorder_tasks_action.execute(ordered_ids);
        }
    }
}
