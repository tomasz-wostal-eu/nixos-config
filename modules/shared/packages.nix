{ pkgs }:

with pkgs; [
  # General packages for development and system management
  alacritty
  bash-completion
  bat
  btop
  coreutils
  killall
  openssh
  sqlite
  wget
  zip

  # Encryption and security tools
  age
  gnupg

  # Cloud-related tools and SDKs
  docker
  docker-compose
  bitwarden-desktop
  bitwarden-cli
  lens

  # Media-related packages
  dejavu_fonts
  fd
  font-awesome
  hack-font
  noto-fonts
  noto-fonts-color-emoji
  meslo-lgs-nf
  nerd-fonts.jetbrains-mono

  # Node.js development tools
  nodejs_24

  # Text and terminal utilities
  htop
  jetbrains-mono
  jq
  ripgrep
  tree
  tmux
  unzip
  unimatrix
  xh
  curlie
  httpie
  posting
  age
  sshs
  tshark
  termshark
  
  # Development tools
  curl
  gh
  terraform
  kubectl
  awscli2
  lazygit
  fzf
  direnv
  
  # Programming languages and runtimes
  go
  rustc
  cargo
  openjdk

  # Python packages
  python3
  virtualenv
]
