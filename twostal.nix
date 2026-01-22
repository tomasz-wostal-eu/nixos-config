{
  config,
  pkgs,
  lazyvim,
  lib,
  ...
}:

{
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    copilot-cli
    ripgrep
    fd
    jq
    nodejs
    python3
    lsof
    gcc
    terraform
    terraform-ls
    terraform-lsp
    terraform-inventory
    terraform-compliance
    terraform-landscape
    tfsec
    pipx
    gh
    nerd-fonts.jetbrains-mono
    wl-clipboard # Wayland clipboard
    xclip # X11 clipboard (fallback)
    unimatrix
    hugo
    kubectl
    kubectl-klock
    kubectl-tree
    kubectl-cnpg
    kubectl-neat
    kubectl-doctor
    kubectl-gadget
    kubectl-images
    kubectl-example
    kubectl-explore
    kubectl-validate
    kubectl-evict-pod
    kubectl-node-shell
    kubectl-ai
    kubectl-ktop
    kubectl-df-pv
    kubectl-graph
    kubectl-convert
    kubectl-view-allocations
    kubectl-view-secret
    kubelogin
    kubelogin-oidc
    hetzner-kube
    lazyhetzner
    hcloud
    azure-cli
    doctl
    awscli
    argo-rollouts
    kargo
    argo-workflows
    argocd
    lazygit
    lazydocker
  ];

  # LazyVim
  imports = [ lazyvim.homeManagerModules.default ];

  programs = {
    chromium.enable = true;
    claude-code.enable = true;
    gemini-cli.enable = true;
    ghostty = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        theme = "catppuccin-macchiato";
        font-family = "JetBrainsMono Nerd Font";
        font-size = 12;
        background-blur-radius = 20;
        mouse-hide-while-typing = true;
        window-decoration = true;
        keybind = [
          "shift+enter=text:\\x1b\\r"
        ];
      };
      themes = {
        catppuccin-macchiato = {
          palette = [
            "0=#494d64"
            "1=#ed8796"
            "2=#a6da95"
            "3=#eed49f"
            "4=#8aadf4"
            "5=#f5bde6"
            "6=#8bd5ca"
            "7=#b8c0e0"
            "8=#5b6078"
            "9=#ed8796"
            "10=#a6da95"
            "11=#eed49f"
            "12=#8aadf4"
            "13=#f5bde6"
            "14=#8bd5ca"
            "15=#a5adcb"
          ];
          background = "24273a";
          foreground = "cad3f5";
          cursor-color = "f4dbd6";
          selection-background = "5b6078";
          selection-foreground = "cad3f5";
        };
      };
    };
    fzf.enable = true;

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
        credential."https://github.com".helper = "!gh auth git-credential";
        credential."https://gist.github.com".helper = "!gh auth git-credential";
      };
    };

    gpg = {
      enable = false;
      settings = {
        default-key = "tomasz@wostal.eu";
        use-agent = true;
        keyserver = "hkps://keys.openpgp.org";
        auto-key-retrieve = true;
      };
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

    lazyvim = {
      enable = true;
      pluginSource = "latest";
      extraPackages = with pkgs; [
        tailwindcss
        ansible-lint
        tailwindcss-language-server
        vscode-langservers-extracted # jsonls
        netcoredbg # .NET debugger
        vscode-js-debug
        nixd
        alejandra
        pyright
        markdown-toc
        nil
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
        css
        scss
        latex
        vue
        tsx
        templ
        wgsl
        d
        c
        cpp
        jq
        go
        vim
        sql
        hcl
        rst
        nix
        dot
        ini
        pod
        xml
        lua
        http
        helm
        json
        bash
        diff
        rust
        html
        make
        toml
        yaml
        tmux
        just
        regex
        jinja
        proto
        gosum
        cmake
        promql
        python
        gowork
        gotmpl
        comment
        angular
        mermaid
        graphql
        arduino
        c_sharp
        markdown
        gitignore
        terraform
        gitcommit
        typescript
        javascript
        git_rebase
        dockerfile
        jinja_inline
        requirements
        markdown_inline
      ];
      extras = {
        ai.sidekick.enable = true;
        editor.telescope.enable = true;

        lang = {
          clangd.enable = true;
          cmake.enable = true;
          docker.enable = true;
          dotnet.enable = true;
          git.enable = true;
          go.enable = true;
          helm.enable = true;
          java.enable = true;
          json.enable = true;
          nushell.enable = true;
          python.enable = true;
          rust.enable = true;
          # sql.enable = true;  # FIXME: vim-dadbod hash mismatch bug in lazyvim-nix
          tailwind.enable = true;
          toml.enable = true;
          typescript.enable = true;
          yaml.enable = true;

          angular = {
            enable = true;
            installDependencies = true;
            installRuntimeDependencies = true;
            config = ''
              return {
                "neovim/nvim-lspconfig",
                opts = {
                  servers = {
                    angularls = {
                      mason = false,
                      cmd = {
                        "ngserver",
                        "--stdio",
                        "--tsProbeLocations",
                        vim.fn.getcwd(),
                        "--ngProbeLocations",
                        vim.fn.getcwd(),
                      },
                      on_new_config = function(new_config, root_dir)
                        new_config.cmd = {
                          "ngserver",
                          "--stdio",
                          "--tsProbeLocations",
                          root_dir,
                          "--ngProbeLocations",
                          root_dir,
                        }
                      end,
                    },
                  },
                },
              }
            '';
          };
          ansible = {
            enable = true;
            installDependencies = true;
            installRuntimeDependencies = true;
          };
          markdown = {
            enable = true;
            installDependencies = true;
            installRuntimeDependencies = true;
          };
          nix = {
            enable = true;
            installDependencies = true;
            installRuntimeDependencies = true;
          };
          terraform = {
            enable = true;
            installDependencies = true;
            installRuntimeDependencies = true;
          };
        };
      };
    };

    zsh = {
      enable = true;
      oh-my-zsh.enable = true;
      initContent = ''
        path+=("$HOME/.local/bin")
        path+=("$HOME/.cache/npm/global/bin/")
      '';
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
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

    atuin = {
      enable = true;
      enableZshIntegration = true;
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
        # Core settings
        set -g status on
        set -g status-position top
        set -g status-interval 2
        set -g detach-on-destroy off
        set -g renumber-windows on
        set -g set-clipboard on

        # Terminal colors
        set -ga terminal-overrides ",xterm-256color:Tc"
        set -ga terminal-overrides ",tmux-256color:Tc"

        # Pane borders
        set -g pane-active-border-style 'fg=magenta,bg=default'
        set -g pane-border-style 'fg=brightblack,bg=default'

        # Keybindings
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

        # Statusbar layout
        set -g status-left-length 100
        set -g status-right-length 200
        set -g status-justify centre
        set -g status-style "bg=default"

        # Left: window number + window name (rounded pills)
        set -g status-left '#[fg=#8aadf4,bg=default]#[fg=#1e2030,bg=#8aadf4,bold] 󰆍 #I #[fg=#8aadf4,bg=default] #[fg=#c6a0f6,bg=default]#[fg=#1e2030,bg=#c6a0f6] #W #[fg=#c6a0f6,bg=default]'

        # Center: directory (rounded pill, shown via window status)
        set -g window-status-format ""
        set -g window-status-current-format '#[fg=#363a4f,bg=default]#[fg=#cad3f5,bg=#363a4f] 󰉋 #{b:pane_current_path} #[fg=#363a4f,bg=default]'

        # Right: cpu, ram, date (rounded pill)
        set -g status-right "#[fg=#363a4f,bg=default]#[fg=#f5bde6,bg=#363a4f] 󰻠 #(awk '/^cpu / {printf \"%.0f\", 100-($5*100/($2+$3+$4+$5+$6+$7+$8)); exit}' /proc/stat)%% #[fg=#494d64]│#[fg=#eed49f] 󰍛 #(free | awk '/Mem:/ {printf \"%.0f\", $3/$2*100}')%% #[fg=#494d64]│#[fg=#a6da95] 󰃰 %d/%m %H:%M #[fg=#363a4f,bg=default]"

        # Floax
        set -g @floax-width '80%'
        set -g @floax-height '80%'
        set -g @floax-border-color 'magenta'
        set -g @floax-text-color 'blue'
        set -g @floax-bind 'p'
        set -g @floax-change-path 'true'

        # Sessionx
        set -g @sessionx-bind 'o'
        set -g @sessionx-bind-zo-new-window 'ctrl-y'
        set -g @sessionx-auto-accept 'off'
        set -g @sessionx-zoxide-mode 'on'
        set -g @sessionx-custom-paths '$HOME/dotfiles'
        set -g @sessionx-window-height '85%'
        set -g @sessionx-window-width '75%'
        set -g @sessionx-filter-current 'false'

        # Resurrect / continuum
        set -g @continuum-restore 'on'
        set -g @resurrect-strategy-nvim 'session'
      '';
    };
  };

  services.gpg-agent = {
    enable = false;
    enableZshIntegration = true;
    defaultCacheTtl = 86400; # 24 hours
    maxCacheTtl = 86400;
    pinentry.package = pkgs.pinentry-curses;
  };
}
