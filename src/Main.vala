namespace Queue {

    public class Application : Adw.Application
    {

        private Settings settings;

        public Application ()
        {
            Object(
                application_id: Config.APP_ID,
                flags: ApplicationFlags.DEFAULT_FLAGS
                );
        }

        construct {
            settings = new Settings(Config.APP_ID);
            register_actions();
        }

        protected override void startup()
        {
            base.startup();
            // Make the bundled application icon resolvable by name, both when
            // installed and when running from the build tree.
            Gtk.IconTheme.get_for_display(Gdk.Display.get_default())
            .add_resource_path("/io/github/dprietob/queue/icons");
            // Applied here, not in construct: the style manager needs GTK/Adw
            // to be initialized first.
            bind_color_scheme();
        }

        protected override void activate()
        {
            if (active_window != null) {
                active_window.present();
                return;
            }

            try {
                var window = new Window(this, new Database());
                window.present();
            } catch (Error error) {
                critical("The application could not start: %s", error.message);
                quit();
            }
        }

        // Registers the application-wide actions and their accelerators.
        private void register_actions()
        {
            var quit_action = new SimpleAction("quit", null);
            quit_action.activate.connect(() => quit());
            add_action(quit_action);
            set_accels_for_action("app.quit", { "<Control>q" });

            // Stateful actions backed by GSettings, so the choices are persisted.
            add_action(settings.create_action("color-scheme"));

            var about_action = new SimpleAction("about", null);
            about_action.activate.connect(() => show_about());
            add_action(about_action);
        }

        // Shows the about dialog with version, author and license information.
        private void show_about()
        {
            var about = new Adw.AboutDialog() {
                application_name = "Queue",
                application_icon = Config.APP_ID,
                developer_name = "Daniel Prieto",
                version = Config.VERSION,
                license_type = Gtk.License.GPL_3_0,
                copyright = "🄯 2026 Daniel Prieto"
            };
            about.present(active_window);
        }

        // Applies the saved color scheme on startup and whenever it changes.
        private void bind_color_scheme()
        {
            apply_color_scheme(settings.get_string("color-scheme"));
            settings.changed["color-scheme"].connect(() => {
                apply_color_scheme(settings.get_string("color-scheme"));
            });
        }

        // Applies the chosen color scheme: follow the system, force light or
        // force dark.
        private void apply_color_scheme(string scheme)
        {
            var manager = Adw.StyleManager.get_default();
            switch (scheme) {
            case "light":
                manager.color_scheme = Adw.ColorScheme.FORCE_LIGHT;
                break;

            case "dark":
                manager.color_scheme = Adw.ColorScheme.FORCE_DARK;
                break;

            default:
                manager.color_scheme = Adw.ColorScheme.DEFAULT;
                break;
            }
        }
    }
}

// Returns the directory of the running executable, or null if it cannot be
// resolved.
string? executable_directory()
{
    try {
        return Path.get_dirname(FileUtils.read_link("/proc/self/exe"));
    } catch (FileError error) {
        return null;
    }
}

// When running from the build tree the compiled GSettings schema sits next to
// the executable in data/; point GSettings there so the app works uninstalled.
// Installed runs find the schema in the system directory and skip this.
void use_local_schemas_if_present()
{
    var directory = executable_directory();
    if (directory == null) {
        return;
    }

    var schema_directory = Path.build_filename(directory, "data");
    if (FileUtils.test(Path.build_filename(schema_directory, "gschemas.compiled"), FileTest.EXISTS)) {
        Environment.set_variable("GSETTINGS_SCHEMA_DIR", schema_directory, true);
    }
}

// Resolves the message-catalog directory: the build tree's po/ when running
// uninstalled, otherwise the installed locale directory.
string locale_directory()
{
    var directory = executable_directory();
    if (directory != null) {
        var local_locale = Path.build_filename(directory, "po");
        if (FileUtils.test(local_locale, FileTest.IS_DIR)) {
            return local_locale;
        }
    }
    return Config.LOCALEDIR;
}

int main(string[] arguments)
{
    use_local_schemas_if_present();

    Intl.setlocale(LocaleCategory.ALL, "");
    Intl.bindtextdomain(Config.GETTEXT_PACKAGE, locale_directory());
    Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain(Config.GETTEXT_PACKAGE);

    var application = new Queue.Application();
    return application.run(arguments);
}
