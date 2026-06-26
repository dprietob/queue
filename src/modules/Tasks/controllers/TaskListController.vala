namespace Collie.Tasks {

    // Coordinates the task panel: it runs validators and actions for the
    // currently selected group, and keeps the bound list model up to date.
    public class TaskListController : Object
    {

        private ListTasksByGroupAction list_tasks_action;
        private CreateTaskAction create_task_action;
        private UpdateTaskAction update_task_action;
        private ToggleTaskAction toggle_task_action;
        private DeleteTaskAction delete_task_action;

        public GLib.ListStore tasks { get; private set; }
        public int group_id { get; private set; default = 0; }

        public TaskListController (Database database)
        {
            list_tasks_action = new ListTasksByGroupAction(database);
            create_task_action = new CreateTaskAction(database);
            update_task_action = new UpdateTaskAction(database);
            toggle_task_action = new ToggleTaskAction(database);
            delete_task_action = new DeleteTaskAction(database);

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

        public string? create(string title)
        {
            if (group_id == 0) {
                return null;
            }
            var error = new TaskStoreValidator(title).validate();
            if (error != null) {
                return error;
            }
            tasks.append(create_task_action.execute(group_id, title.strip()));
            return null;
        }

        public string? rename(Task task, string title)
        {
            var error = new TaskStoreValidator(title).validate();
            if (error != null) {
                return error;
            }
            update_task_action.execute(task.id, title.strip());
            task.title = title.strip();
            return null;
        }

        public void toggle(Task task)
        {
            var done = !task.done;
            toggle_task_action.execute(task.id, done);
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
    }
}
