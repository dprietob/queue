using Collie.Groups;
using Collie.Tasks;

namespace Collie {

    // Application shell. Owns the controllers and wires sidebar and task panel
    // together, presenting dialogs and toasts on behalf of the modules.
    [GtkTemplate(ui = "/com/dprietob/collie/ui/window.ui")]
    public class Window : Adw.ApplicationWindow
    {

        private delegate void TextEnteredCallback(string text);
        private delegate void ConfirmedCallback();

        [GtkChild]
        private unowned Adw.ToastOverlay toast_overlay;
        [GtkChild]
        private unowned Adw.NavigationSplitView split_view;

        private Database database;
        private GroupSidebarController group_controller;
        private TaskListController task_controller;
        private GroupSidebar sidebar;
        private TaskListPanel panel;

        public Window (Gtk.Application application, Database database)
        {
            Object(application: application);

            this.database = database;
            group_controller = new GroupSidebarController(database);
            task_controller = new TaskListController(database);

            sidebar = new GroupSidebar(group_controller);
            panel = new TaskListPanel(task_controller);
            split_view.sidebar = sidebar;
            split_view.content = panel;

            connect_signals();
            panel.show_empty();
        }

        private void connect_signals()
        {
            sidebar.group_selected.connect(on_group_selected);
            sidebar.create_requested.connect(on_create_group);
            sidebar.edit_requested.connect(on_edit_group);
            sidebar.delete_requested.connect(on_delete_group);

            panel.create_requested.connect(on_create_task);
            panel.edit_requested.connect(on_edit_task);
            panel.delete_requested.connect(on_delete_task);
        }

        private void on_group_selected(Group group)
        {
            panel.show_group(group);
            split_view.show_content = true;
        }

        private void on_create_group()
        {
            prompt_text(_("New Group"), _("Group name"), "", (text) => {
                report(group_controller.create(text));
            });
        }

        private void on_edit_group(Group group)
        {
            prompt_text(_("Rename Group"), _("Group name"), group.name, (text) => {
                report(group_controller.rename(group, text));
            });
        }

        private void on_delete_group(Group group)
        {
            var body = _("\"%s\" and all of its tasks will be permanently deleted.")
                .printf(group.name);
            confirm_deletion(_("Delete Group?"), body, () => {
                var was_selected = panel.current_group_id() == group.id;
                group_controller.remove(group);
                if (was_selected) {
                    panel.show_empty();
                }
            });
        }

        private void on_create_task()
        {
            prompt_text(_("New Task"), _("Task description"), "", (text) => {
                report(task_controller.create(text));
            });
        }

        private void on_edit_task(Collie.Tasks.Task task)
        {
            prompt_text(_("Edit Task"), _("Task description"), task.title, (text) => {
                report(task_controller.rename(task, text));
            });
        }

        private void on_delete_task(Collie.Tasks.Task task)
        {
            var body = _("\"%s\" will be permanently deleted.").printf(task.title);
            confirm_deletion(_("Delete Task?"), body, () => {
                task_controller.remove(task);
            });
        }

        // Shows a toast when a controller reports a validation error.
        private void report(string? error)
        {
            if (error != null) {
                toast_overlay.add_toast(new Adw.Toast(error));
            }
        }

        private void prompt_text(string heading, string placeholder, string initial,
            owned TextEnteredCallback callback)
        {
            var dialog = new Adw.AlertDialog(heading, null);

            var entry = new Gtk.Entry() {
                placeholder_text = placeholder,
                text = initial,
                activates_default = true
            };
            dialog.set_extra_child(entry);

            dialog.add_response("cancel", _("Cancel"));
            dialog.add_response("save", _("Save"));
            dialog.set_response_appearance("save", Adw.ResponseAppearance.SUGGESTED);
            dialog.default_response = "save";
            dialog.close_response = "cancel";

            dialog.response.connect((response) => {
                if (response == "save") {
                    callback(entry.text);
                }
            });
            dialog.present(this);
        }

        private void confirm_deletion(string heading, string body, owned ConfirmedCallback callback)
        {
            var dialog = new Adw.AlertDialog(heading, body);

            dialog.add_response("cancel", _("Cancel"));
            dialog.add_response("delete", _("Delete"));
            dialog.set_response_appearance("delete", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.default_response = "cancel";
            dialog.close_response = "cancel";

            dialog.response.connect((response) => {
                if (response == "delete") {
                    callback();
                }
            });
            dialog.present(this);
        }
    }
}
