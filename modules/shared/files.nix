{ pkgs, config, ... }:

{
  ".local/bin/tmux-cpu".source = pkgs.writeShellScript "tmux-cpu" ''
    if [ -f /proc/stat ]; then
      awk '/^cpu / {used=$2+$3+$4+$6+$7+$8; total=used+$5; printf "%d", used*100/total}' /proc/stat
    else
      /usr/bin/top -l 1 -n 0 2>/dev/null | awk '/CPU usage/ {gsub(/%/,""); printf "%d", $3+$5}'
    fi
  '';

  ".local/bin/tmux-mem".source = pkgs.writeShellScript "tmux-mem" ''
    if [ -f /proc/meminfo ]; then
      awk '/MemTotal/ {t=$2} /MemAvailable/ {printf "%d", 100-$2*100/t}' /proc/meminfo
    else
      /usr/bin/memory_pressure 2>/dev/null | awk '/percentage/ {printf "%d", 100-$5}'
    fi
  '';
  ".config/btop/themes/catppuccin_macchiato.theme".text = ''
    # Catppuccin Macchiato theme for btop
    # https://github.com/catppuccin/btop

    # Main background, empty for terminal default, need to be empty if you want transparent background
    theme[main_bg]="#24273a"

    # Main text color
    theme[main_fg]="#cad3f5"

    # Title color for boxes
    theme[title]="#cad3f5"

    # Highlight color for keyboard shortcuts
    theme[hi_fg]="#8aadf4"

    # Background color of selected item in processes box
    theme[selected_bg]="#494d64"

    # Foreground color of selected item in processes box
    theme[selected_fg]="#8aadf4"

    # Color of inactive/disabled text
    theme[inactive_fg]="#8087a2"

    # Color of text appearing on top of graphs, i.e uptime and current network graph scaling
    theme[graph_text]="#f4dbd6"

    # Background color of the percentage meters
    theme[meter_bg]="#494d64"

    # Misc colors for processes box including mini cpu graphs, subtle, etc.
    theme[proc_misc]="#f4dbd6"

    # CPU, Memory, Network, Proc box outline colors
    theme[cpu_box]="#c6a0f6"
    theme[mem_box]="#a6da95"
    theme[net_box]="#ee99a0"
    theme[proc_box]="#8aadf4"

    # Box divider line and target line colors
    theme[div_line]="#6e738d"

    # Temperature graph color (Green -> Yellow -> Red)
    theme[temp_start]="#a6da95"
    theme[temp_mid]="#eed49f"
    theme[temp_end]="#ed8796"

    # CPU graph colors (Teal -> Lavender)
    theme[cpu_start]="#8bd5ca"
    theme[cpu_mid]="#7dc4e4"
    theme[cpu_end]="#b7bdf8"

    # Mem/Disk free meter (Mauve -> Lavender -> Blue)
    theme[free_start]="#c6a0f6"
    theme[free_mid]="#b7bdf8"
    theme[free_end]="#8aadf4"

    # Mem/Disk cached meter (Sapphire -> Blue)
    theme[cached_start]="#7dc4e4"
    theme[cached_mid]="#8aadf4"
    theme[cached_end]="#b7bdf8"

    # Mem/Disk available meter (Peach -> Red)
    theme[available_start]="#f5a97f"
    theme[available_mid]="#ee99a0"
    theme[available_end]="#ed8796"

    # Mem/Disk used meter (Green -> Sky)
    theme[used_start]="#a6da95"
    theme[used_mid]="#8bd5ca"
    theme[used_end]="#91d7e3"

    # Download graph colors (Peach -> Red)
    theme[download_start]="#f5a97f"
    theme[download_mid]="#ee99a0"
    theme[download_end]="#ed8796"

    # Upload graph colors (Green -> Sky)
    theme[upload_start]="#a6da95"
    theme[upload_mid]="#8bd5ca"
    theme[upload_end]="#91d7e3"

    # Process box color gradient for threads, mem and cpu usage (Teal -> Mauve)
    theme[process_start]="#8bd5ca"
    theme[process_mid]="#8aadf4"
    theme[process_end]="#c6a0f6"
  '';

  ".config/bat/themes/Catppuccin Macchiato.tmTheme".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>name</key>
        <string>Catppuccin Macchiato</string>
        <key>semanticClass</key>
        <string>theme.dark.catppuccin-macchiato</string>
        <key>uuid</key>
        <string>02b2bdf3-9eb7-4396-bf04-f17f1468f99f</string>
        <key>author</key>
        <string>Catppuccin Org</string>
        <key>colorSpaceName</key>
        <string>sRGB</string>
        <key>settings</key>
        <array>
          <dict>
            <key>settings</key>
            <dict>
              <key>background</key>
              <string>#24273a</string>
              <key>foreground</key>
              <string>#cad3f5</string>
              <key>caret</key>
              <string>#f4dbd6</string>
              <key>lineHighlight</key>
              <string>#363a4f</string>
              <key>misspelling</key>
              <string>#ed8796</string>
              <key>accent</key>
              <string>#c6a0f6</string>
              <key>selection</key>
              <string>#939ab740</string>
              <key>activeGuide</key>
              <string>#494d64</string>
              <key>findHighlight</key>
              <string>#455c6d</string>
              <key>gutterForeground</key>
              <string>#8087a2</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Basic text and variable names</string>
            <key>scope</key>
            <string>text, source, variable.other.readwrite, punctuation.definition.variable</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#cad3f5</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Punctuation</string>
            <key>scope</key>
            <string>punctuation</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#939ab7</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Comments</string>
            <key>scope</key>
            <string>comment, punctuation.definition.comment</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#939ab7</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Strings</string>
            <key>scope</key>
            <string>string, punctuation.definition.string</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#a6da95</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Escape characters</string>
            <key>scope</key>
            <string>constant.character.escape</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#f5bde6</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Numbers and constants</string>
            <key>scope</key>
            <string>constant.numeric, variable.other.constant, entity.name.constant, constant.language.boolean, constant.language.false, constant.language.true, keyword.other.unit</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#f5a97f</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Keywords</string>
            <key>scope</key>
            <string>keyword, keyword.operator.word, keyword.operator.new, variable.language.super, support.type.primitive, storage.type, storage.modifier, punctuation.definition.keyword</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#c6a0f6</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Operators</string>
            <key>scope</key>
            <string>keyword.operator, punctuation.accessor, punctuation.definition.generic, punctuation.definition.tag, punctuation.separator.key-value</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#8bd5ca</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Functions</string>
            <key>scope</key>
            <string>entity.name.function, meta.function-call.method, support.function, variable.function</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#8aadf4</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Classes</string>
            <key>scope</key>
            <string>entity.name.class, entity.other.inherited-class, support.class, entity.name.struct</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#eed49f</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Types</string>
            <key>scope</key>
            <string>meta.type, support.type, entity.name.type</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#eed49f</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Parameters</string>
            <key>scope</key>
            <string>variable.parameter</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#ee99a0</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Built-ins</string>
            <key>scope</key>
            <string>constant.language, support.function.builtin</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#ed8796</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Property names</string>
            <key>scope</key>
            <string>support.type.property-name</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#8aadf4</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Tags</string>
            <key>scope</key>
            <string>entity.name.tag</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#8aadf4</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Attributes</string>
            <key>scope</key>
            <string>entity.other.attribute-name</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#eed49f</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Headings</string>
            <key>scope</key>
            <string>markup.heading</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#ed8796</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Bold</string>
            <key>scope</key>
            <string>markup.bold</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#ed8796</string>
              <key>fontStyle</key>
              <string>bold</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Italic</string>
            <key>scope</key>
            <string>markup.italic</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#ed8796</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Code</string>
            <key>scope</key>
            <string>markup.raw, markup.inline.raw</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#a6da95</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Links</string>
            <key>scope</key>
            <string>markup.underline.link</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#8aadf4</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Diff inserted</string>
            <key>scope</key>
            <string>markup.inserted</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#a6da95</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Diff deleted</string>
            <key>scope</key>
            <string>markup.deleted</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#ed8796</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Diff changed</string>
            <key>scope</key>
            <string>markup.changed</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#f5a97f</string>
            </dict>
          </dict>
        </array>
      </dict>
    </plist>
  '';

  ".config/posting/config.yaml".text = ''
    theme: catppuccin-macchiato-blue
  '';

  ".local/share/posting/themes/catppuccin-macchiato-blue.yaml".source = pkgs.writeText "catppuccin-macchiato-blue.yaml" ''
name: "catppuccin-macchiato-blue"
primary: "#8aadf4"
secondary: "#8aadf4"
accent: "#bacff8"
background: "#24273a"
surface: "#363a4f"
error: "#ed8796"
success: "#a6da95"
warning: "#eed49f"
dark: "true"

text_area:
  cursor: "reverse #f4dbd6"
  cursor_line: "underline #cad3f5"
  selection: "reverse #939ab7"
  gutter: "bold #a6da95"
  matched_bracket: "reverse #b8c0e0"

url:
  base: "italic #8aadf4"
  protocol: "bold #8bd5ca"
  separator: "#cad3f5"

syntax:
  json_key: "italic #8aadf4"
  json_number: "#f5a97f"
  json_string: "#a6da95"
  json_boolean: "#91d7e3"
  json_null: "#939ab7"

method:
  get: "bold #8aadf4"
  post: "bold #a6da95"
  put: "bold #eed49f"
  delete: "bold #ed8796"
  patch: "bold #8bd5ca"
  options: "bold #b7bdf8"
  head: "bold #c6a0f6"
  '';
}
