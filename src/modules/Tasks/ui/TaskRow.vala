namespace Collie.Tasks {

    [GtkTemplate(ui = "/com/dprietob/collie/ui/task-row.ui")]
    public class TaskRow : Gtk.ListBoxRow
    {

        [GtkChild]
        private unowned Gtk.CheckButton check_button;
        [GtkChild]
        private unowned Gtk.Label title_label;
        [GtkChild]
        private unowned Gtk.Button edit_button;
        [GtkChild]
        private unowned Gtk.Button delete_button;

        public Task task { get; private set; }

        public signal void toggle_requested(Task task);
        public signal void edit_requested(Task task);
        public signal void delete_requested(Task task);

        public TaskRow (Task task)
        {
            this.task = task;

            check_button.active = task.done;
            refresh_title();

            task.notify["done"].connect(() => {
                check_button.active = task.done;
                refresh_title();
            });
            task.notify["title"].connect(refresh_title);

            check_button.toggled.connect(() => {
                if (check_button.active != task.done) {
                    toggle_requested(task);
                }
            });
            edit_button.clicked.connect(() => edit_requested(task));
            delete_button.clicked.connect(() => delete_requested(task));
        }

        // Strikes through and dims the title when the task is completed.
        private void refresh_title()
        {
            if (task.done) {
                title_label.add_css_class("dim-label");
                title_label.set_markup("<s>%s</s>".printf(Markup.escape_text(task.title)));
            } else {
                title_label.remove_css_class("dim-label");
                title_label.set_text(task.title);
            }
        }
    }
}
