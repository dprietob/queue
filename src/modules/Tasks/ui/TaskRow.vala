namespace Queue.Tasks {

    [GtkTemplate(ui = "/io/github/dprietob/queue/ui/task-row.ui")]
    public class TaskRow : Gtk.ListBoxRow
    {

        [GtkChild]
        private unowned Gtk.CheckButton check_button;
        [GtkChild]
        private unowned Gtk.Image important_icon;
        [GtkChild]
        private unowned Gtk.Image completed_icon;
        [GtkChild]
        private unowned Gtk.Label title_label;
        [GtkChild]
        private unowned Gtk.ToggleButton expand_button;
        [GtkChild]
        private unowned Gtk.Revealer description_revealer;
        [GtkChild]
        private unowned Gtk.Label description_label;

        public Task task { get; private set; }

        public signal void toggle_requested(Task task);
        public signal void edit_requested(Task task);
        public signal void delete_requested(Task task);

        public TaskRow (Task task)
        {
            this.task = task;

            check_button.active = task.done;
            refresh_title();
            refresh_description();
            refresh_completed();
            important_icon.visible = task.important;

            task.notify["done"].connect(() => {
                check_button.active = task.done;
                refresh_title();
                refresh_completed();
            });
            task.notify["completed_at"].connect(refresh_completed);
            task.notify["title"].connect(refresh_title);
            task.notify["description"].connect(refresh_description);
            task.notify["important"].connect(() => {
                important_icon.visible = task.important;
            });

            check_button.toggled.connect(() => {
                if (check_button.active != task.done) {
                    toggle_requested(task);
                }
            });
            expand_button.toggled.connect(() => {
                description_revealer.reveal_child = expand_button.active;
                expand_button.icon_name = expand_button.active
                    ? "pan-down-symbolic" : "pan-end-symbolic";
            });
            install_menu_actions();
        }

        private void install_menu_actions()
        {
            var actions = new SimpleActionGroup();

            var edit_action = new SimpleAction("edit", null);
            edit_action.activate.connect(() => edit_requested(task));
            actions.add_action(edit_action);

            var delete_action = new SimpleAction("delete", null);
            delete_action.activate.connect(() => delete_requested(task));
            actions.add_action(delete_action);

            insert_action_group("row", actions);
        }

        private void refresh_description()
        {
            var description = task.description.strip();
            var has_description = description != "";

            description_label.label = description;
            expand_button.visible = has_description;
            if (!has_description) {
                expand_button.active = false;
            }
        }

        private void refresh_completed()
        {
            completed_icon.visible = task.done;
            completed_icon.tooltip_text = completion_tooltip();
        }

        private string completion_tooltip()
        {
            var utc = new DateTime.from_iso8601(task.completed_at.replace(" ", "T") + "Z", null);
            if (utc == null) {
                return _("Completed");
            }
            return _("Completed on %s").printf(utc.to_local().format("%x %X"));
        }

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
