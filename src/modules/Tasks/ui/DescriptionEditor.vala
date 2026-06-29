namespace Queue.Tasks {

    // A lightweight rich-text editor for task descriptions. It shows formatting
    // live with GtkTextTags and serializes to and from Markdown, so the stored
    // value stays plain text. Bold, italic, underline, strikethrough and color
    // apply to the selection; headings and lists apply to whole lines.
    [GtkTemplate(ui = "/io/github/dprietob/queue/ui/description-editor.ui")]
    public class DescriptionEditor : Gtk.Box
    {

        [GtkChild]
        private unowned Gtk.MenuButton heading_button;
        [GtkChild]
        private unowned Gtk.Button h1_button;
        [GtkChild]
        private unowned Gtk.Button h2_button;
        [GtkChild]
        private unowned Gtk.Button h3_button;
        [GtkChild]
        private unowned Gtk.Button normal_button;
        [GtkChild]
        private unowned Gtk.Button bold_button;
        [GtkChild]
        private unowned Gtk.Button italic_button;
        [GtkChild]
        private unowned Gtk.Button underline_button;
        [GtkChild]
        private unowned Gtk.Button strikethrough_button;
        [GtkChild]
        private unowned Gtk.Button color_button;
        [GtkChild]
        private unowned Gtk.Button bullet_button;
        [GtkChild]
        private unowned Gtk.Button numbered_button;
        [GtkChild]
        private unowned Gtk.TextView text_view;

        private Gtk.TextTag bold_tag;
        private Gtk.TextTag italic_tag;
        private Gtk.TextTag underline_tag;
        private Gtk.TextTag strikethrough_tag;
        private Gtk.TextTag[] heading_tags;
        private HashTable<string, Gtk.TextTag> color_tags;

        construct {
            var buffer = text_view.buffer;
            bold_tag = buffer.create_tag("bold", "weight", Pango.Weight.BOLD);
            italic_tag = buffer.create_tag("italic", "style", Pango.Style.ITALIC);
            underline_tag = buffer.create_tag("underline", "underline", Pango.Underline.SINGLE);
            strikethrough_tag = buffer.create_tag("strikethrough", "strikethrough", true);
            heading_tags = {
                buffer.create_tag("heading1", "scale", 1.6, "weight", Pango.Weight.BOLD),
                buffer.create_tag("heading2", "scale", 1.3, "weight", Pango.Weight.BOLD),
                buffer.create_tag("heading3", "scale", 1.15, "weight", Pango.Weight.BOLD),
            };
            color_tags = new HashTable<string, Gtk.TextTag> (str_hash, str_equal);

            bold_button.clicked.connect(() => toggle_tag(bold_tag));
            italic_button.clicked.connect(() => toggle_tag(italic_tag));
            underline_button.clicked.connect(() => toggle_tag(underline_tag));
            strikethrough_button.clicked.connect(() => toggle_tag(strikethrough_tag));
            color_button.clicked.connect(() => choose_color());
            bullet_button.clicked.connect(() => prefix_lines("• ", false));
            numbered_button.clicked.connect(() => prefix_lines("", true));
            h1_button.clicked.connect(() => set_heading(1));
            h2_button.clicked.connect(() => set_heading(2));
            h3_button.clicked.connect(() => set_heading(3));
            normal_button.clicked.connect(() => set_heading(0));
        }

        // Loads a Markdown description, rendering its headings and inline styles
        // as tags. Each line is parsed independently so heading prefixes apply
        // to the whole line.
        public void set_markdown(string markdown)
        {
            var buffer = text_view.buffer;
            buffer.text = "";

            var lines = markdown.split("\n");
            for (int line = 0; line < lines.length; line++) {
                if (line > 0) {
                    insert_text("\n");
                }

                var level = TaskDescriptionMarkup.heading_level(lines[line]);
                var content = level > 0 ? lines[line].substring(level + 1) : lines[line];

                Gtk.TextIter line_start;
                buffer.get_end_iter(out line_start);
                int line_offset = line_start.get_offset();

                insert_runs(content);

                if (level > 0) {
                    Gtk.TextIter start, end;
                    buffer.get_iter_at_offset(out start, line_offset);
                    buffer.get_end_iter(out end);
                    buffer.apply_tag(heading_tags[level - 1], start, end);
                }
            }
        }

        // Serializes the current content back to Markdown, line by line so that
        // heading prefixes can be emitted per line.
        public string get_markdown()
        {
            var buffer = text_view.buffer;
            var builder = new StringBuilder();
            int line_count = buffer.get_line_count();

            for (int line = 0; line < line_count; line++) {
                if (line > 0) {
                    builder.append("\n");
                }
                Gtk.TextIter start, end;
                buffer.get_iter_at_line(out start, line);
                end = start;
                if (!end.ends_line()) {
                    end.forward_to_line_end();
                }
                builder.append(heading_prefix(start));
                builder.append(serialize_segment(start, end));
            }

            return builder.str;
        }

        // Inserts the runs of an inline Markdown string with their tags.
        private void insert_runs(string markdown)
        {
            var buffer = text_view.buffer;
            var runs = TaskDescriptionMarkup.to_runs(markdown);
            for (int index = 0; index < runs.length; index++) {
                var run = runs.get(index);
                int offset = insert_text(run.text);

                Gtk.TextIter start, end;
                buffer.get_iter_at_offset(out start, offset);
                buffer.get_end_iter(out end);
                if (run.bold) {
                    buffer.apply_tag(bold_tag, start, end);
                }
                if (run.italic) {
                    buffer.apply_tag(italic_tag, start, end);
                }
                if (run.underline) {
                    buffer.apply_tag(underline_tag, start, end);
                }
                if (run.strikethrough) {
                    buffer.apply_tag(strikethrough_tag, start, end);
                }
                if (run.color != "") {
                    buffer.apply_tag(color_tag_for(run.color), start, end);
                }
            }
        }

        // Appends text at the end of the buffer and returns its start offset.
        private int insert_text(string text)
        {
            var buffer = text_view.buffer;
            Gtk.TextIter end;
            buffer.get_end_iter(out end);
            int offset = end.get_offset();
            buffer.insert(ref end, text, -1);
            return offset;
        }

        // Returns the Markdown heading prefix of the line starting at the iter.
        private string heading_prefix(Gtk.TextIter line_start)
        {
            for (int level = 1; level <= heading_tags.length; level++) {
                if (line_start.has_tag(heading_tags[level - 1])) {
                    return string.nfill(level, '#') + " ";
                }
            }
            return "";
        }

        // Serializes the inline content of a buffer range to Markdown.
        private string serialize_segment(Gtk.TextIter from, Gtk.TextIter to)
        {
            var buffer = text_view.buffer;
            var builder = new StringBuilder();

            Gtk.TextIter position = from;
            while (position.compare(to) < 0) {
                Gtk.TextIter next = position;
                if (!next.forward_to_tag_toggle(null) || next.compare(to) > 0) {
                    next = to;
                }
                builder.append(wrap(buffer.get_text(position, next, false), position));
                position = next;
            }

            return builder.str;
        }

        // Wraps a constant-formatting segment with its Markdown markers.
        private string wrap(string text, Gtk.TextIter at)
        {
            if (text == "") {
                return "";
            }

            var open = new StringBuilder();
            var close = new StringBuilder();
            var color = color_at(at);
            if (color != null) {
                open.append("<c%s>".printf(color));
                close.prepend("</c>");
            }
            if (at.has_tag(bold_tag)) {
                open.append("**");
                close.prepend("**");
            }
            if (at.has_tag(italic_tag)) {
                open.append("*");
                close.prepend("*");
            }
            if (at.has_tag(underline_tag)) {
                open.append("<u>");
                close.prepend("</u>");
            }
            if (at.has_tag(strikethrough_tag)) {
                open.append("~~");
                close.prepend("~~");
            }
            return open.str + text + close.str;
        }

        // Adds or removes a tag over the selection, toggling on its current state.
        private void toggle_tag(Gtk.TextTag tag)
        {
            Gtk.TextIter start, end;
            if (text_view.buffer.get_selection_bounds(out start, out end)) {
                if (start.has_tag(tag)) {
                    text_view.buffer.remove_tag(tag, start, end);
                } else {
                    text_view.buffer.apply_tag(tag, start, end);
                }
            }
            text_view.grab_focus();
        }

        // Applies the given heading level to every line in the selection, or
        // clears the heading when level is 0.
        private void set_heading(int level)
        {
            var buffer = text_view.buffer;

            Gtk.TextIter start, end;
            if (!buffer.get_selection_bounds(out start, out end)) {
                buffer.get_iter_at_mark(out start, buffer.get_insert());
                end = start;
            }

            int first_line = start.get_line();
            int last_line = end.get_line();
            for (int line = first_line; line <= last_line; line++) {
                Gtk.TextIter line_start, line_end;
                buffer.get_iter_at_line(out line_start, line);
                line_end = line_start;
                if (!line_end.ends_line()) {
                    line_end.forward_to_line_end();
                }
                foreach (var tag in heading_tags) {
                    buffer.remove_tag(tag, line_start, line_end);
                }
                if (level > 0) {
                    buffer.apply_tag(heading_tags[level - 1], line_start, line_end);
                }
            }

            heading_button.active = false;
            text_view.grab_focus();
        }

        // Opens the system color chooser and applies the chosen color to the
        // current selection.
        private void choose_color()
        {
            var dialog = new Gtk.ColorDialog() {
                with_alpha = false
            };
            dialog.choose_rgba.begin(get_root() as Gtk.Window, null, null, (object, result) => {
                try {
                    apply_color(dialog.choose_rgba.end(result));
                } catch (Error error) {
                    // The chooser was dismissed; nothing to apply.
                }
            });
        }

        // Replaces any existing text color over the selection with the given one.
        private void apply_color(Gdk.RGBA rgba)
        {
            var buffer = text_view.buffer;
            Gtk.TextIter start, end;
            if (!buffer.get_selection_bounds(out start, out end)) {
                text_view.grab_focus();
                return;
            }

            foreach (var tag in color_tags.get_values()) {
                buffer.remove_tag(tag, start, end);
            }
            buffer.apply_tag(color_tag_for(to_hex(rgba)), start, end);
            text_view.grab_focus();
        }

        // Returns the reusable tag that paints text with the given "#rrggbb".
        private Gtk.TextTag color_tag_for(string hex)
        {
            var tag = color_tags.get(hex);
            if (tag == null) {
                tag = text_view.buffer.create_tag(null, "foreground", hex);
                color_tags.set(hex, tag);
            }
            return tag;
        }

        // Returns the "#rrggbb" color applied at the iter, or null when none is.
        private string? color_at(Gtk.TextIter at)
        {
            foreach (var hex in color_tags.get_keys()) {
                if (at.has_tag(color_tags.get(hex))) {
                    return hex;
                }
            }
            return null;
        }

        // Prefixes every line in the selection (or the current line) with a
        // fixed marker or an incrementing number.
        private void prefix_lines(string fixed_prefix, bool numbered)
        {
            var buffer = text_view.buffer;

            Gtk.TextIter start, end;
            if (!buffer.get_selection_bounds(out start, out end)) {
                buffer.get_iter_at_mark(out start, buffer.get_insert());
                end = start;
            }

            int first_line = start.get_line();
            int last_line = end.get_line();
            for (int line = first_line; line <= last_line; line++) {
                Gtk.TextIter line_start;
                buffer.get_iter_at_line(out line_start, line);
                var prefix = numbered ? "%d. ".printf(line - first_line + 1) : fixed_prefix;
                buffer.insert(ref line_start, prefix, -1);
            }

            text_view.grab_focus();
        }

        // Formats an RGBA color as a "#rrggbb" string.
        private static string to_hex(Gdk.RGBA rgba)
        {
            int red = (int) (rgba.red * 255 + 0.5);
            int green = (int) (rgba.green * 255 + 0.5);
            int blue = (int) (rgba.blue * 255 + 0.5);
            return "#%02x%02x%02x".printf(red, green, blue);
        }
    }
}
