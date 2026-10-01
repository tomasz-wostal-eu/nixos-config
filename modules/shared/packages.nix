{ pkgs }:

with pkgs;
[
  age
  ansible
  ansible-lint
  argo-rollouts
  argo-workflows
  argocd
  arp-scan
  awscli2
  azure-cli
  bash-completion
  zsh-completions
  bat
  bitwarden-cli
  btop
  cargo
  # checkov # python3.13-av fails OOM on aarch64-darwin; use: pipx install checkov
  cmatrix
  codex
  conftest
  coreutils
  crane
  curl
  curlie
  dejavu_fonts
  direnv
  docker
  docker-compose
  dotnet-sdk
  doctl
  fd
  ffmpeg
  font-awesome
  fzf
  gcalcli # Google Calendar CLI; needs own OAuth client -> `gcalcli init`
  gcc
  gh
  git-bug # issues stored as git objects; rides to Codeberg over plain git refs
  gitea-actions-runner # Homebrew act_runner / gitea-runner
  gitleaks
  gnupg
  go
  hack-font
  hadolint
  hcloud
  helmfile
  # https://herdr.dev — keeps coding agents (Claude Code, Codex, 20+ others)
  # running in the background per project and reattaches from another machine
  # over SSH. In nixpkgs at 0.9.1, so no overlay; upstream is 0.9.3 and a plain
  # `nix flake update` picks that up. Overlaps workmux on agent status: workmux
  # tracks agents inside one tmux session via hooks, herdr owns the runtime that
  # outlives the terminal.
  herdr
  hetzner-kube
  htmlhint
  htop
  httpie
  hugo
  imagemagick
  inter
  jetbrains-mono
  jq
  just
  khal # terminal calendar; reads the vdir synced by vdirsyncer
  k3d
  k6
  kargo
  killall
  kind
  krew
  kubectl
  kubectl-ai
  kubectl-cnpg
  kubectl-convert
  kubectl-df-pv
  kubectl-doctor
  kubectl-evict-pod
  kubectl-example
  kubectl-explore
  kubectl-gadget
  kubectl-graph
  kubectl-images
  kubectl-klock
  kubectl-ktop
  kubectl-neat
  kubectl-node-shell
  kubectl-tree
  kubectl-validate
  kubectl-view-allocations
  kubectl-view-secret
  kubelogin
  kubelogin-oidc
  kubeseal
  kubernetes-helm
  lazydocker
  lazygit
  lazyhetzner
  lima
  lieer # Gmail <-> notmuch sync over the Gmail API (gmi)
  lolcat
  lsof
  mc # midnight-commander
  meslo-lgs-nf
  mongosh
  msmtp # SMTP sender for neomutt; XOAUTH2 against Gmail
  neomutt
  nerd-fonts.jetbrains-mono
  nmap
  notmuch
  nodejs_24
  noto-fonts
  obsidian
  noto-fonts-color-emoji
  ollama
  openjdk
  openssh
  packer
  pass
  # https://github.com/earendil-works/pi — self-extensible coding agent CLI;
  # binary is `pi`, multi-provider (Anthropic/OpenAI/Google/Bedrock/...)
  pi-coding-agent
  pipx
  pnpm
  podman
  podman-compose
  podman-tui
  poetry
  ponysay
  posting
  postgresql
  python3
  qemu
  ripgrep
  ruby
  rustc
  s3cmd
  # sonar-scanner # not in nixpkgs
  sqlfluff
  sqlite
  sshpass
  sshs
  stylelint
  termshark
  terraform
  terraform-compliance
  terraform-inventory
  terraform-landscape
  terraform-ls
  terraform-lsp
  terragrunt
  # taskwarrior 2, not 3, on purpose: bugwarrior talks to it through the `taskw`
  # library, which writes the 2.x .data files. A taskwarrior 3 install reads
  # taskchampion.sqlite3 instead and silently shows "No matches" for everything
  # bugwarrior writes — verified, not theoretical.
  taskwarrior2
  taskwarrior-tui
  python3Packages.bugwarrior # git-bug -> taskwarrior; no gitea/forgejo service exists upstream
  tesseract
  tflint
  tfsec
  tmux
  tree
  tshark
  unimatrix
  unzip
  uv
  vdirsyncer # CalDAV sync into ~/.local/share/calendars; OAuth creds live outside the store
  vhs
  virtualenv
  # vite # nixpkgs "vite" is ViTE (Qt trace explorer, fails to build on darwin), not the JS bundler; use `npm create vite` per project
  w3m # renders text/html for neomutt's mailcap (and handy on its own)
  watch
  wget
  whisper-cpp
  # https://github.com/raine/workmux — one git worktree per task, each in its
  # own tmux window; overlays/40-workmux.nix. Overlaps git-wt: wt manages the
  # worktrees, workmux also drives the tmux side and per-task agent commands.
  workmux
  # wireshark # GUI conflicts with termshark/tshark CLI, use cask on macOS
  xh
  yamllint
  yq
  zip
  mosquitto
  cloudflared
  cloudflare-cli
  sox
  cocoapods
  fjo
  forgejo-cli
  git-wt
  tea
  tea-dash # gh-dash for Codeberg; overlays/30-tea-dash.nix, reads tea's login
  mkdocs
  google-cloud-sdk
]
++ lib.optionals (stdenv.isLinux && stdenv.hostPlatform.isx86_64) [
  android-studio # pulls in pkgsi686Linux, x86-only
  slack
  steam
]
++ lib.optionals stdenv.isLinux [
  # Homebrew equivalents available in nixpkgs for Linux.
  audacity
  brave
  dbeaver-bin
  discord
  figma-linux
  flutter
  freelens-bin
  gemini-cli
  ghostty
  google-chrome
  kdePackages.kdenlive
  microsoft-edge
  mqtt-explorer
  obs-studio
  openvpn
  signal-desktop
  spotify
  tailscale
  teams-for-linux
  telegram-desktop
  vscode
  karere # WhatsApp client; replaces removed wasistlos
  wireshark
  zenmap
  # qmd # not in nixpkgs
]
