# tea-dash — gh-dash-style TUI for Gitea/Forgejo, i.e. the Codeberg equivalent
# of gh-dash. Not in nixpkgs (12 stars upstream), so it is built here.
# Auth is not configured in this file: tea-dash reads the instance URL and token
# straight out of `tea`'s own config, so `tea login list` is the source of truth.
final: prev: {
  tea-dash = prev.buildGoModule rec {
    pname = "tea-dash";
    version = "0.3.7";

    src = prev.fetchFromGitHub {
      owner = "gbarany";
      repo = "tea-dash";
      tag = "v${version}";
      hash = "sha256-SbbrPWL33PrD02S58c50Gk9xOiu/5pRuccK9vrKViqE=";
    };

    vendorHash = "sha256-pnZbFXZX34xUUUMCR8zSplbBnwdYfrPDRssHQDcBA6o=";

    # internal/git tests shell out to `git init`, which is not in the sandbox
    # PATH by default — without this they fail as "executable file not found".
    nativeCheckInputs = [ prev.git ];

    # Same -X targets the upstream Makefile sets; without them `tea-dash
    # --version` reports "dev". Commit/Date are left alone — a build date would
    # break reproducibility and the store path is the real provenance anyway.
    ldflags = [
      "-s"
      "-w"
      "-X github.com/gbarany/tea-dash/internal/build.Version=v${version}"
    ];

    meta = {
      description = "Terminal dashboard (TUI) for Gitea and Forgejo — PRs, issues, notifications, Actions runs, branches";
      homepage = "https://github.com/gbarany/tea-dash";
      license = prev.lib.licenses.mit;
      mainProgram = "tea-dash";
    };
  };
}
