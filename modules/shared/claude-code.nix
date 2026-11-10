# Claude Code as the editor's main session: everything it needs that home-manager can
# own without overwriting Claude's mutable state (~/.claude.json, ~/.claude/settings.json).
# - files: the guard hook and its policy, the OTel headers helper.
# - activation: syncs the MCP servers into the user scope (`claude mcp add-json`), merges
#   the hook / OTel env / helper into settings.json, removes herdr's hooks.
{ pkgs, lib }:

let
  mcpServers = import ./mcp-servers.nix { inherit pkgs; };

  # Servers pi has that Claude Code gets another way.
  skip = {
    atlassian = "the claude.ai Atlassian v2 connector provides the same Jira/Confluence tools";
    chrome = "built into Claude Code (`claude --chrome`, /chrome); the pi entry only wraps that flag";
  };

  secretCmd = lib.removePrefix "!";
  isSecret = v: lib.hasPrefix "!" v;
  claude = "${pkgs.claude-code}/bin/claude";
  jq = "${pkgs.jq}/bin/jq";

  # pi-mcp-adapter resolves `!cmd` values at start. Claude Code has no such syntax:
  # stdio secrets go through a bash wrapper (`export K="$(cmd)"; exec server`), HTTP
  # bearer tokens through headersHelper. Nothing secret lands in the Nix store.
  toClaude =
    name: s:
    if s ? command then
      let
        env = s.env or { };
        plain = lib.filterAttrs (_: v: !isSecret v) env;
        secret = lib.filterAttrs (_: isSecret) env;
        exports = lib.concatStrings (
          lib.mapAttrsToList (k: v: "export ${k}=\"$(${secretCmd v})\"\n") secret
        );
      in
      {
        type = "stdio";
      }
      // (
        if secret == { } then
          {
            command = s.command;
            args = s.args or [ ];
          }
        else
          {
            command = "${pkgs.bash}/bin/bash";
            args = [
              "-c"
              (exports + "exec \"$@\"")
              "mcp-${name}"
              s.command
            ] ++ (s.args or [ ]);
          }
      )
      // lib.optionalAttrs (plain != { }) { env = plain; }
    else
      {
        type = "http";
        url = s.url;
      }
      // lib.optionalAttrs (s ? bearerToken) {
        headersHelper = "${jq} -n --arg t \"$(${secretCmd s.bearerToken})\" '{Authorization: (\"Bearer \" + $t)}'";
      }
      // lib.optionalAttrs (s.auth or "" == "oauth" && s ? oauth) {
        oauth = {
          clientId = s.oauth.clientId;
          callbackPort = lib.toInt (lib.last (lib.splitString ":" (lib.removeSuffix "/callback" s.oauth.redirectUri)));
        };
      };

  managed = lib.filterAttrs (n: _: !(skip ? ${n})) mcpServers;

  # OAuth client secret: add-json takes it from MCP_CLIENT_SECRET with --client-secret.
  clientSecretCmd = s: if s ? oauth && s.oauth ? clientSecret then secretCmd s.oauth.clientSecret else "";

  syncCalls = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      n: s:
      "sync_mcp ${lib.escapeShellArg n} ${pkgs.writeText "claude-mcp-${n}.json" (builtins.toJSON (toClaude n s))} ${lib.escapeShellArg (clientSecretCmd s)}"
    ) managed
  );
  managedNames = lib.concatStringsSep " " (map lib.escapeShellArg (builtins.attrNames managed));

  guard = pkgs.writeTextFile {
    name = "claude-guard";
    executable = true;
    text = "#!${pkgs.python3}/bin/python3\n" + builtins.readFile ./claude-code/claude-guard.py;
  };

  # Token for the OTLP endpoint (DW-315): Key Vault -> 0600 file, re-read from Key Vault
  # only when the file is missing or older than the TTL. otelHeadersHelper runs at
  # startup and every 29 minutes, so this must be cheap. A failed refresh falls back to
  # the stale token. Only works with the http/* OTLP protocols (not grpc).
  otelHeaders = pkgs.writeShellApplication {
    name = "claude-otel-headers";
    runtimeInputs = [
      pkgs.azure-cli
      pkgs.jq
      pkgs.findutils
      pkgs.coreutils
    ];
    text = ''
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/claude-otel"
      file="$state/ingest-token"
      ttl_min=$(( ''${CLAUDE_OTEL_TOKEN_TTL:-43200} / 60 ))

      fresh() { [ -s "$file" ] && [ -n "$(find "$file" -mmin "-$ttl_min")" ]; }

      if ! fresh; then
        umask 077
        mkdir -p "$state"
        tmp=$(mktemp "$state/.token.XXXXXX")
        if az keyvault secret show --vault-name "''${CLAUDE_OTEL_VAULT:-kv-driftwardendev}" \
            --name otel-agent-ingest-token --query value -o tsv 2>/dev/null | tr -d '\n' > "$tmp" \
            && [ -s "$tmp" ]; then
          mv "$tmp" "$file"
        else
          rm -f "$tmp"
        fi
      fi

      if [ ! -s "$file" ]; then
        echo "claude-otel-headers: no otel-agent-ingest-token (az login?)" >&2
        exit 1
      fi
      jq -n --rawfile t "$file" '{Authorization: ("Bearer " + $t)}'
    '';
  };

  # What goes into ~/.claude/settings.json. @HOME@ and @HOST@ are filled in by the
  # activation script. The hook has no matcher: it sees every tool, subagents included.
  settingsFragment = pkgs.writeText "claude-settings-fragment.json" (
    builtins.toJSON {
      hooks.PreToolUse = [
        {
          hooks = [
            {
              type = "command";
              command = "@HOME@/.local/bin/claude-guard";
              timeout = 10;
            }
          ];
        }
      ];
      otelHeadersHelper = "@HOME@/.local/bin/claude-otel-headers";
      env = {
        CLAUDE_CODE_ENABLE_TELEMETRY = "1";
        CLAUDE_CODE_ENHANCED_TELEMETRY_BETA = "1"; # traces (beta)
        OTEL_METRICS_EXPORTER = "otlp";
        OTEL_LOGS_EXPORTER = "otlp";
        OTEL_TRACES_EXPORTER = "otlp";
        # otelHeadersHelper only works with the http protocols.
        OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf";
        OTEL_EXPORTER_OTLP_ENDPOINT = "https://otel.tailc90e09.ts.net";
        # session.id is on every datapoint and event by default (the run id).
        OTEL_RESOURCE_ATTRIBUTES = "vendor=anthropic,host.name=@HOST@";
      };
    }
  );
in
{
  files = {
    ".local/bin/claude-guard".source = guard;
    ".local/bin/claude-otel-headers".source = "${otelHeaders}/bin/claude-otel-headers";
    ".config/claude-guard/policy.json".source = ./claude-code/guard-policy.json;
  };

  activation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Never fail the whole switch over Claude Code state.
    claude_state="$HOME/.local/state/claude-mcp-nix"

    # Idempotent: a server is (re)added only when its generated JSON changed or it is
    # missing from ~/.claude.json. Re-adding resets that server's OAuth login.
    sync_mcp() {
      name=$1 json=$2 secret_cmd=$3
      want=$(${pkgs.coreutils}/bin/sha256sum < "$json" | cut -d' ' -f1)
      if [ "$(cat "$claude_state/$name" 2>/dev/null)" = "$want" ] \
          && ${jq} -e --arg n "$name" '.mcpServers[$n]' "$HOME/.claude.json" >/dev/null 2>&1; then
        return 0
      fi
      echo "claude-code: mcp server $name"
      [ -n "''${DRY_RUN:-}" ] && return 0
      ${claude} mcp remove --scope user "$name" >/dev/null 2>&1 || true
      if [ -n "$secret_cmd" ]; then
        MCP_CLIENT_SECRET=$(${pkgs.bash}/bin/bash -c "$secret_cmd") \
          ${claude} mcp add-json --scope user "$name" "$(cat "$json")" --client-secret >/dev/null
      else
        ${claude} mcp add-json --scope user "$name" "$(cat "$json")" >/dev/null
      fi && echo "$want" > "$claude_state/$name" \
        || echo "claude-code: adding mcp server $name failed" >&2
    }

    mkdir -p "$claude_state"
    ${syncCalls}
    # Servers this config managed before and no longer does.
    for stamp in "$claude_state"/*; do
      [ -e "$stamp" ] || continue
      n=$(basename "$stamp")
      case " ${managedNames} " in *" $n "*) continue ;; esac
      [ -n "''${DRY_RUN:-}" ] || { ${claude} mcp remove --scope user "$n" >/dev/null 2>&1; rm -f "$stamp"; }
    done

    # settings.json: add the guard hook, OTel env and helper without touching the other
    # hooks (workmux, impeccable, gstack); drop herdr's. Same herdr cleanup for codex.
    merge_json() {
      target=$1 filter=$2; shift 2
      [ -f "$target" ] || return 0
      tmp=$(mktemp "$target.XXXXXX")
      if ${jq} "$@" "$filter" "$target" > "$tmp" && ${jq} -e . "$tmp" >/dev/null; then
        if cmp -s "$tmp" "$target"; then rm -f "$tmp"; else
          [ -n "''${DRY_RUN:-}" ] && { rm -f "$tmp"; return 0; }
          cp -p "$target" "$target.bak-nix"; chmod "$(${pkgs.coreutils}/bin/stat -c %a "$target")" "$tmp"
          mv "$tmp" "$target"; echo "claude-code: updated $target"
        fi
      else
        rm -f "$tmp"; echo "claude-code: could not merge $target" >&2
      fi
    }
    herdr_free='(.hooks // {}) |= (map_values(map(select(any(.hooks[]?; (.command // "") | contains("herdr-agent-state")) | not))) | with_entries(select(.value | length > 0)))'
    fragment=$(sed -e "s#@HOME@#$HOME#g" -e "s#@HOST@#$(/bin/hostname -s)#g" ${settingsFragment})
    merge_json "$HOME/.claude/settings.json" "
      $herdr_free
      | .hooks.PreToolUse = ([(.hooks.PreToolUse // [])[] | select(any(.hooks[]?; (.command // \"\") | contains(\"claude-guard\")) | not)] + \$f.hooks.PreToolUse)
      | .env = ((.env // {}) + \$f.env)
      | .otelHeadersHelper = \$f.otelHeadersHelper" --argjson f "$fragment"
    merge_json "$HOME/.codex/hooks.json" "$herdr_free"
    for f in "$HOME/.claude/hooks/herdr-agent-state.sh" "$HOME/.codex/herdr-agent-state.sh"; do
      if [ -f "$f" ] && grep -q '^# installed by herdr' "$f"; then
        [ -n "''${DRY_RUN:-}" ] || { rm -f "$f"; echo "claude-code: removed $f"; }
      fi
    done
  '';
}
