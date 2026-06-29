namespace Queue.Tasks {

    // A run of text sharing the same inline formatting. A non-empty color holds
    // the text color as a "#rrggbb" string.
    public class TextRun : Object
    {
        public string text { get; set; default = ""; }
        public bool bold { get; set; default = false; }
        public bool italic { get; set; default = false; }
        public bool underline { get; set; default = false; }
        public bool strikethrough { get; set; default = false; }
        public string color { get; set; default = ""; }
    }

    // Converts task descriptions between the stored Markdown form and the
    // representations the UI needs: styled runs for the live editor and Pango
    // markup for display. Lists are kept as plain "• "/"N. " line prefixes and
    // headings as "# " line prefixes, so only inline styles are encoded inline:
    // **bold**, *italic*, <u>underline</u>, ~~strikethrough~~ and
    // <c#rrggbb>colored</c>.
    public class TaskDescriptionMarkup : Object
    {

        // Returns the heading level (1-3) of a line, or 0 when it is not a heading.
        public static int heading_level(string line)
        {
            int hashes = 0;
            while (hashes < line.length && line[hashes] == '#') {
                hashes++;
            }
            if (hashes >= 1 && hashes <= 3 && hashes < line.length && line[hashes] == ' ') {
                return hashes;
            }
            return 0;
        }

        // Splits Markdown into a sequence of runs carrying their formatting.
        public static GenericArray<TextRun> to_runs(string markdown)
        {
            var runs = new GenericArray<TextRun> ();
            var current = new StringBuilder();
            bool bold = false, italic = false, underline = false, strikethrough = false;
            string color = "";
            int length = markdown.length;

            for (int index = 0; index < length;) {
                if (index + 1 < length && markdown[index] == '*' && markdown[index + 1] == '*') {
                    flush(runs, current, bold, italic, underline, strikethrough, color);
                    bold = !bold;
                    index += 2;
                    continue;
                }
                if (markdown[index] == '*') {
                    flush(runs, current, bold, italic, underline, strikethrough, color);
                    italic = !italic;
                    index += 1;
                    continue;
                }
                if (index + 1 < length && markdown[index] == '~' && markdown[index + 1] == '~') {
                    flush(runs, current, bold, italic, underline, strikethrough, color);
                    strikethrough = !strikethrough;
                    index += 2;
                    continue;
                }
                if (index + 3 < length && markdown[index] == '<' && markdown[index + 1] == '/'
                    && markdown[index + 2] == 'u' && markdown[index + 3] == '>') {
                    flush(runs, current, bold, italic, underline, strikethrough, color);
                    underline = false;
                    index += 4;
                    continue;
                }
                if (index + 3 < length && markdown[index] == '<' && markdown[index + 1] == '/'
                    && markdown[index + 2] == 'c' && markdown[index + 3] == '>') {
                    flush(runs, current, bold, italic, underline, strikethrough, color);
                    color = "";
                    index += 4;
                    continue;
                }
                if (index + 2 < length && markdown[index] == '<' && markdown[index + 1] == 'u'
                    && markdown[index + 2] == '>') {
                    flush(runs, current, bold, italic, underline, strikethrough, color);
                    underline = true;
                    index += 3;
                    continue;
                }
                if (index + 9 < length && markdown[index] == '<' && markdown[index + 1] == 'c'
                    && markdown[index + 2] == '#' && markdown[index + 9] == '>'
                    && is_hex_sequence(markdown, index + 3, 6)) {
                    flush(runs, current, bold, italic, underline, strikethrough, color);
                    color = byte_range(markdown, index + 2, index + 9);
                    index += 10;
                    continue;
                }

                // Markers are ASCII, so any other byte is copied verbatim and
                // multi-byte UTF-8 sequences are reassembled untouched.
                current.append_c(markdown[index]);
                index += 1;
            }

            flush(runs, current, bold, italic, underline, strikethrough, color);
            return runs;
        }

        // Renders Markdown as Pango markup for display in a label, rendering
        // each line's heading or list prefix and its inline styles.
        public static string to_pango(string markdown)
        {
            var lines = markdown.split("\n");
            var builder = new StringBuilder();

            for (int index = 0; index < lines.length; index++) {
                if (index > 0) {
                    builder.append("\n");
                }
                builder.append(render_line(lines[index]));
            }

            return builder.str;
        }

        // Renders a single Markdown line, turning a heading or list prefix into
        // a presentational form and rendering the rest inline.
        private static string render_line(string line)
        {
            int level = heading_level(line);
            if (level > 0) {
                var size = level == 1 ? "xx-large" : (level == 2 ? "x-large" : "large");
                return "<span size=\"%s\" weight=\"bold\">%s</span>"
                       .printf(size, inline_to_pango(line.substring(level + 1)));
            }
            if (line.has_prefix("- ") || line.has_prefix("* ")) {
                return "• " + inline_to_pango(line.substring(2));
            }
            return inline_to_pango(line);
        }

        // Renders the inline styles of a single line as Pango markup.
        private static string inline_to_pango(string text)
        {
            var runs = to_runs(text);
            var builder = new StringBuilder();

            for (int index = 0; index < runs.length; index++) {
                var run = runs.get(index);
                var escaped = Markup.escape_text(run.text);

                var open = new StringBuilder();
                var close = new StringBuilder();
                if (run.color != "") {
                    open.append("<span foreground=\"%s\">".printf(run.color));
                    close.prepend("</span>");
                }
                if (run.bold) {
                    open.append("<b>");
                    close.prepend("</b>");
                }
                if (run.italic) {
                    open.append("<i>");
                    close.prepend("</i>");
                }
                if (run.underline) {
                    open.append("<u>");
                    close.prepend("</u>");
                }
                if (run.strikethrough) {
                    open.append("<s>");
                    close.prepend("</s>");
                }
                builder.append(open.str).append(escaped).append(close.str);
            }

            return builder.str;
        }

        // Appends the accumulated text as a run and resets the accumulator.
        private static void flush(GenericArray<TextRun> runs, StringBuilder current,
            bool bold, bool italic, bool underline, bool strikethrough, string color)
        {
            if (current.len == 0) {
                return;
            }
            runs.add(new TextRun() {
                text = current.str,
                bold = bold,
                italic = italic,
                underline = underline,
                strikethrough = strikethrough,
                color = color
            });
            current.truncate(0);
        }

        // Returns whether count characters starting at offset are hex digits.
        private static bool is_hex_sequence(string source, int offset, int count)
        {
            for (int index = offset; index < offset + count; index++) {
                var character = source[index];
                bool is_digit = character >= '0' && character <= '9';
                bool is_lower = character >= 'a' && character <= 'f';
                bool is_upper = character >= 'A' && character <= 'F';
                if (!is_digit && !is_lower && !is_upper) {
                    return false;
                }
            }
            return true;
        }

        // Builds a string from the bytes in [start, end), reassembling UTF-8.
        private static string byte_range(string source, int start, int end)
        {
            var builder = new StringBuilder();
            for (int index = start; index < end; index++) {
                builder.append_c(source[index]);
            }
            return builder.str;
        }
    }
}
