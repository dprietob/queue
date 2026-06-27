[![License: GPL-3.0-or-later](https://img.shields.io/badge/License-GPL--3.0--or--later-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Flathub Installs](https://img.shields.io/flathub/downloads/com.dprietob.queue?label=Installs)][Flathub]
[![Please do not theme this app](https://stopthemingmy.app/badge.svg)](https://stopthemingmy.app)

<img src="data/icons/hicolor/256x256/apps/com.dprietob.queue.png?raw=true" width="128" alt="Queue icon">

# Queue

A simple, fast task manager for the GNOME desktop.

![Queue](screenshots/main.png?raw=true)

Queue helps you keep track of what you need to do. Organize your tasks into
colorful groups, mark the ones that matter, and see everything at a glance.

It is a small, focused native app — no accounts, no sync services, no clutter.
Your tasks live in a local database on your own device.

Queue lets you:

- Group tasks into custom, color-coded lists
- Mark tasks as completed or important, and reorder them by dragging
- Add an optional description to any task
- Filter by status and search within a group

It is also built to keep your data yours:

- Back up and restore everything as a single JSON file
- Fully translated into English, Spanish, French, German, Italian, Portuguese,
  Simplified Chinese, and Japanese, with light and dark styles

## Made for GNOME

Queue is built with GTK 4 and libadwaita to feel right at home on the GNOME
desktop, following the GNOME Human Interface Guidelines and respecting the
system style. Contributions are welcome and are expected to follow the
[GNOME Code of Conduct].

<a href='https://flathub.org/apps/com.dprietob.queue'><img width='196' alt='Download on Flathub' src='https://flathub.org/api/badge?locale=en'/></a>

## Your data stays on your device

Queue keeps your tasks in a local SQLite database inside your user data
directory — there is no online account and nothing leaves your computer.
App preferences such as the theme and window state are stored with GSettings.

Built-in backups let you export everything to a single JSON file and restore it
whenever you like, so moving your data between machines is always under your
control.

## Developing and Building

The easiest way to build and run Queue is with [GNOME Builder]: open the
project and press Run.

To build the Flatpak from the command line:

```shell
flatpak install flathub org.gnome.Platform//48 org.gnome.Sdk//48
flatpak-builder --user --install --force-clean build-flatpak com.dprietob.queue.yaml
flatpak run com.dprietob.queue
```

Or build natively with Meson and Ninja:

```shell
meson setup _build
ninja -C _build
./_build/queue
```

[Flathub]: https://flathub.org/apps/com.dprietob.queue
[GNOME Builder]: https://apps.gnome.org/Builder/
[GNOME Code of Conduct]: https://conduct.gnome.org
