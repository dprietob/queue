# collie

Gestor de tareas de escritorio para Linux, escrito en **Vala** con **GTK4** y **libadwaita**.

## Estado

Work in progress.

## Características

- Crea, edita y completa tareas de forma rápida.
- Organiza las tareas en listas y etiquétalas.
- Persistencia local en SQLite; sin cuentas ni conexión.
- Integración nativa con el escritorio: respeta el tema claro/oscuro del sistema.
- Interfaz GTK4 + libadwaita que sigue las _GNOME Human Interface Guidelines_.

## Dependencias

| Dependencia | Versión mínima | Notas                |
| ----------- | -------------- | -------------------- |
| Vala        | 0.56           |                      |
| GTK4        | 4.12           |                      |
| libadwaita  | 1.5            | `libadwaita-1`       |
| SQLite      | 3              | `sqlite3`            |
| JSON-GLib   | 1.0            | `json-glib-1.0`      |
| Meson       | 0.62           | Sistema de build     |
| Ninja       | —              | Backend de Meson     |
| gettext     | —              | Herramientas de i18n |

En Fedora / RHEL:

```shell
sudo dnf install vala vala-devel vala-language-server gtk4-devel libadwaita-devel sqlite-devel json-glib-devel meson ninja-build gettext-devel
```

En Debian / Ubuntu:

```shell
sudo apt install valac libvala-dev vala-language-server libgtk-4-dev libadwaita-1-dev libsqlite3-dev libjson-glib-dev meson ninja-build gettext
```

En Arch Linux:

```shell
sudo pacman -S vala vala-language-server gtk4 libadwaita sqlite json-glib meson ninja gettext base-devel
```

## Compilación y ejecución

```shell
# Clona el repositorio
git clone git@github.com:dprietob/collie.git
cd collie

# Configura el build en el directorio _build/
meson setup _build

# Compila
ninja -C _build

# Ejecuta directamente desde el directorio de build
./_build/collie
```

### Instalación en el sistema

```shell
# Instala en /usr/local (o el prefix configurado)
sudo ninja -C _build install

# Ejecuta como cualquier otra aplicación
collie
```

Para desinstalar:

```shell
sudo ninja -C _build uninstall
```

### Prefix personalizado

```shell
# Instalar en ~/.local (sin sudo)
meson setup _build --prefix ~/.local
ninja -C _build
ninja -C _build install
```

## Almacenamiento de datos

Las tareas se guardan en una base de datos SQLite dentro del directorio de datos del usuario (XDG):

```
~/.local/share/collie/collie.db
```

Las preferencias de la aplicación (tema, estado de ventana) se gestionan con **GSettings**.

## Desarrollo

> La arquitectura del proyecto está descrita en [`ARCHITECTURE.md`](ARCHITECTURE.md) y las convenciones de desarrollo en [`CLAUDE.md`](CLAUDE.md).

### Recompilar tras cambios

Meson detecta automáticamente los cambios en los ficheros fuente; basta con volver a ejecutar `ninja`:

```shell
ninja -C _build
```

Si modificas `meson.build` o `meson_options.txt`, Meson se regenera solo al invocar `ninja`.

### Tests

```shell
meson test -C _build
```

### Estructura del proyecto

```
collie/
├── meson.build                  # Build principal
├── meson_options.txt            # Opciones: profile (default/development)
├── src/
│   ├── Main.vala                # Punto de entrada y clase Adw.Application
│   ├── Config.vapi              # Constantes generadas por Meson (APP_ID, VERSION…)
│   ├── config/                  # Configuración global y acceso a GSettings
│   ├── database/
│   │   ├── migrations/          # Migraciones de esquema SQLite
│   │   └── seeders/             # Datos iniciales (primer arranque)
│   └── modules/
│       └── Tasks/               # Módulo de tareas
│           ├── models/          # Acceso a datos (única capa que habla con SQLite)
│           ├── factories/       # Factorías de modelos (tests)
│           ├── validators/      # Validación de datos
│           ├── actions/         # Casos de uso atómicos
│           ├── controllers/     # Controladores de UI (presenters)
│           ├── services/        # Lógica reutilizable entre actions
│           └── ui/              # Widgets GTK4 y plantillas .ui
├── tests/
│   ├── feature/                 # Tests de casos de uso completos
│   └── unit/                    # Tests de actions y services
├── data/
│   ├── com.dprietob.collie.desktop.in       # Acceso directo freedesktop
│   ├── com.dprietob.collie.appdata.xml.in   # Metadatos AppStream / GNOME Software
│   └── icons/hicolor/scalable/apps/
│       └── com.dprietob.collie.svg          # Icono de la aplicación
└── po/
    ├── LINGUAS                  # Idiomas disponibles
    ├── POTFILES                 # Ficheros fuente con cadenas traducibles
    └── es.po                    # Traducción al español
```

### Añadir un nuevo idioma

1. Añade el código de idioma a `po/LINGUAS` (p. ej. `fr`).
2. Genera el fichero `.po` inicial desde el directorio `_build/`:

```shell
ninja -C _build collie-pot       # Actualiza el fichero .pot
msginit -l fr -o po/fr.po -i _build/po/collie.pot
```

3. Traduce las cadenas en `po/fr.po`.
4. Recompila con `ninja -C _build`.

### Actualizar las cadenas traducibles

Cuando se añaden o modifican cadenas en el código:

```shell
ninja -C _build collie-update-po
```

Esto actualiza todos los ficheros `.po` existentes con las nuevas cadenas.

## ID de la aplicación

`com.dprietob.collie`

Sigue la convención de nomenclatura inversa de dominios de freedesktop / GNOME.
