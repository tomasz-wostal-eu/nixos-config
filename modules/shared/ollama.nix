# Ollama on the LAN box (CO-82). Shared by modules/shared/files.nix (pi's
# models.json, pi-ollama-up) and modules/darwin/home-manager.nix (the relay).
{ pkgs }:

rec {
  ollamaLanHost = "192.168.1.37";
  ollamaLanPort = "11434";
  ollamaRelayPort = "11435";

  # macOS Local Network Privacy attributes every process started under the Nix
  # tmux server to tmux, which has no Local Network permission, so Nix-built
  # binaries get EHOSTUNREACH to LAN addresses. Apple platform binaries are
  # exempt, so on darwin a launchd agent relays 127.0.0.1:ollamaRelayPort to the
  # box with /usr/bin/nc, and everything talks to the relay. Linux goes direct.
  ollamaUrl =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "http://127.0.0.1:${ollamaRelayPort}"
    else
      "http://${ollamaLanHost}:${ollamaLanPort}";
}
