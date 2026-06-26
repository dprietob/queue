namespace Collie {

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

            // Stateful action backed by GSettings, so the choice is persisted.
            add_action(settings.create_action("color-scheme"));
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

// When running from the build tree the compiled GSettings schema sits next to
// the executable in data/; point GSettings there so the app works uninstalled.
// Installed runs find the schema in the system directory and skip this.
void use_local_schemas_if_present()
{
    string executable_path;
    try {
        executable_path = FileUtils.read_link("/proc/self/exe");
    } catch (FileError error) {
        return;
    }

    var schema_directory = Path.build_filename(Path.get_dirname(executable_path), "data");
    if (FileUtils.test(Path.build_filename(schema_directory, "gschemas.compiled"), FileTest.EXISTS)) {
        Environment.set_variable("GSETTINGS_SCHEMA_DIR", schema_directory, true);
    }
}

int main(string[] arguments)
{
    Intl.setlocale(LocaleCategory.ALL, "");
    Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
    Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain(Config.GETTEXT_PACKAGE);

    use_local_schemas_if_present();

    var application = new Collie.Application();
    return application.run(arguments);
}
