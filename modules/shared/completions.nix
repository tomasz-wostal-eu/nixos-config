# zsh completions for every package in home.packages that does not ship a
# working one. Nothing to register by hand: add a package and its completion
# is generated on the next build, and regenerated whenever it is bumped.
#
# Per package (one small derivation each, so a bump rebuilds only that one),
# for every bin/<name> without a valid share/zsh/site-functions file:
#   - packages whose binaries embed a `#compdef` template (cobra,
#     clap_complete, ...) are asked for one through the usual subcommands
#     and flags;
#   - Python click apps go through `_<NAME>_COMPLETE=zsh_source`;
#   - cobra kubectl plugins get a `kubectl_complete-<plugin>` wrapper, which
#     kubectl (>= 1.26) runs to complete `kubectl <plugin> ...`;
#   - a shipped file that zsh rejects (no `#compdef` on line 1) is repaired.
# Output is only accepted if it is a zsh completion for that exact name.
#
# Results go to their own fpath entry, ahead of the profile's site-functions,
# so a repaired file shadows the broken original. Carapace still overrides
# the commands it knows.
#
# Commands outside the Nix store (casks, brews) can't be generated at build
# time; `external` below regenerates them into ~/.cache when the binary is
# newer than the cached file.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Generators tried, in order, in packages that embed a `#compdef` template.
  generators = [
    "completion zsh"
    "completions zsh"
    "--generate-shell-completion zsh"
    "generate-shell-completion zsh"
    "shell-completion zsh"
    "completion --shell zsh"
    "completion -s zsh"
    "completions --shell zsh"
    "--completions zsh"
    "--completion zsh"
  ];

  # Not generatable: the zsh files sit in the source tree and the nixpkgs Go
  # build installs only the bash and fish ones.
  manual = pkgs.runCommand "zsh-completions-manual" { } ''
    d=$out/share/zsh/generated-completions
    mkdir -p $d
    cp ${pkgs.kubectx.src}/completion/_kubectx.zsh $d/_kubectx
    cp ${pkgs.kubectx.src}/completion/_kubens.zsh $d/_kubens
  '';

  # Cask/brew CLIs: command -> generator arguments.
  external = {
    tailscale = "completion zsh"; # tailscale-app cask
  };

  forPackage =
    pkg:
    pkgs.runCommand "zsh-completions-${pkg.pname or pkg.name}"
      {
        nativeBuildInputs = [ pkgs.coreutils ];
        preferLocalBuild = true;
        allowSubstitutes = false;
      }
      ''
        bindir=${lib.getBin pkg}/bin
        own=${pkg}/share/zsh/site-functions
        gen=$out/share/zsh/generated-completions
        mkdir -p $gen
        [[ -d $bindir ]] || exit 0

        export HOME=$TMPDIR/home
        mkdir -p $HOME
        cd $TMPDIR

        # Commands the package already completes: every word on a valid
        # `#compdef` line (covers `_xh` declaring `#compdef xh xhs`).
        declare -A covered=()
        for f in $own/_*; do
          [[ -f $f ]] || continue
          read -r first < "$f" || true
          [[ $first == '#compdef '* ]] || continue
          for w in ''${first#'#compdef '}; do covered[''${w%%=*}]=1; done
        done

        # Keep only a zsh completion for $1: drop anything printed before the
        # `#compdef` line and require that line to name the command.
        accept() {
          sed -n '/^#compdef /,$p' "$2" > accepted.zsh
          read -r first < accepted.zsh || return 1
          [[ " ''${first#'#compdef '} " == *" $1 "* ]] || return 1
          cp accepted.zsh "$gen/_$1"
        }

        # Launchers like uvx carry no template of their own but answer the
        # same flags as the sibling (uv) that does.
        template=
        grep -alqF '#compdef' $bindir/* $bindir/.*-wrapped 2> /dev/null && template=1

        for bin in $bindir/*; do
          name=''${bin##*/}
          [[ -x $bin && ! -d $bin && $name != .* ]] || continue
          [[ -n ''${covered[$name]:-} ]] && continue

          # Grep the real program, not a makeWrapper shim.
          real=$bin
          if head -c2 "$bin" | grep -q '^#!'; then
            w=$(grep -aoE '/nix/store/[^" ]+/\.[^" /]+-wrapped' "$bin" | head -1 || true)
            [[ -n $w && -f $w ]] && real=$w
          fi

          # A shipped file zsh rejects.
          if [[ -f $own/_$name ]]; then
            accept "$name" "$own/_$name" && continue
            # Old sourced-style script: `compdef <fn> <name>` at the bottom.
            fn=$(sed -nE "s/^[[:space:]]*compdef[[:space:]]+([^[:space:]]+)[[:space:]]+$name([[:space:]]|$).*/\1/p" "$own/_$name" | head -1)
            if [[ -n $fn ]]; then
              { echo "#compdef $name"; cat "$own/_$name"; echo "$fn \"\$@\""; } > "$gen/_$name"
              continue
            fi
          fi

          if [[ $name == kubectl-* ]] && grep -aqF __complete "$real" \
             && [[ ! -e $bindir/kubectl_complete-''${name#kubectl-} ]]; then
            mkdir -p $out/bin
            printf '#!${pkgs.runtimeShell}\nexec %s __complete "$@"\n' "$bin" \
              > $out/bin/kubectl_complete-''${name#kubectl-}
            chmod +x $out/bin/kubectl_complete-''${name#kubectl-}
          fi

          if [[ -n $template ]]; then
            ${lib.concatMapStrings (g: ''
              if timeout 10 "$bin" ${g} < /dev/null > out.zsh 2> /dev/null \
                 && accept "$name" out.zsh; then continue; fi
            '') generators}
          fi

          if grep -aqE -- '-python3[.0-9]*-click-[0-9]' "$real"; then
            var=_$(echo "$name" | tr 'a-z-' 'A-Z_')_COMPLETE
            if env "$var=zsh_source" timeout 10 "$bin" < /dev/null > out.zsh 2> /dev/null \
               && accept "$name" out.zsh; then continue; fi
          fi
        done
      '';

  generated = pkgs.symlinkJoin {
    name = "zsh-completions-generated";
    paths = [ manual ] ++ map forPackage (lib.filter lib.isDerivation config.home.packages);
  };
in
{
  programs.zsh.initContent = lib.mkOrder 550 ''
    # Generated completions (modules/shared/completions.nix); before compinit.
    fpath=(${generated}/share/zsh/generated-completions $fpath)
    path=(${generated}/bin $path)

    () {
      local dir=''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions bin
      mkdir -p $dir
      fpath=($dir $fpath)
      ${lib.concatStrings (
        lib.mapAttrsToList (c: g: ''
          bin=''${commands[${c}]:-}
          if [[ -n $bin && ( ! -s $dir/_${c} || $bin -nt $dir/_${c} ) ]]; then
            $bin ${g} > $dir/_${c} 2> /dev/null || rm -f $dir/_${c}
          fi
        '') external
      )}
    }
  '';
}
