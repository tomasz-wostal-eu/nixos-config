{
  config,
  pkgs,
  lib,
  ...
}:

let
  name = "Tomasz Wostal";
  user = "twostal";
  email = "tomasz@wostal.eu";
in
{

  # Shared shell configuration
  zsh = {
    enable = true;
    oh-my-zsh.enable = true;
    initContent = ''
      path+=("$HOME/.local/bin")
      path+=("$HOME/.cache/npm/global/bin/")
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
          fi
    '';
  };

  atuin = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      search_mode = "fuzzy";
      style = "full";
      enter_accept = false;
      keymap_mode = "vim-normal";
      theme = {
        name = "catppuccin-macchiato-blue";
      };
    };
    themes = {
      "catppuccin-macchiato-blue" = ''
        [theme]
        name = "catppuccin-macchiato-blue"
          [colors]
          AlertInfo = "#a6da95"
            AlertWarn = "#f5a97f"
            AlertError = "#ed8796"
            Annotation = "#8aadf4"
            Base = "#cad3f5"
            Guidance = "#939ab7"
            Important = "#ed8796"
            Title = "#8aadf4"
      '';
      "catppuccin-macchiato-mauve" = ''
        [theme]
        name = "catppuccin-macchiato-mauve"
          [colors]
          AlertInfo = "#a6da95"
            AlertWarn = "#f5a97f"
            AlertError = "#ed8796"
            Annotation = "#c6a0f6"
            Base = "#cad3f5"
            Guidance = "#939ab7"
            Important = "#ed8796"
            Title = "#c6a0f6"
      '';
    };
  };

  carapace = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  starship = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    settings = {
      add_newline = false;
      format = "$directory$character";
      palette = "catppuccin_macchiato";
      right_format = "$all";
      command_timeout = 1000;
      character = {
        success_symbol = "[➜](bold green)";
        vicmd_symbol = "[N] >>>";
      };
      directory.substitutions = {
        "~/tests/starship-custom" = "work-project";
      };
      git_branch.format = "[$symbol$branch(:$remote_branch)]($style)";
      aws = {
        format = "[$symbol(profile: \"$profile\" )(\\(region: $region\\) )]($style)";
        disabled = true;
        style = "bold blue";
        symbol = " ";
      };
      golang.format = "[ ](bold cyan)";
      kubernetes = {
        symbol = "☸ ";
        disabled = false;
        format = "[$symbol$context( \\($namespace\\))]($style) ";
      };
      docker_context.disabled = false;

      palettes.catppuccin_macchiato = {
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
    };
  };

  tmux = {
    enable = true;
    prefix = "C-a";
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 1000000;
    keyMode = "vi";
    terminal = "tmux-256color";
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor "macchiato"
          set -g @catppuccin_window_status_style "rounded"
          set -g @catppuccin_status_background "default"
          set -g @catppuccin_window_text " #W"
          set -g @catppuccin_window_current_text " #W"
          set -g @catppuccin_date_time_text " %d/%m %H:%M"
        '';
      }
      sensible
      yank
      resurrect
      continuum
      tmux-thumbs
      tmux-fzf
      fzf-tmux-url
      tmux-sessionx
      tmux-floax
    ];

    extraConfig = ''
      set -g status on
      set -g status-position top
      set -g status-interval 2
      set -g detach-on-destroy off
      set -g renumber-windows on
      set -g set-clipboard on
      set -as terminal-features ",xterm-256color:RGB"
      set -as terminal-features ",xterm-ghostty:RGB"
      set -ag terminal-overrides ",xterm-256color:Tc"
      set -ag terminal-overrides ",tmux-256color:Tc"
      set -ag terminal-overrides ",xterm-ghostty:Tc"
      set-environment -g COLORTERM truecolor
      set -g pane-active-border-style 'fg=magenta,bg=default'
      set -g pane-border-style 'fg=brightblack,bg=default'
      bind r command-prompt -p "rename window:" "rename-window '%%'"
      bind ^X lock-server
      bind ^C new-window -c "$HOME"
      bind ^D detach
      bind H previous-window
      bind L next-window
      bind z resize-pane -Z
      bind s split-window -v -c "#{pane_current_path}"
      bind v split-window -h -c "#{pane_current_path}"
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind -r , resize-pane -L 20
      bind -r . resize-pane -R 20
      bind -r - resize-pane -D 7
      bind -r = resize-pane -U 7
      bind c kill-pane
      bind x swap-pane -D
      bind S choose-session
      bind K send-keys "clear"\; send-keys "Enter"
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      set -g status-left-length 100
      set -g status-right-length 200
      set -g status-left ""
      set -g status-right "#{E:@catppuccin_status_session}"
      set -ag status-right "#[fg=#8bd5ca,bg=#1e2030] 󰻠 #(${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/scripts/cpu_percentage.sh) "
      set -ag status-right "#[fg=#eed49f,bg=#1e2030] 󰍛 #(${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/scripts/ram_percentage.sh) "
      set -ag status-right "#{E:@catppuccin_status_date_time}"
      set -g @floax-width '80%'
      set -g @floax-height '80%'
      set -g @floax-border-color 'magenta'
      set -g @floax-text-color 'blue'
      set -g @floax-bind 'p'
      set -g @floax-change-path 'true'
      set -g @sessionx-bind 'o'
      set -g @sessionx-bind-zo-new-window 'ctrl-y'
      set -g @sessionx-auto-accept 'off'
      set -g @sessionx-zoxide-mode 'on'
      set -g @sessionx-custom-paths '$HOME/dotfiles'
      set -g @sessionx-window-height '85%'
      set -g @sessionx-window-width '75%'
      set -g @sessionx-filter-current 'false'
      set -g @continuum-restore 'on'
      set -g @resurrect-strategy-nvim 'session'
    '';
  };

  ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        identityFile = "~/.ssh/id_ed25519";
        addKeysToAgent = "yes";
      };
      "github.com" = {
        hostname = "github.com";
        user = "git";
      };
    };
  };

  gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
    };
    settings = {
      editor = "nvim";
      git_protocol = "ssh";
    };
  };

  gpg = {
    enable = true;
    settings = {
      default-key = "tomasz@wostal.eu";
      use-agent = true;
      keyserver = "hkps://keys.openpgp.org";
      auto-key-retrieve = true;
    };
  };

  git = {
    enable = true;
    settings = {
      user = {
        name = "Tomasz Wostal";
        email = "tomasz@wostal.eu";
        signingKey = "tomasz@wostal.eu";
      };
      init.defaultBranch = "main";
      commit.gpgsign = true;
      tag.gpgsign = true;
    };
  };

  neovim = {
    enable = true;
  };

  lazyvim = {
    enable = true;
    configFiles = ./lazyvim;
    extras = {
      lang = {
        nix = {
          enable = true;
          installDependencies = true;
          installRuntimeDependencies = true;
        };
        python = {
          enable = true;
          installDependencies = true; # Install ruff
          installRuntimeDependencies = true; # Install python3
        };
        go = {
          enable = true;
          installDependencies = true; # Install gopls, gofumpt, etc.
          installRuntimeDependencies = true; # Install go compiler
        };
      };
    };
    extraPackages = with pkgs; [
      nixd # Nix LSP
      alejandra # Nix formatter
      nil
      nixd
      vimPlugins.plenary-nvim
      vimPlugins.obsidian-nvim
      vimPlugins.nvim-treesitter.withAllGrammars
      tailwindcss
      ansible-lint
      tailwindcss-language-server
      vscode-langservers-extracted # jsonls
      netcoredbg # .NET debugger
      vscode-js-debug
      pyright
      markdown-toc
      pipx
      cmake-lint
      cmake
      fsautocomplete
      csharpier
      fantomas
      vimPlugins.nvim-java-test
      angular-language-server
      typescript
      vimPlugins.nvim-treesitter.withAllGrammars
      tree-sitter
      lua5_1
      mermaid-cli
      viu
      chafa
      ast-grep
      stylua
      shfmt
      ruff
      lua-language-server
      yaml-language-server
      vim-language-server
      sqlite
      statix
    ];
    treesitterParsers = with pkgs.vimPlugins.nvim-treesitter-parsers; [
      c
      nu
      go
      jq
      xml
      css
      sql
      rst
      lua
      csv
      tsx
      cpp
      ini
      vim
      nix
      hcl
      zsh
      diff
      rust
      just
      toml
      json
      cuda
      yaml
      luap
      make
      sway
      helm
      foam
      bash
      scss
      http
      html
      jinja
      templ
      cmake
      query
      typst
      gomod
      bicep
      jsdoc
      regex
      gosum
      nginx
      proto
      goctl
      strace
      promql
      gotmpl
      python
      luadoc
      scheme
      muttrc
      angular
      comment
      graphql
      arduino
      c_sharp
      mermaid
      markdown
      gitcommit
      terraform
      git_config
      ssh_config
      javascript
      pymanifest
      typescript
      git_rebase
      requirements
      jinja_inline
      markdown_inline
      wgsl # WebGPU Shading Language
      templ # Go templ files
    ];
  };

  claude-code = {
    enable = true;
  };

  k9s = {
    enable = true;
    settings = {
      k9s = {
        ui = {
          skin = "catppuccin-macchiato";
        };
      };
    };
    skins = {
      catppuccin-macchiato = {
        k9s = {
          body = {
            fgColor = "#cad3f5";
            bgColor = "#24273a";
            logoColor = "#c6a0f6";
          };
          prompt = {
            fgColor = "#cad3f5";
            bgColor = "#1e2030";
            suggestColor = "#8aadf4";
          };
          help = {
            fgColor = "#cad3f5";
            bgColor = "#24273a";
            sectionColor = "#a6da95";
            keyColor = "#8aadf4";
            numKeyColor = "#ee99a0";
          };
          frame = {
            title = {
              fgColor = "#8bd5ca";
              bgColor = "#24273a";
              highlightColor = "#f5bde6";
              counterColor = "#eed49f";
              filterColor = "#a6da95";
            };
            border = {
              fgColor = "#c6a0f6";
              focusColor = "#b7bdf8";
            };
            menu = {
              fgColor = "#cad3f5";
              keyColor = "#8aadf4";
              numKeyColor = "#ee99a0";
            };
            crumbs = {
              fgColor = "#24273a";
              bgColor = "#ee99a0";
              activeColor = "#f0c6c6";
            };
            status = {
              newColor = "#8aadf4";
              modifyColor = "#b7bdf8";
              addColor = "#a6da95";
              pendingColor = "#f5a97f";
              errorColor = "#ed8796";
              highlightColor = "#91d7e3";
              killColor = "#c6a0f6";
              completedColor = "#6e738d";
            };
          };
          info = {
            fgColor = "#f5a97f";
            sectionColor = "#cad3f5";
          };
          views = {
            table = {
              fgColor = "#cad3f5";
              bgColor = "#24273a";
              cursorFgColor = "#363a4f";
              cursorBgColor = "#494d64";
              markColor = "#f4dbd6";
              header = {
                fgColor = "#eed49f";
                bgColor = "#24273a";
                sorterColor = "#91d7e3";
              };
            };
            xray = {
              fgColor = "#cad3f5";
              bgColor = "#24273a";
              cursorColor = "#494d64";
              cursorTextColor = "#24273a";
              graphicColor = "#f5bde6";
            };
            charts = {
              bgColor = "#24273a";
              chartBgColor = "#24273a";
              dialBgColor = "#24273a";
              defaultDialColors = [
                "#a6da95"
                "#ed8796"
              ];
              defaultChartColors = [
                "#a6da95"
                "#ed8796"
              ];
              resourceColors = {
                cpu = [
                  "#c6a0f6"
                  "#8aadf4"
                ];
                mem = [
                  "#eed49f"
                  "#f5a97f"
                ];
              };
            };
            yaml = {
              keyColor = "#8aadf4";
              valueColor = "#cad3f5";
              colonColor = "#a5adcb";
            };
            logs = {
              fgColor = "#cad3f5";
              bgColor = "#24273a";
              indicator = {
                fgColor = "#b7bdf8";
                bgColor = "#24273a";
                toggleOnColor = "#a6da95";
                toggleOffColor = "#a5adcb";
              };
            };
          };
          dialog = {
            fgColor = "#eed49f";
            bgColor = "#939ab7";
            buttonFgColor = "#24273a";
            buttonBgColor = "#8087a2";
            buttonFocusFgColor = "#24273a";
            buttonFocusBgColor = "#f5bde6";
            labelFgColor = "#f4dbd6";
            fieldFgColor = "#cad3f5";
          };
        };
      };
    };
  };

  btop = {
    enable = true;
    settings = {
      color_theme = "catppuccin_macchiato";
      theme_background = false;
      vim_keys = true;
    };
  };

  bat = {
    enable = true;
    config = {
      theme = "Catppuccin Macchiato";
    };
  };

  zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  direnv = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    nix-direnv.enable = true;
  };

  nushell = {
    enable = true;

    shellAliases = {
      # General
      l = "ls --all";
      c = "clear";
      ll = "ls -l";
      lt = "eza --tree --level=2 --long --icons --git";
      v = "nvim";

      # Git
      gc = "git commit -m";
      gca = "git commit -a -m";
      gp = "git push origin HEAD";
      gpu = "git pull origin";
      gst = "git status";
      glog = "git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit";
      gdiff = "git diff";
      gco = "git checkout";
      gb = "git branch";
      gba = "git branch -a";
      gadd = "git add";
      ga = "git add -p";
      gcoall = "git checkout -- .";
      gr = "git remote";
      gre = "git reset";

      # Kubernetes
      k = "kubectl";
      ka = "kubectl apply -f";
      kg = "kubectl get";
      kd = "kubectl describe";
      kdel = "kubectl delete";
      kl = "kubectl logs -f";
      kgpo = "kubectl get pod";
      kgd = "kubectl get deployments";
      kc = "kubectx";
      kns = "kubens";
      ke = "kubectl exec -it";
    };

    environmentVariables = {
      EDITOR = "nvim";
      DIRENV_LOG_FORMAT = "";
    };

    extraConfig = ''
      # Catppuccin Macchiato color palette
      let catppuccin_macchiato = {
          rosewater: "#f4dbd6"
          flamingo: "#f0c6c6"
          pink: "#f5bde6"
          mauve: "#c6a0f6"
          red: "#ed8796"
          maroon: "#ee99a0"
          peach: "#f5a97f"
          yellow: "#eed49f"
          green: "#a6da95"
          teal: "#8bd5ca"
          sky: "#91d7e3"
          sapphire: "#7dc4e4"
          blue: "#8aadf4"
          lavender: "#b7bdf8"
          text: "#cad3f5"
          subtext1: "#b8c0e0"
          subtext0: "#a5adcb"
          overlay2: "#939ab7"
          overlay1: "#8087a2"
          overlay0: "#6e738d"
          surface2: "#5b6078"
          surface1: "#494d64"
          surface0: "#363a4f"
          base: "#24273a"
          mantle: "#1e2030"
          crust: "#181926"
      }

      let catppuccin_theme = {
          separator: $catppuccin_macchiato.overlay0
          leading_trailing_space_bg: { attr: n }
          header: { fg: $catppuccin_macchiato.blue attr: b }
          empty: $catppuccin_macchiato.lavender
          bool: $catppuccin_macchiato.lavender
          int: $catppuccin_macchiato.peach
          filesize: $catppuccin_macchiato.teal
          duration: $catppuccin_macchiato.lavender
          date: $catppuccin_macchiato.mauve
          range: $catppuccin_macchiato.text
          float: $catppuccin_macchiato.peach
          string: $catppuccin_macchiato.green
          nothing: $catppuccin_macchiato.overlay0
          binary: $catppuccin_macchiato.peach
          cell-path: $catppuccin_macchiato.lavender
          row_index: { fg: $catppuccin_macchiato.mauve attr: b }
          record: $catppuccin_macchiato.text
          list: $catppuccin_macchiato.text
          block: $catppuccin_macchiato.text
          hints: $catppuccin_macchiato.overlay0
          search_result: { fg: $catppuccin_macchiato.base bg: $catppuccin_macchiato.yellow }

          shape_and: { fg: $catppuccin_macchiato.mauve attr: b }
          shape_binary: { fg: $catppuccin_macchiato.mauve attr: b }
          shape_block: { fg: $catppuccin_macchiato.blue attr: b }
          shape_bool: $catppuccin_macchiato.lavender
          shape_closure: { fg: $catppuccin_macchiato.teal attr: b }
          shape_custom: $catppuccin_macchiato.teal
          shape_datetime: { fg: $catppuccin_macchiato.teal attr: b }
          shape_directory: $catppuccin_macchiato.sapphire
          shape_external: $catppuccin_macchiato.sapphire
          shape_externalarg: { fg: $catppuccin_macchiato.green attr: b }
          shape_external_resolved: { fg: $catppuccin_macchiato.green attr: b }
          shape_filepath: $catppuccin_macchiato.sapphire
          shape_flag: { fg: $catppuccin_macchiato.maroon attr: b }
          shape_float: { fg: $catppuccin_macchiato.peach attr: b }
          shape_garbage: { fg: $catppuccin_macchiato.text bg: $catppuccin_macchiato.red attr: b }
          shape_glob_interpolation: { fg: $catppuccin_macchiato.sapphire attr: b }
          shape_globpattern: { fg: $catppuccin_macchiato.sapphire attr: b }
          shape_int: { fg: $catppuccin_macchiato.peach attr: b }
          shape_internalcall: { fg: $catppuccin_macchiato.blue attr: b }
          shape_keyword: { fg: $catppuccin_macchiato.mauve attr: b }
          shape_list: { fg: $catppuccin_macchiato.sapphire attr: b }
          shape_literal: $catppuccin_macchiato.blue
          shape_match_pattern: $catppuccin_macchiato.green
          shape_matching_brackets: { attr: u }
          shape_nothing: $catppuccin_macchiato.lavender
          shape_operator: $catppuccin_macchiato.sky
          shape_or: { fg: $catppuccin_macchiato.mauve attr: b }
          shape_pipe: { fg: $catppuccin_macchiato.mauve attr: b }
          shape_range: { fg: $catppuccin_macchiato.yellow attr: b }
          shape_record: { fg: $catppuccin_macchiato.sapphire attr: b }
          shape_redirection: { fg: $catppuccin_macchiato.mauve attr: b }
          shape_signature: { fg: $catppuccin_macchiato.teal attr: b }
          shape_string: $catppuccin_macchiato.green
          shape_string_interpolation: { fg: $catppuccin_macchiato.sapphire attr: b }
          shape_table: { fg: $catppuccin_macchiato.blue attr: b }
          shape_variable: { fg: $catppuccin_macchiato.flamingo attr: i }
          shape_vardecl: { fg: $catppuccin_macchiato.flamingo attr: i }
          shape_raw_string: { fg: $catppuccin_macchiato.pink attr: b }
      }

      $env.config = ($env.config | merge {
          show_banner: false
          color_config: $catppuccin_theme
          edit_mode: vi
          float_precision: 2
          use_ansi_coloring: true
          bracketed_paste: true
          highlight_resolved_externals: false

          ls: {
              use_ls_colors: true
              clickable_links: true
          }

          rm: {
              always_trash: false
          }

          table: {
              mode: rounded
              index_mode: always
              show_empty: true
              padding: { left: 1, right: 1 }
              trim: {
                  methodology: wrapping
                  wrapping_try_keep_words: true
                  truncating_suffix: "..."
              }
          }

          history: {
              max_size: 100_000
              sync_on_enter: true
              file_format: "plaintext"
              isolation: false
          }

          completions: {
              case_sensitive: false
              quick: true
              partial: true
              algorithm: "prefix"
              use_ls_colors: true
          }

          cursor_shape: {
              emacs: block
              vi_insert: block
              vi_normal: underscore
          }

          shell_integration: {
              osc2: true
              osc7: true
              osc8: true
              osc9_9: false
              osc133: true
              osc633: true
              reset_application_mode: true
          }

          explore: {
              status_bar_background: { fg: $catppuccin_macchiato.crust bg: $catppuccin_macchiato.subtext1 }
              command_bar_text: { fg: $catppuccin_macchiato.subtext1 }
              highlight: { fg: $catppuccin_macchiato.base bg: $catppuccin_macchiato.yellow }
              status: {
                  error: { fg: $catppuccin_macchiato.text bg: $catppuccin_macchiato.red }
                  warn: {}
                  info: {}
              }
              selected_cell: { bg: $catppuccin_macchiato.surface1 }
          }
      })

      # Custom function: cd + ls
      def --env cx [arg] {
          cd $arg
          ls -l
      }
    '';
  };

  eza = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    icons = "auto";
    git = true;
  };

  gemini-cli.enable = true;
  fzf.enable = true;

}
