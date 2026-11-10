# claude-guard: PreToolUse hook for Claude Code (main session and subagents).
# Reads the hook JSON on stdin and answers with a permissionDecision on stdout:
#   deny  - secret files, force-push / history rewrites on main, bare Key Vault secrets
#   ask   - destructive MCP tools that are not on the allow list
#   (no output) - everything else; Claude Code's own permission rules decide.
# Every deny/ask is appended to $CLAUDE_GUARD_LOG_DIR/blocks.jsonl (default
# ~/.local/state/claude-guard). Policy: $CLAUDE_GUARD_POLICY (default
# ~/.config/claude-guard/policy.json). An internal error never blocks a tool call.
import fnmatch
import json
import os
import re
import shlex
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
LOG_DIR = os.environ.get("CLAUDE_GUARD_LOG_DIR") or os.path.join(HOME, ".local/state/claude-guard")
POLICY = os.environ.get("CLAUDE_GUARD_POLICY") or os.path.join(HOME, ".config/claude-guard/policy.json")
MAIN_BRANCHES = {"main", "master"}

# --- secret files -----------------------------------------------------------

EXAMPLE_SUFFIXES = ("example", "sample", "template", "dist", "defaults")
SSH_OK = ("known_hosts", "config", "authorized_keys")

# A file token in a shell command: `.env`, `.env.local`, `prod.env`, `*.env`.
# `process.env` (JS) is not a file; `.env.example` and friends are templates.
ENV_TOKEN = re.compile(
    r"""(?:^|(?<=[\s'"=:/(<>,]))(?!process\.env)((?:[\w*?-]*\.env)(?:\.[\w.*?-]+|\*)?)(?=$|[\s'"):;|&<>,\\])"""
)
AWS_TOKEN = re.compile(r"(?<![\w.-])\.aws(?![\w-])")
SSH_TOKEN = re.compile(r"(?<![\w.-])\.ssh(?:/([^\s'\"]*))?")


def env_file(name):
    base = os.path.basename(name.rstrip("/"))
    if not (base == ".env" or base.startswith(".env.") or base.endswith(".env") or base == ".env*"):
        return False
    return not base.lower().endswith(EXAMPLE_SUFFIXES)


def ssh_private(rest):
    if rest is None or rest == "":
        return False
    base = os.path.basename(rest.rstrip("/"))
    return not (base.endswith(".pub") or base.startswith(SSH_OK))


def secret_path(p):
    """Rule name when the path string names a secret file, else None."""
    p = os.path.expanduser(p)
    if re.search(r"(^|/)\.aws(/|$)", p):
        return "secret-file:aws"
    m = re.search(r"(^|/)\.ssh/(.*)$", p)
    if m and ssh_private(m.group(2)):
        return "secret-file:ssh-key"
    if env_file(p):
        return "secret-file:env"
    return None


def secret_in_command(cmd):
    for m in ENV_TOKEN.finditer(cmd):
        if env_file(m.group(1)):
            return "secret-file:env"
    if AWS_TOKEN.search(cmd):
        return "secret-file:aws"
    for m in SSH_TOKEN.finditer(cmd):
        if ssh_private(m.group(1)):
            return "secret-file:ssh-key"
    return None


# --- Key Vault secrets ------------------------------------------------------

KV_SHOW = re.compile(r"(?<![\w-])az\s+keyvault\s+secret\s+show\b")
STMT_END = re.compile(r";|&&|\|\||\n")


def keyvault_rule(cmd):
    """Deny `az keyvault secret show` unless its output is captured, never printed:
    NAME=$(az ...) (and NAME is not echoed), `az ... > file`, or `az ... | pbcopy`."""
    shows = list(KV_SHOW.finditer(cmd))
    if not shows:
        return None
    if re.search(r"(^|[;&\s])set\s+-\w*x|\bbash\s+-\w*x", cmd):
        return "keyvault-secret-print"
    for m in shows:
        before = cmd[: m.start()]
        stmt = cmd[m.start():]
        end = STMT_END.search(stmt)
        stmt = stmt[: end.start()] if end else stmt
        assign = re.search(r"\b([A-Za-z_]\w*)=[\"']?\$\(\s*(?:[\w./-]*/)?$", before)
        if assign:
            name = assign.group(1)
            if re.search(r"\b(echo|printf|cat|print)\b[^;&|\n]*\$\{?%s\b" % name, cmd[m.end():]):
                return "keyvault-secret-print"
            continue
        redirect = re.search(r"(?<![\d&])>>?\s*(?!&|/dev/(stdout|stderr|tty))[^\s|&;<>]+", stmt)
        if redirect and not re.search(r"\|\s*tee\b", stmt):
            continue
        if re.search(r"\|\s*pbcopy\b", stmt):
            continue
        return "keyvault-secret-print"
    return None


# --- git on main ------------------------------------------------------------

SEPARATORS = {";", "&&", "||", "|", "&", "|&", "(", ")"}


def segments(cmd):
    try:
        lex = shlex.shlex(cmd.replace("\n", " ; "), posix=True, punctuation_chars=True)
        lex.commenters = ""
        lex.whitespace_split = True
        toks = list(lex)
    except ValueError:
        toks = re.split(r"\s+", cmd.replace("\n", " ; "))
    seg, out = [], []
    for t in toks:
        if t in SEPARATORS or set(t) <= set(";&|()"):
            if seg:
                out.append(seg)
            seg = []
        else:
            seg.append(t)
    if seg:
        out.append(seg)
    return out


def git_calls(cmd):
    """Yield (dir, subcommand, args) for each `git` invocation in the command."""
    for seg in segments(cmd):
        for i, t in enumerate(seg):
            if os.path.basename(t) != "git":
                continue
            j, cdir = i + 1, None
            while j < len(seg) and seg[j].startswith("-"):
                if seg[j] == "-C" and j + 1 < len(seg):
                    cdir = seg[j + 1]
                    j += 2
                elif seg[j] in ("-c", "--git-dir", "--work-tree", "--namespace") and j + 1 < len(seg):
                    j += 2
                else:
                    j += 1
            if j < len(seg):
                yield cdir, seg[j], seg[j + 1:]
            break


_branch_cache = {}


def current_branch(cwd, cdir):
    d = os.path.join(cwd, os.path.expanduser(cdir)) if cdir else cwd
    if d not in _branch_cache:
        try:
            _branch_cache[d] = subprocess.run(
                ["git", "-C", d, "symbolic-ref", "--short", "-q", "HEAD"],
                capture_output=True, text=True, timeout=5,
            ).stdout.strip()
        except Exception:
            _branch_cache[d] = ""
    return _branch_cache[d]


def push_rule(args, cwd, cdir):
    force = False
    delete = False
    pos = []
    for a in args:
        if a in ("-f", "--force", "--force-if-includes") or a.startswith("--force-with-lease"):
            force = True
        elif a in ("-d", "--delete"):
            delete = True
        elif re.fullmatch(r"-[a-zA-Z]+", a) and "f" in a:
            force = True
        elif a in ("--all", "--mirror"):
            pos.append(a)
        elif not a.startswith("-"):
            pos.append(a)
    refspecs = pos[1:]
    if any(r.startswith("+") for r in refspecs):
        force = True
    if not (force or delete):
        return None
    branch = current_branch(cwd, cdir)
    targets = []
    for r in refspecs:
        dst = r.lstrip("+").split(":")[-1]
        dst = dst.replace("refs/heads/", "")
        targets.append(branch if dst == "HEAD" else dst)
    if not refspecs:
        targets = [branch] + (["main"] if "--all" in pos or "--mirror" in pos else [])
    if any(t in MAIN_BRANCHES for t in targets):
        return "git-push-delete-main" if delete and not force else "git-force-push-main"
    return None


REV_ARG = re.compile(r"^(HEAD|@|ORIG_HEAD|origin/|upstream/)|^[0-9a-f]{7,40}$|[~^]\d*$")


def rewrite_rule(sub, args, cwd, cdir):
    on_main = current_branch(cwd, cdir) in MAIN_BRANCHES
    if sub in ("filter-branch", "filter-repo"):
        return "git-history-rewrite-main"
    if sub == "update-ref" and any(re.search(r"(^|/)(main|master)$", a) for a in args):
        return "git-history-rewrite-main"
    if sub == "branch" and any(a in ("-f", "--force", "-M", "-D", "-d") or re.fullmatch(r"-[a-zA-Z]*[fMD][a-zA-Z]*", a) for a in args) \
            and any(a in MAIN_BRANCHES for a in args):
        return "git-history-rewrite-main"
    if not on_main:
        return None
    if sub == "rebase":
        return "git-history-rewrite-main"
    if sub == "commit" and "--amend" in args:
        return "git-history-rewrite-main"
    if sub == "reset" and any(
        a in ("--hard", "--soft", "--keep", "--merge") or (not a.startswith("-") and REV_ARG.search(a))
        for a in args
    ):
        return "git-history-rewrite-main"
    return None


def git_rule(cmd, cwd):
    for cdir, sub, args in git_calls(cmd):
        rule = push_rule(args, cwd, cdir) if sub == "push" else rewrite_rule(sub, args, cwd, cdir)
        if rule:
            return rule
    return None


# --- MCP gates --------------------------------------------------------------

def mcp_rule(tool, policy):
    m = re.match(r"mcp__(.+?)__(.+)$", tool)
    if not m:
        return None
    server, name = m.groups()
    if any(fnmatch.fnmatch(tool, pat) for pat in policy.get("mcp_allow", [])):
        return None
    for gate in policy.get("mcp_gates", []):
        if re.search(gate["server"], server, re.I) and re.search(gate["tool"], name, re.I):
            return "mcp-gate"
    return None


# --- decision ---------------------------------------------------------------

REASONS = {
    "secret-file:env": "Blocked: .env / *.env files hold secrets and must not enter the transcript.",
    "secret-file:aws": "Blocked: ~/.aws holds credentials.",
    "secret-file:ssh-key": "Blocked: private SSH keys must not be read (public keys, known_hosts and config are fine).",
    "keyvault-secret-print": "Blocked: `az keyvault secret show` output would land in the transcript. "
    "Capture it: VAR=$(az keyvault secret show ... --query value -o tsv), or redirect it with > file, "
    "and do not echo it.",
    "git-force-push-main": "Blocked: force-push to main. Push a branch and open a PR.",
    "git-push-delete-main": "Blocked: deleting main on the remote.",
    "git-history-rewrite-main": "Blocked: history rewrite on main. Work on a feature branch.",
    "mcp-gate": "Destructive MCP tool, not on the allow list (mcp_allow in guard-policy.json).",
}

PATH_FIELDS = ("file_path", "path", "notebook_path", "glob")


def decide(data, policy):
    tool = data.get("tool_name", "")
    ti = data.get("tool_input") or {}
    cwd = data.get("cwd") or os.getcwd()
    if tool == "Bash":
        cmd = ti.get("command", "")
        for rule in (secret_in_command(cmd), keyvault_rule(cmd), git_rule(cmd, cwd)):
            if rule:
                return "deny", rule, cmd
        return None
    if tool.startswith("mcp__"):
        rule = mcp_rule(tool, policy)
        return ("ask", rule, json.dumps(ti)[:200]) if rule else None
    paths = [ti[f] for f in PATH_FIELDS if isinstance(ti.get(f), str)]
    if tool == "Glob" and isinstance(ti.get("pattern"), str):
        paths.append(ti["pattern"])
    for p in paths:
        rule = secret_path(p)
        if rule:
            return "deny", rule, p
    return None


def log(data, decision, rule, detail):
    try:
        os.makedirs(LOG_DIR, mode=0o700, exist_ok=True)
        rec = {
            "ts": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
            "decision": decision,
            "rule": rule,
            "tool": data.get("tool_name"),
            "session_id": data.get("session_id"),
            "agent_id": data.get("agent_id"),
            "agent_type": data.get("agent_type"),
            "cwd": data.get("cwd"),
            "detail": detail[:300],
        }
        with open(os.path.join(LOG_DIR, "blocks.jsonl"), "a") as f:
            f.write(json.dumps(rec) + "\n")
    except OSError:
        pass


def main():
    try:
        data = json.load(sys.stdin)
        try:
            with open(POLICY) as f:
                policy = json.load(f)
        except (OSError, ValueError):
            policy = {}
        result = decide(data, policy)
    except Exception as e:  # never block a tool call on a guard bug
        print("claude-guard: internal error: %s" % e, file=sys.stderr)
        return 0
    if not result:
        return 0
    decision, rule, detail = result
    log(data, decision, rule, detail)
    reason = REASONS[rule]
    if rule == "mcp-gate":
        reason = "%s: %s (%s)" % (data["tool_name"], reason, next(
            (g["why"] for g in policy.get("mcp_gates", []) if re.search(g["server"], data["tool_name"].split("__")[1], re.I)), ""))
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": decision,
        "permissionDecisionReason": "claude-guard [%s] %s" % (rule, reason),
    }}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
