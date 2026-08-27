{ pkgs, config, ... }:

let
  # Catppuccin Macchiato. Single source of truth for the configs below that
  # take 24-bit colour (neomutt has +truecolor, khal's palette takes #RRGGBB
  # in the high-colour slots). Terminal/btop/bat themes above predate this and
  # still carry their own copies.
  cat = {
    rosewater = "#f4dbd6";
    flamingo = "#f0c6c6";
    pink = "#f5bde6";
    mauve = "#c6a0f6";
    red = "#ed8796";
    maroon = "#ee99a0";
    peach = "#f5a97f";
    yellow = "#eed49f";
    green = "#a6da95";
    teal = "#8bd5ca";
    sky = "#91d7e3";
    sapphire = "#7dc4e4";
    blue = "#8aadf4";
    lavender = "#b7bdf8";
    text = "#cad3f5";
    subtext1 = "#b8c0e0";
    subtext0 = "#a5adcb";
    overlay2 = "#939ab7";
    overlay1 = "#8087a2";
    overlay0 = "#6e738d";
    surface2 = "#5b6078";
    surface1 = "#494d64";
    surface0 = "#363a4f";
    base = "#24273a";
    mantle = "#1e2030";
    crust = "#181926";
  };

  # (An xterm-256 approximation table used to live here for neomutt. It was
  # dropped: the 256-cube nearest neighbours are visibly off — notably base
  # #24273a landing on the neutral grey color235 — which left a seam between the
  # neomutt pane and everything else. neomutt now uses the ANSI 0-15 slots and
  # `default`, which the terminal already maps to exact Catppuccin values.)
in
{
  ".local/bin/pinentry-auto".source = pkgs.writeShellScript "pinentry-auto" ''
    # Use curses pinentry for SSH, mac pinentry otherwise
    if [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]; then
      exec ${pkgs.pinentry-curses}/bin/pinentry-curses "$@"
    else
      exec /usr/local/MacGPG2/libexec/pinentry-mac.app/Contents/MacOS/pinentry-mac "$@"
    fi
  '';

  ".gnupg/gpg-agent.conf".text = ''
    default-cache-ttl 86400
    max-cache-ttl 86400
    pinentry-program /Users/twostal/.local/bin/pinentry-auto
  '';
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

  ".local/share/posting/themes/catppuccin-macchiato-blue.yaml".source =
    pkgs.writeText "catppuccin-macchiato-blue.yaml" ''
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

  # gh-dash for Codeberg. No instance URL or token here on purpose: tea-dash
  # reads both from tea's own config, so `tea login list` stays the single
  # source of truth and no credential lands in the world-readable /nix/store.
  # `login` is named explicitly because that login is not marked default.
  ".config/tea-dash/config.yml".text = ''
    instance:
      login: codeberg
    prSections:
      - title: My PRs
        filter:
          state: open
          createdBy: "@me"
      - title: Needs Review
        filter:
          reviewRequested: "@me"
      - title: All Open
        filter:
          state: open
    issuesSections:
      - title: My Issues
        filter:
          state: open
          createdBy: "@me"
      - title: Assigned
        filter:
          state: open
          assignedBy: "@me"
    # Only title/limit here — unlike gh-dash, tea-dash notification sections
    # take no filters, so the old reason:review-requested / reason:mention
    # splits have no equivalent and collapse into one list.
    notificationsSections:
      - title: Inbox
        limit: 20
    defaults:
      preview:
        open: true
        # Columns, not a fraction: gh-dash's 0.45 would be read as 0 here,
        # which happens to mean "automatic 50/50" — spelled out instead.
        width: 0
      prsLimit: 20
      issuesLimit: 20
      notificationsLimit: 20
      view: prs
      refetchIntervalMinutes: 30
    # No global `repos:` list: with one set, sections without their own repo:
    # fan out over just those repos instead of searching the whole instance,
    # which would quietly narrow "All Open".
    repoPaths:
      "mistwolftech/*": ~/projects/{{.Repo}}
    keybindings:
      prs:
        - key: g
          name: lazygit
          command: >-
            tmux new-window '
              cd {{.RepoPath}} && lazygit
            '
        - key: C
          name: claude review
          command: >-
            tmux new-window '
              cd {{.RepoPath}} && claude "Review PR {{.PrNumber}} in {{.RepoName}}. Run: tea pulls {{.PrNumber}} --comments for the description, and git fetch origin pull/{{.PrNumber}}/head && git diff origin/main...FETCH_HEAD for the changes. Provide a thorough code review."
            '
    theme:
      icons: nerd
    confirmQuit: false
  '';

  # Google Calendar -> local vdir. OAuth client lives in GCP project
  # gcalcli-tw-2026 (published, so the refresh token never expires).
  # The CalDAV API must stay enabled on that project or discovery 403s.
  # Secrets are read at runtime from ~/.config/vdirsyncer/{client_id,client_secret}
  # (mode 600) because this file lands world-readable in /nix/store.
  ".config/vdirsyncer/config".text = ''
    [general]
    status_path = "~/.local/share/vdirsyncer/status/"

    [pair google]
    a = "google_local"
    b = "google_remote"
    collections = ["from b"]
    conflict_resolution = "b wins"
    metadata = ["displayname", "color"]

    [storage google_local]
    type = "filesystem"
    path = "~/.local/share/calendars/"
    fileext = ".ics"

    [storage google_remote]
    type = "google_calendar"
    token_file = "~/.local/share/vdirsyncer/google_token"
    client_id.fetch = ["shell", "cat ~/.config/vdirsyncer/client_id"]
    client_secret.fetch = ["shell", "cat ~/.config/vdirsyncer/client_secret"]
    # Bounded window: keeps the vdir small and skips a legacy CNCF/Bevy invite
    # from 2025-03-12 whose UID contains slashes, which breaks filesystem storage.
    # Changing these bounds requires wiping the vdir + status first, otherwise
    # vdirsyncer reads the newly out-of-range events as local deletions.
    start_date = "datetime.now() - timedelta(days=90)"
    end_date = "datetime.now() + timedelta(days=730)"

    # Second Google account (Workspace, itomm.pl) — separate token, separate
    # vdir. Collections are pinned rather than "from b": that account also
    # exposes "Święta w Polsce" and "Holidays in Poland", which would duplicate
    # the holidays already synced from the personal account.
    [pair itomm]
    a = "itomm_local"
    b = "itomm_remote"
    collections = ["tomasz.wostal@itomm.pl"]
    conflict_resolution = "b wins"
    metadata = ["displayname", "color"]

    [storage itomm_local]
    type = "filesystem"
    path = "~/.local/share/calendars-itomm/"
    fileext = ".ics"

    [storage itomm_remote]
    type = "google_calendar"
    token_file = "~/.local/share/vdirsyncer/itomm_token"
    client_id.fetch = ["shell", "cat ~/.config/vdirsyncer/client_id"]
    client_secret.fetch = ["shell", "cat ~/.config/vdirsyncer/client_secret"]
    start_date = "datetime.now() - timedelta(days=90)"
    end_date = "datetime.now() + timedelta(days=730)"
  '';

  # Calendars are listed explicitly rather than `type = discover` so the colours
  # are Catppuccin instead of whatever Google assigned. The IDs are the vdir
  # directory names created by vdirsyncer; a new Google calendar needs an entry here.
  ".config/khal/config".text = ''
    [calendars]

      [[personal]]
      path = ~/.local/share/calendars/tomasz.wostal@gmail.com
      color = '${cat.blue}'

      [[family]]
      path = ~/.local/share/calendars/family01431012608072901150@group.calendar.google.com
      color = '${cat.green}'

      [[holidays]]
      path = ~/.local/share/calendars/e1m2ss3fdhkn6q13d1nmoqb4c5sk0pridtqn0bjm5phm2r35dpi62shectnmuprcckn66rrd@virtual
      color = '${cat.red}'
      readonly = True

      [[moon]]
      path = ~/.local/share/calendars/ht3jlfaac5lfd6263ulfh4tql8@group.calendar.google.com
      color = '${cat.lavender}'
      readonly = True

      [[work]]
      path = ~/.local/share/calendars-itomm/tomasz.wostal@itomm.pl
      color = '${cat.peach}'

    [locale]
    local_timezone = Europe/Warsaw
    default_timezone = Europe/Warsaw
    timeformat = %H:%M
    dateformat = %d.%m.
    longdateformat = %d.%m.%Y
    datetimeformat = %d.%m. %H:%M
    longdatetimeformat = %d.%m.%Y %H:%M
    firstweekday = 0
    unicode_symbols = True

    [view]
    theme = dark
    # Default format appends the full description, which makes `khal list`
    # unreadable for events with long notes. Use `khal at`/`khal search` for detail.
    agenda_event_format = {calendar-color}{start-end-time-style} {title}{repeat-symbol}{alarm-symbol}{reset}
    event_format = {calendar-color}{start-end-time-style} {title}{repeat-symbol}{alarm-symbol}{reset}

    # Catppuccin Macchiato for ikhal. Entries must be length 2, 3 or 5, and the
    # first two slots only accept the 16 named colours — so the real values go
    # in the trailing high-colour slots and the 16-colour slots stay empty.
    [palette]
    header = "", "", "", "${cat.subtext1}", "${cat.mantle}"
    footer = "", "", "", "${cat.subtext1}", "${cat.mantle}"
    line header = "", "", "", "${cat.text}", "${cat.surface0}"
    alt header = "", "", "", "${cat.overlay1}", "${cat.base}"
    bright = "", "", "", "${cat.blue}", "${cat.base}"
    list = "", "", "", "${cat.text}", "${cat.base}"
    list focused = "", "", "", "${cat.base}", "${cat.blue}"
    edit = "", "", "", "${cat.text}", "${cat.base}"
    edit focus = "", "", "", "${cat.base}", "${cat.blue}"
    editbx = "", "", "", "${cat.text}", "${cat.surface0}"
    editcp = "", "", "", "${cat.base}", "${cat.lavender}"
    button = "", "", "", "${cat.text}", "${cat.surface1}"
    button focused = "", "", "", "${cat.base}", "${cat.blue}"
    reveal focus = "", "", "", "${cat.base}", "${cat.lavender}"
    today = "", "", "", "${cat.base}", "${cat.peach}"
    today focus = "", "", "", "${cat.base}", "${cat.mauve}"
    date header = "", "", "", "${cat.subtext0}", "${cat.base}"
    date header focused = "", "", "", "${cat.base}", "${cat.sapphire}"
    date header selected = "", "", "", "${cat.base}", "${cat.teal}"
    dayname = "", "", "", "${cat.sky}", "${cat.base}"
    monthname = "", "", "", "${cat.mauve}", "${cat.base}"
    weeknumber_right = "", "", "", "${cat.overlay0}", "${cat.base}"
    alert = "", "", "", "${cat.base}", "${cat.red}"
    mark = "", "", "", "${cat.base}", "${cat.green}"
    frame = "", "", "", "${cat.surface2}", "${cat.base}"
    frame focus = "", "", "", "${cat.blue}", "${cat.base}"
    frame focus color = "", "", "", "${cat.blue}", "${cat.base}"
    frame focus top = "", "", "", "${cat.mauve}", "${cat.base}"
    popupbg = "", "", "", "${cat.text}", "${cat.mantle}"

    [default]
    # Must match a calendar *name* from [calendars] above, not the Google ID.
    default_calendar = personal
    highlight_event_days = True
  '';

  # notmuch indexes ~/Mail, which lieer fills from Gmail.
  # Paths are relative, which notmuch resolves against $HOME.
  ".config/notmuch/default/config".text = ''
    [database]
    path=Mail
    mail_root=Mail

    [user]
    name=Tomasz Wostal
    primary_email=tomasz@wostal.eu
    other_email=tomasz.wostal@itomm.pl;tomasz.wostal@gmail.com;tomasz.wostal@devops.toys;tomasz.wostal@mistwolf.tech;support@wostal.eu;info@wostal.eu;support@mistwolf.tech;info@mistwolf.tech

    [new]
    # Deliberately empty: lieer derives tags from Gmail labels, and any tag added
    # here would be pushed back to Gmail as a stray label ("new" is not on
    # lieer's ignore list). Mail arriving via mbsync would need a post-new hook.
    tags=
    ignore=/.*[.](json|lock|bak|tmp)$/;.uidvalidity;.mbsyncstate;.notmuch

    [search]
    exclude_tags=trash;spam;deleted

    [maildir]
    synchronize_flags=true
  '';

  # Empty marker so the directory exists for neomutt's header cache.
  ".cache/neomutt/.keep".text = "";

  ".config/neomutt/neomuttrc".text = ''
    # ---------------------------------------------------------------- identity
    set realname = "Tomasz Wostal"
    set from     = "tomasz@wostal.eu"
    set use_from = yes
    set reverse_name = yes      # reply from whichever identity received the mail
    alternates "^(tomasz\.wostal@gmail\.com|tomasz\.wostal@itomm\.pl|tomasz@wostal\.eu|tomasz\.wostal@devops\.toys|tomasz\.wostal@mistwolf\.tech|(support|info)@(wostal\.eu|mistwolf\.tech))$"

    # Pick the identity with <esc>1..<esc>5 while composing; msmtp follows the
    # From address on its own, so nothing else needs switching.
    macro compose <esc>1 "<edit-from><kill-line>tomasz@wostal.eu<enter>" "from: wostal.eu"
    macro compose <esc>2 "<edit-from><kill-line>tomasz.wostal@itomm.pl<enter>" "from: itomm.pl"
    macro compose <esc>3 "<edit-from><kill-line>tomasz.wostal@gmail.com<enter>" "from: gmail"
    macro compose <esc>4 "<edit-from><kill-line>tomasz.wostal@devops.toys<enter>" "from: devops.toys"
    macro compose <esc>5 "<edit-from><kill-line>tomasz.wostal@mistwolf.tech<enter>" "from: mistwolf.tech"
    macro compose <esc>6 "<edit-from><kill-line>support@mistwolf.tech<enter>" "from: support@mistwolf.tech"
    macro compose <esc>7 "<edit-from><kill-line>info@mistwolf.tech<enter>" "from: info@mistwolf.tech"
    macro compose <esc>8 "<edit-from><kill-line>support@wostal.eu<enter>" "from: support@wostal.eu"
    macro compose <esc>9 "<edit-from><kill-line>info@wostal.eu<enter>" "from: info@wostal.eu"

    # ---------------------------------------------------------------- notmuch
    # Absolute path required: neomutt does not expand ~ inside a notmuch:// URL.
    set nm_default_url   = "notmuch:///Users/twostal/Mail"
    # Note the underscore: the old `virtual_spoolfile` spelling is silently
    # mis-parsed into `spool_file = "yes"` instead of erroring out.
    set virtual_spool_file = yes
    set nm_record        = no
    set header_cache     = "~/.cache/neomutt"

    # notmuch indexes all of ~/Mail, so these span both accounts at once.
    virtual-mailboxes "Inbox"   "notmuch://?query=tag:inbox and not tag:trash"
    virtual-mailboxes "Unread"  "notmuch://?query=tag:unread and not tag:trash"
    virtual-mailboxes "Flagged" "notmuch://?query=tag:flagged"
    virtual-mailboxes "Sent"    "notmuch://?query=tag:sent"
    virtual-mailboxes "Archive" "notmuch://?query=not tag:inbox and not tag:trash and not tag:sent"
    virtual-mailboxes "All"     "notmuch://?query=not tag:trash"

    # Per-account views. The merged mailboxes above give no clue which account a
    # message came from; `path:` filters on the maildir, which is the only thing
    # that distinguishes them (Gmail labels become identical tags on both).
    virtual-mailboxes "· gmail"     "notmuch://?query=tag:inbox and not tag:trash and path:gmail/**"
    virtual-mailboxes "· itomm"     "notmuch://?query=tag:inbox and not tag:trash and path:itomm/**"
    virtual-mailboxes "· gmail new" "notmuch://?query=tag:unread and not tag:trash and path:gmail/**"
    virtual-mailboxes "· itomm new" "notmuch://?query=tag:unread and not tag:trash and path:itomm/**"

    # ---------------------------------------------------------------- behaviour
    set sort          = threads
    set sort_aux      = reverse-last-date-received
    set mark_old      = no
    set help          = no
    set mail_check_stats = yes
    auto_view text/html
    alternative_order text/plain text/enriched text/html

    # ---------------------------------------------------------------- sidebar
    set sidebar_visible = yes
    set sidebar_width   = 22
    set sidebar_short_path = yes
    set sidebar_format  = "%D%* %?N?%N/? %S"
    bind index,pager \Cp sidebar-prev
    bind index,pager \Cn sidebar-next
    bind index,pager \Co sidebar-open

    # ---------------------------------------------------------------- Catppuccin Macchiato
    set crypt_use_gpgme = yes

    # Uses the ANSI 0-15 slots and `default`, NOT 256-cube approximations.
    # Ghostty's palette (modules/darwin/files.nix) already sets 0-15 to the exact
    # Catppuccin Macchiato values, background #24273a and foreground #cad3f5 — so
    # color4 renders as exactly #8aadf4, the same value khal emits as truecolor.
    # `default` for the background is what removes the seam between panes: any
    # explicit dark here paints a slightly different black than the terminal's.
    # This also survives SSH, where TERM drops to xterm-256color but the remote
    # terminal still applies the same 16-colour palette.
    #   0 surface1  1 red     2 green  3 yellow  4 blue
    #   5 pink      6 teal    7 subtext1  8 surface2  15 subtext0
    color normal      default  default
    color indicator   default  color4
    color status      color7   color0
    color error       color1   default
    color message     color6   default
    color markers     color1   default
    color tilde       color8   default
    color tree        color4   default
    color search      color0   color3
    color attachment  color5   default
    color signature   color15  default
    color bold        color7   default
    color underline   color7   default
    color progress    color0   color4
    color prompt      default  default

    color hdrdefault  color6   default
    color header      color4   default "^(From|Subject):"
    color header      color2   default "^(To|Cc):"

    color quoted      color2   default
    color quoted1     color6   default
    color quoted2     color4   default
    color quoted3     color5   default
    color quoted4     color15  default

    color body        color4   default "(https?|ftp)://[^ ]+"
    color body        color5   default "[-a-z_0-9.%+]+@[-a-z_0-9.]+\.[a-z]+"

    color index         default  default "~A"
    color index         color2   default "~N"
    color index         color3   default "~F"
    color index         color1   default "~D"
    color index         color8   default "~Q"
    color index_author  color5   default "~A"
    color index_subject default  default "~A"
    color index_date    color6   default
    color index_number  color8   default
    color index_size    color15  default

    color sidebar_divider   color0   default
    color sidebar_new       color2   default
    color sidebar_highlight default  color0
    color sidebar_indicator default  color4

    # ---------------------------------------------------------------- sending
    set sendmail          = "${pkgs.msmtp}/bin/msmtp"
    set sendmail_wait     = 0
    set use_envelope_from = yes
    set copy              = no   # lieer pulls the Gmail copy back into notmuch
  '';

  # Prints a short-lived Gmail access token for msmtp's XOAUTH2. Takes the
  # account name and reads ~/.config/msmtp/<name>-oauth.json (mode 600, outside
  # the store); this script only reads it. Tool paths are pinned because msmtp
  # may be invoked from neomutt with a minimal PATH.
  ".local/bin/msmtp-oauth-token".source = pkgs.writeShellScript "msmtp-oauth-token" ''
    set -euo pipefail
    cfg="$HOME/.config/msmtp/''${1:?podaj nazwe konta}-oauth.json"
    jq="${pkgs.jq}/bin/jq"
    ${pkgs.curl}/bin/curl -s --fail \
      -d client_id="$("$jq" -r .client_id "$cfg")" \
      -d client_secret="$("$jq" -r .client_secret "$cfg")" \
      -d refresh_token="$("$jq" -r .refresh_token "$cfg")" \
      -d grant_type=refresh_token \
      https://oauth2.googleapis.com/token \
      | "$jq" -re .access_token
  '';

  # Three-pane dashboard for the sesh "inbox" window: neomutt on the left,
  # calendar top-right, tasks bottom-right.
  # Refresh is a plain `clear; cmd; sleep` loop rather than watch(1): `watch -c`
  # silently drops 24-bit sequences, so khal's Catppuccin colours would degrade
  # to plain SGR. Verified — direct khal emits four `38;2;` runs, through
  # `watch -c` zero, through this loop four.
  ".local/bin/tmux-inbox".source = pkgs.writeShellScript "tmux-inbox" ''
    set -u
    self="$0"
    case "''${1:-}" in
      --khal)
        while :; do
          clear
          ${pkgs.khal}/bin/khal --color list today 14d 2>&1
          sleep 60
        done
        ;;
      --task)
        while :; do
          clear
          ${pkgs.taskwarrior2}/bin/task rc._forcecolor=on rc.confirmation=no 2>&1
          sleep 60
        done
        ;;
      *)
        here="''${TMUX_PANE:-}"
        ${pkgs.tmux}/bin/tmux split-window -h -l 45% "$self --khal"
        ${pkgs.tmux}/bin/tmux split-window -v -l 50% "$self --task"
        [ -n "$here" ] && ${pkgs.tmux}/bin/tmux select-pane -t "$here"
        exec ${pkgs.neomutt}/bin/neomutt
        ;;
    esac
  '';

  # Codeberg's *native* issue tracker, which bugwarrior cannot reach: it has no
  # gitea/forgejo service and 2.1.0 is the newest upstream release. git-bug only
  # covers issues stored as git refs, so without this the Forgejo issues you
  # actually work from stay invisible. Repos are discovered from git remotes
  # rather than hardcoded. Token: ~/.config/codeberg/token (0600).
  ".local/bin/codeberg-tasks".source =
    pkgs.writeScript "codeberg-tasks" ''
      #!${pkgs.python3}/bin/python3
      import os
      os.environ["PATH"] = "${pkgs.taskwarrior2}/bin:${pkgs.git}/bin:" + os.environ.get("PATH", "")
      ${builtins.readFile ./codeberg-tasks.py}
    '';

  # One section per repo, each on its own port: bugwarrior's gitbug service
  # works by spawning `git-bug webui` and querying its GraphQL endpoint, and the
  # port setting defaults to 43915 for every service — leave it at the default
  # and the repos collide. Note this spawns one webui subprocess per repo per
  # pull, so the run cost grows linearly with this list.
  ".config/bugwarrior/bugwarrior.toml".text =
    let
      repos = [
        "cd-homelab"
        "drift-warden"
        "hydro-habitat"
        # "hydrohabitat" — stale local clone; mistwolftech/hydrohabitat no longer
        # exists on Codeberg ("Cannot find repository"). hydro-habitat is the live one.
        "iac-hetzner"
        "mistwolf-tech"
        "mistwolf-video-producer"
        "nexus-hetzner"
        "publishing-queue"
        "wostal-cloud"
        "wostal-eu"
      ];
      section = i: r: ''

        [${r}]
        service = "gitbug"
        path = "~/projects/${r}"
        port = ${toString (43915 + i)}
        add_tags = ["${r}"]
        # Default template renders "(bw)Bug# - <title>": it wants an issue
        # number and git-bug has none, leaving a bare "Bug#" stub.
        description_template = "{{gitbugtitle}}"
      '';
    in
    ''
      [general]
      targets = [${pkgs.lib.concatMapStringsSep ", " (r: ''"${r}"'') repos}]
      taskrc = "~/.taskrc"
      inline_links = false
      annotation_links = true
    ''
    + pkgs.lib.concatStrings (pkgs.lib.imap0 section repos);

  # Catppuccin Macchiato via the ANSI 0-15 slots, same reasoning as neomutt:
  # the terminal palette already *is* Catppuccin, so color4 is exactly #8aadf4
  # and `default` inherits the real background — no second, slightly-off black.
  ".taskrc".text = ''
    data.location=~/.task
    confirmation=no
    verbose=label,affected,blank,footnote,header,special
    news.version=2.6.2

    # --- report tweaks
    default.command=next
    report.next.columns=id,start.age,entry.age,depends,priority,project,tags,recur,scheduled.countdown,due.relative,until.remaining,description,urgency
    report.next.labels=ID,Active,Age,Deps,P,Project,Tag,Recur,S,Due,Until,Description,Urg
    # bugwarrior's gitbug service keeps returning closed bugs, so it never
    # "closes" the task — it only flips the gitbugstate UDA. Without this filter
    # every bug you ever closed stays on the list forever. Verified that tasks
    # with no gitbugstate at all (i.e. ones you added by hand) still show up.
    report.next.filter=status:pending -WAITING gitbugstate.isnt:CLOSED
    # Everything git-bug knows about, closed included.
    report.bugs.description=git-bug issues
    report.bugs.columns=id,project,tags,gitbugstate,description,urgency
    report.bugs.labels=ID,Project,Tag,State,Description,Urg
    report.bugs.filter=status:pending gitbugid.any:
    report.bugs.sort=urgency-

    # --- Catppuccin Macchiato
    rule.precedence.color=deleted,completed,active,keyword.,tag.,project.,overdue,scheduled,due.today,due,blocked,blocking,recurring,tagged,uda.
    color=on
    color.active=color0 on color3
    color.overdue=color1
    color.due.today=color1
    color.due=color3
    color.scheduled=color6
    color.recurring=color5
    color.blocked=color8
    color.blocking=color5
    color.tagged=color2
    color.completed=color8
    color.deleted=color8
    color.header=color4
    color.footnote=color6
    color.label=color7
    color.label.sort=color7
    color.error=color1
    color.debug=color8
    color.alternate=
    color.calendar.today=color0 on color4
    color.calendar.due=color0 on color1
    color.calendar.due.today=color0 on color1
    color.calendar.overdue=color0 on color5
    color.calendar.weekend=
    color.calendar.holiday=color0 on color3
    color.calendar.weeknumber=color8

    # --- UDAs written by bugwarrior's gitbug service.
    # Without these the description renders as a bare "(bw)Bug#" placeholder.
    uda.gitbugauthor.type=string
    uda.gitbugauthor.label=Gitbug Issue Author
    uda.gitbugid.type=string
    uda.gitbugid.label=Gitbug UUID
    uda.gitbugstate.type=string
    uda.gitbugstate.label=Gitbug state
    uda.gitbugtitle.type=string
    uda.gitbugtitle.label=Gitbug Title

    # --- UDAs for codeberg-tasks (Forgejo importer).
    # These MUST be declared here. `task config uda...` cannot add them at
    # runtime because this file is a read-only nix store symlink — the write
    # fails silently and taskwarrior then folds "cbissue:..." into the task
    # *description* instead, so `cbissue.any:` matches nothing and every run
    # re-adds every issue as a duplicate.
    uda.cbissue.type=string
    uda.cbissue.label=Codeberg Issue
    uda.cburl.type=string
    uda.cburl.label=Codeberg URL
  '';

  # pass holds the canonical copy of the *static* secrets. Runtime reads stay on
  # the plain 0600 files on purpose: the launchd sync agents run unattended, and
  # routing them through pass would make every cycle depend on an unlocked
  # gpg-agent (24h TTL here, GUI pinentry) — a cold cache would either pop a
  # dialog at a random moment or fail silently.
  ".local/bin/secrets-restore".source = pkgs.writeShellScript "secrets-restore" ''
    set -euo pipefail
    umask 077
    r() {
      mkdir -p "$(dirname "$2")"
      ${pkgs.pass}/bin/pass show "$1" > "$2"
      chmod 600 "$2"
      echo "  $2"
    }
    echo "Odtwarzam z pass:"
    r email/oauth/vdirsyncer-client-id     "$HOME/.config/vdirsyncer/client_id"
    r email/oauth/vdirsyncer-client-secret "$HOME/.config/vdirsyncer/client_secret"
    r email/oauth/lieer-client.json        "$HOME/.config/lieer/client_secret.json"
    r email/oauth/msmtp-gmail.json         "$HOME/.config/msmtp/gmail-oauth.json"
    r email/oauth/msmtp-itomm.json         "$HOME/.config/msmtp/itomm-oauth.json"
    r codeberg/api-token                   "$HOME/.config/codeberg/token"
    echo
    echo "NIE do odtworzenia (stan runtime, rotowany przez same narzedzia):"
    echo "  ~/Mail/{gmail,itomm}/.credentials.gmailieer.json"
    echo "    -> gmi auth -C ~/Mail/<repo> -c ~/.config/lieer/client_secret.json"
    echo "  ~/.local/share/vdirsyncer/{google,itomm}_token"
    echo "    -> vdirsyncer discover"
  '';

  # Counterpart: push the current on-disk secrets back into pass after a
  # re-authorisation issues a new refresh token.
  ".local/bin/secrets-backup".source = pkgs.writeShellScript "secrets-backup" ''
    set -euo pipefail
    b() {
      [ -f "$2" ] || { echo "  pomijam (brak): $2"; return 0; }
      ${pkgs.pass}/bin/pass insert -m -f "$1" < "$2" >/dev/null
      echo "  $1 <- $2"
    }
    echo "Zapisuje do pass:"
    b email/oauth/vdirsyncer-client-id     "$HOME/.config/vdirsyncer/client_id"
    b email/oauth/vdirsyncer-client-secret "$HOME/.config/vdirsyncer/client_secret"
    b email/oauth/lieer-client.json        "$HOME/.config/lieer/client_secret.json"
    b email/oauth/msmtp-gmail.json         "$HOME/.config/msmtp/gmail-oauth.json"
    b email/oauth/msmtp-itomm.json         "$HOME/.config/msmtp/itomm-oauth.json"
    b codeberg/api-token                   "$HOME/.config/codeberg/token"
    if ${pkgs.git}/bin/git -C "$HOME/.password-store" rev-parse --git-dir >/dev/null 2>&1; then
      ${pkgs.pass}/bin/pass git push 2>/dev/null && echo "  wypchnieto na remote" || echo "  (push nieudany - sprawdz remote)"
    fi
  '';

  # No password anywhere in here, so it is safe to live world-readable in the
  # nix store — msmtp only refuses that for configs containing a literal
  # `password` line. Gmail's SMTP needs the full https://mail.google.com/
  # scope; the narrower gmail.send that lieer-style scopes give is rejected.
  # Two real mailboxes, five identities. neomutt passes -f <address> (it has
  # use_envelope_from set), and msmtp picks the first account whose `from`
  # matches — so switching identity in neomutt switches the SMTP account with
  # no further wiring. The wostal.eu / devops.toys / mistwolf.tech identities
  # are Gmail "send as" aliases of the itomm mailbox, so they authenticate as
  # tomasz.wostal@itomm.pl and reuse its token.
  ".msmtprc".text = ''
    defaults
    auth           xoauth2
    tls            on
    tls_starttls   on
    logfile        ~/.cache/msmtp.log
    host           smtp.gmail.com
    port           587

    account        gmail
    from           tomasz.wostal@gmail.com
    user           tomasz.wostal@gmail.com
    passwordeval   "$HOME/.local/bin/msmtp-oauth-token gmail"

    account        itomm
    from           tomasz.wostal@itomm.pl
    user           tomasz.wostal@itomm.pl
    passwordeval   "$HOME/.local/bin/msmtp-oauth-token itomm"

    account        wostal
    from           tomasz@wostal.eu
    user           tomasz.wostal@itomm.pl
    passwordeval   "$HOME/.local/bin/msmtp-oauth-token itomm"

    account        devops
    from           tomasz.wostal@devops.toys
    user           tomasz.wostal@itomm.pl
    passwordeval   "$HOME/.local/bin/msmtp-oauth-token itomm"

    account        mistwolf
    from           tomasz.wostal@mistwolf.tech
    user           tomasz.wostal@itomm.pl
    passwordeval   "$HOME/.local/bin/msmtp-oauth-token itomm"

    account        support-mistwolf
    from           support@mistwolf.tech
    user           tomasz.wostal@itomm.pl
    passwordeval   "$HOME/.local/bin/msmtp-oauth-token itomm"

    account        info-mistwolf
    from           info@mistwolf.tech
    user           tomasz.wostal@itomm.pl
    passwordeval   "$HOME/.local/bin/msmtp-oauth-token itomm"

    account        support-wostal
    from           support@wostal.eu
    user           tomasz.wostal@itomm.pl
    passwordeval   "$HOME/.local/bin/msmtp-oauth-token itomm"

    account        info-wostal
    from           info@wostal.eu
    user           tomasz.wostal@itomm.pl
    passwordeval   "$HOME/.local/bin/msmtp-oauth-token itomm"

    # Matches the Gmail default sending identity of the itomm mailbox.
    account default : wostal
  '';

}
