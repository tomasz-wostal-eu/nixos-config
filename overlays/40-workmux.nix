# workmux — git worktrees wired to tmux windows, one window per task. Not in
# nixpkgs, so it is built here from the tagged release.
# Upstream's own flake.nix builds the same way; it is not used as an input
# because it does not follow this flake's nixpkgs and would pull a second one.
final: prev: {
  workmux = prev.rustPlatform.buildRustPackage rec {
    pname = "workmux";
    version = "0.1.260";

    src = prev.fetchFromGitHub {
      owner = "raine";
      repo = "workmux";
      tag = "v${version}";
      hash = "sha256-58YT4pad85tyQCyMJWiQtgIoAjH9zZzu7kvg7ZK7208=";
    };

    cargoHash = "sha256-v3+q4EpN4LNI2xRBsCwDrO4pgvIAXI8wGC+uwSXmXvI=";

    nativeBuildInputs = [
      prev.installShellFiles
      prev.git
    ];

    # `workmux completions` writes to a config dir on first run, so give it a
    # writable HOME — same trick upstream's flake uses.
    postInstall = ''
      export HOME=$TMPDIR
      installShellCompletion --cmd workmux \
        --bash <($out/bin/workmux completions bash) \
        --fish <($out/bin/workmux completions fish) \
        --zsh <($out/bin/workmux completions zsh)
    '';

    meta = {
      description = "Git worktrees plus tmux windows for parallel development";
      homepage = "https://github.com/raine/workmux";
      license = prev.lib.licenses.mit;
      mainProgram = "workmux";
    };
  };
}
