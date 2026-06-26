using Collie.Groups;
using Collie.Tasks;

namespace Collie {

    // Application shell. Owns the controllers and wires sidebar and task panel
    // together, presenting dialogs and toasts on behalf of the modules.
    [GtkTemplate(ui = "/com/dprietob/collie/ui/window.ui")]
    public class Window : Adw.ApplicationWindow
    {

        private delegate void TextEnteredCallback(string text);
        private delegate void GroupEnteredCallback(string name, string color);
        private delegate void ConfirmedCallback();

        [GtkChild]
        private unowned Adw.ToastOverlay toast_overlay;
        [GtkChild]
        private unowned Adw.NavigationSplitView split_view;

        private Settings settings;
        private Database database;
        private GroupSidebarController group_controller;
        private TaskListController task_controller;
        private GroupSidebar sidebar;
        private TaskListPanel panel;

        public Window (Gtk.Application application, Database database)
        {
            Object(application: application);

            settings = new Settings(Config.APP_ID);
            settings.bind("window-width", this, "default-width", SettingsBindFlags.DEFAULT);
            settings.bind("window-height", this, "default-height", SettingsBindFlags.DEFAULT);
            settings.bind("window-maximized", this, "maximized", SettingsBindFlags.DEFAULT);

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
            prompt_group(_("New Group"), "", "", (name, color) => {
                Group ? created;
                report(group_controller.create(name, color, out created));
                if (created != null) {
                    sidebar.select_group(created);
                }
            });
        }

        private void on_edit_group(Group group)
        {
            prompt_group(_("Edit Group"), group.name, group.color, (name, color) => {
                report(group_controller.update(group, name, color));
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
            prompt_task(_("New Task"), "", (text) => {
                report(task_controller.create(text));
            });
        }

        private void on_edit_task(Collie.Tasks.Task task)
        {
            prompt_task(_("Edit Task"), task.title, (text) => {
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

        // Dialog to create or edit a group: a name entry plus a color picker.
        // The color defaults to transparent and an unchanged transparent value
        // is stored as an empty string (no background).
        private void prompt_group(string heading, string name, string color,
            owned GroupEnteredCallback callback)
        {
            var dialog = new Adw.AlertDialog(heading, null);

            var entry = new Gtk.Entry() {
                placeholder_text = _("Group name"),
                text = name,
                activates_default = true
            };

            var color_button = new Gtk.ColorDialogButton(new Gtk.ColorDialog() {
                with_alpha = true
            });
            var initial_color = Gdk.RGBA() {
                red = 0, green = 0, blue = 0, alpha = 0
            };
            if (color != "") {
                initial_color.parse(color);
            }
            color_button.set_rgba(initial_color);

            var color_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
            color_row.append(new Gtk.Label(_("Color")) {
                hexpand = true, xalign = 0
            });
            color_row.append(color_button);

            var content = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            content.append(entry);
            content.append(color_row);
            dialog.set_extra_child(content);

            dialog.add_response("cancel", _("Cancel"));
            dialog.add_response("save", _("Save"));
            dialog.set_response_appearance("save", Adw.ResponseAppearance.SUGGESTED);
            dialog.default_response = "save";
            dialog.close_response = "cancel";

            dialog.response.connect((response) => {
                if (response == "save") {
                    var chosen = color_button.get_rgba();
                    var color_value = chosen.alpha == 0 ? "" : chosen.to_string();
                    callback(entry.text, color_value);
                }
            });
            dialog.present(this);
        }

        // Dialog to create or edit a task. A single-line entry (no line breaks)
        // capped at the task's maximum length, shown in a wide popup with
        // natural-sized buttons aligned to the right.
        private void prompt_task(string heading, string initial,
            owned TextEnteredCallback callback)
        {
            var dialog = new Adw.Dialog() {
                title = heading,
                content_width = 500
            };

            var title_label = new Gtk.Label(heading) {
                halign = Gtk.Align.START,
                wrap = true
            };
            title_label.add_css_class("title-2");

            var entry = new Gtk.Entry() {
                placeholder_text = _("Task description"),
                text = initial,
                activates_default = true,
                max_length = Tasks.TaskStoreValidator.MAXIMUM_LENGTH,
                hexpand = true
            };

            var cancel_button = new Gtk.Button.with_label(_("Cancel"));
            var save_button = new Gtk.Button.with_label(_("Save"));
            save_button.add_css_class("suggested-action");

            var buttons = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6) {
                halign = Gtk.Align.END
            };
            buttons.append(cancel_button);
            buttons.append(save_button);

            var content = new Gtk.Box(Gtk.Orientation.VERTICAL, 18) {
                margin_top = 24,
                margin_bottom = 24,
                margin_start = 24,
                margin_end = 24
            };
            content.append(title_label);
            content.append(entry);
            content.append(buttons);
            dialog.child = content;

            dialog.default_widget = save_button;
            dialog.focus_widget = entry;

            cancel_button.clicked.connect(() => dialog.close());
            save_button.clicked.connect(() => {
                callback(entry.text);
                dialog.close();
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
