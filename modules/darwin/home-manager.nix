{
  config,
  pkgs,
  lib,
  home-manager,
  ...
}:

let
  user = "twostal";
  sharedFiles = import ../shared/files.nix { inherit config pkgs; };
  ollama = import ../shared/ollama.nix { inherit pkgs; };
  additionalFiles = import ./files.nix { inherit user config pkgs; };
  shared = import ../shared/home-manager.nix { inherit config pkgs lib; };
in
{
  imports = [
    ./dock
  ];

  # It me
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    taps = [
      {
        name = "nikitabobko/tap";
        trusted = true;
      }
      {
        name = "timvw/tap";
        trusted = true;
      }
    ];
    brews = pkgs.callPackage ./brews.nix { };
    casks = pkgs.callPackage ./casks.nix { };
    onActivation = {
      cleanup = "uninstall";
      # Homebrew 4.6+ requires an explicit flag when `brew bundle --cleanup`
      # would uninstall formulae/casks during non-interactive activation.
      extraFlags = [ "--force" ];
    };

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    # If you have previously added these apps to your Mac App Store profile (but not installed them on this system),
    # you may receive an error message "Redownload Unavailable with This Apple ID".
    # This message is safe to ignore. (https://github.com/dustinlyons/nixos-config/issues/83)
    masApps = {
      # "wireguard" = 1451685025;
    };
  };

  # Enable home-manager
  home-manager = {
    useGlobalPkgs = true;
    users.${user} =
      {
        pkgs,
        config,
        lib,
        lazyvim,
        ...
      }:
      {
        home = {
          enableNixpkgsReleaseCheck = false;
          packages = pkgs.callPackage ./packages.nix { };
          file = lib.mkMerge [
            sharedFiles
            additionalFiles
          ];
          stateVersion = "23.11";
          shellAliases = shared.shellAliases;
          sessionPath = [ "$HOME/.local/bin" ];
        };
        imports = [
          lazyvim.homeManagerModules.default
          ../shared/completions.nix
        ];
        programs = shared.programs;

        # Pull Google Calendar into ~/.local/share/calendars every 15 min so
        # khal has fresh data. darwin only: the OAuth token lives on this host.
        launchd.agents.vdirsyncer = {
          enable = true;
          config = {
            ProgramArguments = [
              "${pkgs.writeShellScript "vdirsyncer-sync" ''
                # launchd hands over a bare PATH; the config's `.fetch` hooks
                # shell out to `cat` for the OAuth client id/secret.
                export PATH="${pkgs.coreutils}/bin:$PATH"
                vd=${pkgs.vdirsyncer}/bin/vdirsyncer
                echo "=== $(date '+%Y-%m-%d %H:%M:%S') vdirsyncer sync ==="
                # -v ERROR: Google returns duplicate hrefs, and the resulting
                # ~100 "Skipping identical href" warnings per run would bloat the log.
                "$vd" -v ERROR sync && exit 0

                # Changing `collections` in the config makes every later sync
                # abort with "Detected change in config file, please run
                # discover" — deliberate on vdirsyncer's part, but as a timed
                # agent it just fails silently every cycle until noticed.
                # Discover is run only on failure, never pre-emptively: doing it
                # each cycle would defeat that guard and silently adopt any new
                # remote calendar. Note the retry DOES accept new collections.
                echo "sync failed -> discover + one retry"
                yes | "$vd" -v ERROR discover >/dev/null 2>&1 || true
                exec "$vd" -v ERROR sync
              ''}"
            ];
            RunAtLoad = true;
            StartInterval = 900;
            StandardOutPath = "/Users/${user}/Library/Logs/vdirsyncer.log";
            StandardErrorPath = "/Users/${user}/Library/Logs/vdirsyncer.log";
            ProcessType = "Background";
            LowPriorityIO = true;
          };
        };

        # Mail sync. Deliberately NOT `gmi sync`: that pushes before it pulls,
        # so a local state that is behind (interrupted pull, fresh clone) reads
        # as mass local deletion and trashes those messages in Gmail — which is
        # exactly what happened on 2026-08-26. Pulling first and pushing only
        # after the pull succeeded makes that ordering impossible.
        launchd.agents.mailsync = {
          enable = true;
          config = {
            ProgramArguments = [
              "${pkgs.writeShellScript "mailsync" ''
                export PATH="${pkgs.coreutils}/bin:$PATH"
                gmi=${pkgs.lieer}/bin/gmi
                echo "=== $(date '+%Y-%m-%d %H:%M:%S') mailsync ==="
                rc=0
                for repo in gmail itomm; do
                  d="$HOME/Mail/$repo"
                  [ -d "$d" ] || continue
                  if "$gmi" pull -C "$d" -q -s; then
                    "$gmi" push -C "$d" -q -s || { echo "push failed: $repo"; rc=1; }
                  else
                    # No push on a failed pull — that is the whole point.
                    echo "pull failed: $repo (skipping push)"
                    rc=1
                  fi
                done
                ${pkgs.notmuch}/bin/notmuch new --quiet || rc=1
                exit $rc
              ''}"
            ];
            RunAtLoad = true;
            StartInterval = 300;
            StandardOutPath = "/Users/${user}/Library/Logs/mailsync.log";
            StandardErrorPath = "/Users/${user}/Library/Logs/mailsync.log";
            ProcessType = "Background";
            LowPriorityIO = true;
          };
        };

        # git-bug keeps issues as git refs, so "syncing with Codeberg" is just a
        # fetch/push of refs/bugs — no Forgejo API involved (bugwarrior has no
        # gitea service at all). Each repo is handled independently so one dead
        # remote cannot abort the rest, then bugwarrior imports into taskwarrior.
        launchd.agents.bugsync = {
          enable = true;
          config = {
            ProgramArguments = [
              "${pkgs.writeShellScript "bugsync" ''
                export PATH="${pkgs.coreutils}/bin:${pkgs.git}/bin:${pkgs.git-bug}/bin:${pkgs.taskwarrior2}/bin:$PATH"
                echo "=== $(date '+%Y-%m-%d %H:%M:%S') bugsync ==="
                rc=0
                # Transport is plain `git`, not `git-bug pull/push`. git-bug uses
                # go-git, which insists on an SSH agent and will not read the key
                # file itself — and launchd agents do not inherit SSH_AUTH_SOCK
                # (`launchctl getenv SSH_AUTH_SOCK` is empty), so git-bug's own
                # transport fails here with "SSH agent requested but
                # SSH_AUTH_SOCK not-specified". git shells out to OpenSSH, which
                # reads ~/.ssh/personal directly and works unattended.
                # Refspecs are deliberately non-forced: a bug edited on two
                # machines gets rejected rather than clobbered — resolve those
                # interactively with `git bug pull`, where the agent is present.
                # --no-verify skips pre-push hooks: several repos lint code there
                # (terraform fmt, bun) and those tools are not on the launchd
                # PATH — but we are pushing bug refs, not code, so running a code
                # linter over them is meaningless anyway.
                refs="refs/bugs/*:refs/bugs/* refs/identities/*:refs/identities/*"
                for r in cd-homelab drift-warden hydro-habitat \
                         iac-hetzner mistwolf-tech mistwolf-video-producer \
                         nexus-hetzner publishing-queue wostal-cloud wostal-eu; do
                  d="$HOME/projects/$r"
                  [ -d "$d/.git" ] || continue
                  ( cd "$d" \
                      && git fetch -q origin $refs 2>/dev/null \
                      && git push -q --no-verify origin $refs 2>/dev/null ) \
                    || { echo "sync failed: $r"; rc=1; }
                done
                ${pkgs.python3Packages.bugwarrior}/bin/bugwarrior pull || rc=1
                # Codeberg's native tracker — the issues actually worked from.
                # bugwarrior cannot see these at all (no forgejo service).
                "$HOME/.local/bin/codeberg-tasks" || rc=1
                exit $rc
              ''}"
            ];
            RunAtLoad = true;
            StartInterval = 300;
            StandardOutPath = "/Users/${user}/Library/Logs/bugsync.log";
            StandardErrorPath = "/Users/${user}/Library/Logs/bugsync.log";
            ProcessType = "Background";
            LowPriorityIO = true;
          };
        };

        # Keep Docker Desktop lean: images live in the registry cache on the
        # NAS, so anything unused for 2 days is safe to drop and re-pull.
        # Named volumes are never touched (they hold project databases), and
        # k3d node containers are excluded so a stopped cluster survives.
        # `until` on containers and images is the creation time — Docker keeps
        # no last-used timestamp — so a container created over 2 days ago is
        # removed once stopped; `docker compose up` recreates it.
        # Relay 127.0.0.1:ollamaRelayPort to the Ollama box on the LAN. launchd
        # accepts each connection and runs nc with it as stdin/stdout. nc is an
        # Apple binary, so Local Network Privacy lets it through (see ollama.nix).
        launchd.agents.ollama-relay = {
          enable = true;
          config = {
            Label = "tech.mistwolf.ollama-relay";
            ProgramArguments = [
              "/usr/bin/nc"
              ollama.ollamaLanHost
              ollama.ollamaLanPort
            ];
            inetdCompatibility.Wait = false;
            Sockets.Listeners = {
              SockNodeName = "127.0.0.1";
              SockServiceName = ollama.ollamaRelayPort;
              SockType = "stream";
            };
          };
        };

        launchd.agents.docker-prune = {
          enable = true;
          config = {
            ProgramArguments = [
              "${pkgs.writeShellScript "docker-prune" ''
                d=${pkgs.docker}/bin/docker
                echo "=== $(date '+%Y-%m-%d %H:%M:%S') docker-prune ==="
                # Never start Docker Desktop just to clean it.
                "$d" info >/dev/null 2>&1 || { echo "docker not running, skipping"; exit 0; }
                rc=0
                "$d" container prune -f --filter until=48h --filter 'label!=app=k3d' || rc=1
                "$d" image prune -af --filter until=48h || rc=1
                "$d" builder prune -af --filter until=48h || rc=1
                # Anonymous volumes only; named ones need `docker volume rm`.
                "$d" volume prune -f || rc=1
                "$d" system df
                exit $rc
              ''}"
            ];
            RunAtLoad = false;
            # Calendar, not StartInterval: launchd runs a missed calendar job
            # after wake, an interval job just waits for the next tick.
            StartCalendarInterval = [ { Hour = 12; Minute = 0; } ];
            StandardOutPath = "/Users/${user}/Library/Logs/docker-prune.log";
            StandardErrorPath = "/Users/${user}/Library/Logs/docker-prune.log";
            ProcessType = "Background";
            LowPriorityIO = true;
          };
        };

        # Marked broken Oct 20, 2022 check later to remove this
        # https://github.com/nix-community/home-manager/issues/3344
        manual.manpages.enable = false;
      };
  };

  # Fully declarative dock using the latest from Nix Store
  local.dock = {
    enable = true;
    username = user;
    entries = [
      { path = "/Applications/Ghostty.app/"; }
      { path = "/Applications/Google Chrome.app/"; }
      { path = "/Applications/Brave Browser.app/"; }
      { path = "/Applications/Firefox.app/"; }
      { path = "/Applications/WhatsApp.app/"; }
      { path = "/Applications/Freelens.app/"; }
      { path = "/Applications/Signal.app/"; }
      { path = "/Applications/Telegram Desktop.app/"; }
      { path = "/Applications/Slack.app/"; }
      { path = "/Applications/Discord.app/"; }
      { path = "/System/Applications/System Settings.app/"; }
      {
        path = "${config.users.users.${user}.home}/Downloads";
        section = "others";
        options = "--sort name --view grid --display stack";
      }
    ];
  };

}
