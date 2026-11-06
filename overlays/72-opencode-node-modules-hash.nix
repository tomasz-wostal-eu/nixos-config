final: prev: {
  # nixpkgs' node_modules FOD hash for opencode 2.2.5 does not match what
  # bun produces on aarch64-darwin. Drop this once nixpkgs bumps opencode.
  opencode = prev.opencode.overrideAttrs (old:
    if old.version == "2.2.5" then {
      node_modules = old.node_modules.overrideAttrs {
        outputHash = "sha256-dIveiaiPFGSItwLyeMuPDxTE9gpvvnlTCB/+nG24qCc=";
      };
    } else { });
}
