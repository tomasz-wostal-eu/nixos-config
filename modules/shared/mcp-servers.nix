{ pkgs }:

# The MCP servers pi (pi-mcp-adapter) loads from ~/.config/mcp/mcp.json. One source of
# truth: claude-code.nix derives the Claude Code user-scope servers from the same data.
# MCP servers for pi (pi-mcp-adapter reads this shared file; its own settings
# and tool toggles go to ~/.pi/agent/mcp-adapter.json, so a read-only symlink
# is fine). Secrets stay in 0600 files: a leading `!` in env runs the command
# through bash when the server starts.
# - google-workspace: one server for both accounts (each tool takes
#   user_google_email; the first call per account opens Google's consent page,
#   callback on localhost:8000). Reuses lieer's Desktop OAuth client, whose GCP
#   project also needs the Drive API enabled. Gmail is read-only, Drive can
#   write. Not in nixpkgs, so uvx with a pinned version.
# - grafana: token of the claude-mcp service account (Admin, so read-write),
#   read from drift-warden's Key Vault at start (needs `az login`; ~2 s of
#   the adapter's 10 s command budget). Rotation: drift-warden
#   docs/observability.md. A copy sits in pass (grafana/mcp-sa-token); after
#   a rotation refresh it from Key Vault.
# - slack: Slack's hosted server, workspace mistwolf. It has no dynamic client
#   registration, so it signs in through our own app "pi MCP" (A0CBEJLQ4BZ,
#   created from a manifest with is_mcp_enabled and read-only user scopes).
#   The redirect URL is fixed in the app; the secret stays in a 0600 file,
#   with copies in pass (slack/mcp-client-secret) and in Key Vault
#   kv-driftwardendev (slack-mcp-client-secret).
# - chrome: Claude in Chrome, the same browser tools Claude Code gets with
#   --chrome. It drives the real Chrome through the extension and the native
#   host claude installs, so the sessions you are signed in to are in reach.
#   --claude-in-chrome-mcp is an undocumented claude flag and may change.
# - kubernetes: containers/kubernetes-mcp-server, read-write (its default),
#   on ~/.kube/config with every context reachable (tools take `context`).
#   Not in nixpkgs (mcp-k8s-go is a different, smaller server), so npx with
#   a pinned version.
# - argocd: argoproj-labs/mcp-for-argocd against cd.mistwolf.tech,
#   read-write (MCP_READ_ONLY unset). The argocd CLI's own token is an SSO
#   session (Authentik, 1 h), so this uses an API token of a local account
#   in a 0600 file, with a copy in pass (argocd/mcp-api-token).
# - home-assistant: HA's own MCP Server integration (Assist intents, live
#   context, exposed scripts) at 192.168.1.208. Only entities exposed to
#   Assist are reachable, and it can't edit configuration. Plain http on the
#   LAN, so the long-lived token travels in clear there. The token sits in a
#   0600 file, with copies in pass (home-assistant/mcp-token) and in Key
#   Vault kv-driftwardendev (home-assistant-mcp-token).
# - ha-mcp: homeassistant-ai/ha-mcp (unofficial) on the same HA and token,
#   for configuration: automations, scripts, helpers, history, logs. Not in
#   nixpkgs, so uvx with a pinned version.
# - n8n: czlonkowski/n8n-mcp against n8n.mistwolf.tech (the n8n-postiz-stack
#   in ~/projects/n8n): node docs and schemas, plus creating, editing and
#   validating workflows through the n8n API. Not in nixpkgs, so npx with a
#   pinned version. The API key sits in a 0600 file, with a copy in Key
#   Vault kv-driftwardendev (n8n-api-key).
# - postiz: Postiz's own MCP server at postiz.mistwolf.tech (channels,
#   creating and scheduling posts), streamable HTTP with the public API key
#   as a bearer token. The key sits in a 0600 file; the source is Key Vault
#   kv-driftwardendev (postiz-public-api-key).
{
  atlassian = {
    url = "https://mcp.atlassian.com/v1/mcp";
    auth = "oauth";
    approveTools = "destructive";
    # Its tools hand results to MCP App pages, which pi-mcp-adapter opens
    # in the browser on every call. false: results come back inline only.
    openUi = false;
  };
  google-workspace = {
    command = "${pkgs.uv}/bin/uvx";
    args = [
      "workspace-mcp==2.2.0"
      "--permissions"
      "gmail:readonly"
      "drive:full"
    ];
    env = {
      GOOGLE_CLIENT_SECRET_PATH = "\${HOME}/.config/lieer/client_secret.json";
      WORKSPACE_MCP_CREDENTIALS_DIR = "\${HOME}/.local/share/workspace-mcp";
    };
    approveTools = "destructive";
  };
  grafana = {
    command = "${pkgs.mcp-grafana}/bin/mcp-grafana";
    env = {
      GRAFANA_URL = "https://grafana.mistwolf.tech";
      GRAFANA_SERVICE_ACCOUNT_TOKEN = "!${pkgs.azure-cli}/bin/az keyvault secret show --vault-name kv-driftwardendev --name grafana-mcp-sa-token --query value -o tsv";
    };
    approveTools = "destructive";
  };
  slack = {
    url = "https://mcp.slack.com/mcp";
    auth = "oauth";
    oauth = {
      clientId = "10097094100597.12388632820407";
      clientSecret = "!cat \"$HOME/.config/slack/mcp-client-secret\"";
      redirectUri = "http://localhost:3118/callback";
    };
    approveTools = "destructive";
  };
  chrome = {
    command = "${pkgs.claude-code}/bin/claude";
    args = [ "--claude-in-chrome-mcp" ];
    approveTools = "destructive";
  };
  kubernetes = {
    command = "${pkgs.nodejs_24}/bin/npx";
    args = [ "-y" "kubernetes-mcp-server@0.0.69" ];
    approveTools = "destructive";
  };
  argocd = {
    command = "${pkgs.nodejs_24}/bin/npx";
    args = [ "-y" "argocd-mcp@0.9.0" "stdio" ];
    env = {
      ARGOCD_BASE_URL = "https://cd.mistwolf.tech";
      ARGOCD_API_TOKEN = "!cat \"$HOME/.config/argocd/mcp-api-token\"";
    };
    approveTools = "destructive";
  };
  home-assistant = {
    url = "http://192.168.1.208:8123/api/mcp";
    # Without auth = "bearer" the adapter ignores bearerToken and tries OAuth.
    auth = "bearer";
    bearerToken = "!cat \"$HOME/.config/home-assistant/token\"";
    approveTools = "destructive";
  };
  ha-mcp = {
    command = "${pkgs.uv}/bin/uvx";
    args = [ "ha-mcp==9.1.0" ];
    env = {
      HOMEASSISTANT_URL = "http://192.168.1.208:8123";
      HOMEASSISTANT_TOKEN = "!cat \"$HOME/.config/home-assistant/token\"";
    };
    approveTools = "destructive";
  };
  n8n = {
    command = "${pkgs.nodejs_24}/bin/npx";
    args = [ "-y" "n8n-mcp@2.99.1" ];
    env = {
      MCP_MODE = "stdio";
      LOG_LEVEL = "error";
      DISABLE_CONSOLE_OUTPUT = "true";
      N8N_MCP_TELEMETRY_DISABLED = "true";
      N8N_API_URL = "https://n8n.mistwolf.tech";
      N8N_API_KEY = "!cat \"$HOME/.config/n8n/api-key\"";
    };
    approveTools = "destructive";
  };
  postiz = {
    url = "https://postiz.mistwolf.tech/api/mcp";
    auth = "bearer";
    bearerToken = "!cat \"$HOME/.config/postiz/api-key\"";
    approveTools = "destructive";
  };
}
