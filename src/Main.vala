namespace Collie {

    public class Application : Adw.Application
    {

        public Application ()
        {
            Object(
                application_id: Config.APP_ID,
                flags: ApplicationFlags.DEFAULT_FLAGS
                );
        }

        construct {
            register_actions();
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
        }
    }
}

int main(string[] arguments)
{
    Intl.setlocale(LocaleCategory.ALL, "");
    Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
    Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain(Config.GETTEXT_PACKAGE);

    var application = new Collie.Application();
    return application.run(arguments);
}
