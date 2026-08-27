#!/usr/bin/env python3
"""Import Codeberg (Forgejo) issues into taskwarrior.

bugwarrior has no gitea/forgejo service and 2.1.0 is the newest upstream
release, so the native Codeberg tracker is unreachable through it. This walks
~/projects, finds repos whose origin is on codeberg.org, and upserts their open
issues as taskwarrior tasks keyed on the `cbissue` UDA.
"""
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

PROJECTS = os.path.expanduser("~/projects")
TOKEN_FILE = os.path.expanduser("~/.config/codeberg/token")
API = "https://codeberg.org/api/v1"
REMOTE_RE = re.compile(r"codeberg\.org[:/]+([^/]+)/(.+?)(?:\.git)?/?$")


def token():
    try:
        with open(TOKEN_FILE) as fh:
            return fh.read().strip()
    except FileNotFoundError:
        sys.exit(f"brak tokenu: {TOKEN_FILE}")


def api(path, tok):
    req = urllib.request.Request(
        API + path, headers={"Authorization": "token " + tok}
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def discover_repos():
    """owner/name for every ~/projects clone whose origin is on Codeberg."""
    found = {}
    for entry in sorted(os.listdir(PROJECTS)):
        path = os.path.join(PROJECTS, entry)
        if not os.path.isdir(os.path.join(path, ".git")):
            continue
        try:
            url = subprocess.run(
                ["git", "-C", path, "remote", "get-url", "origin"],
                capture_output=True, text=True, timeout=10,
            ).stdout.strip()
        except Exception:
            continue
        m = REMOTE_RE.search(url)
        if m:
            found[f"{m.group(1)}/{m.group(2)}"] = entry
    return found


def task(*args, capture=True):
    cmd = ["task", "rc.confirmation=no", "rc.verbose=nothing",
           "rc.hooks=off", "rc.bulk=0", *args]
    return subprocess.run(cmd, capture_output=capture, text=True)


def existing():
    """cbissue -> task uuid, for tasks this script owns."""
    out = task("rc.json.array=on", "cbissue.any:", "export").stdout or "[]"
    try:
        rows = json.loads(out)
    except json.JSONDecodeError:
        rows = []
    return {r["cbissue"]: r for r in rows if r.get("cbissue")}


def main():
    tok = token()
    repos = discover_repos()
    if not repos:
        sys.exit("nie znalazlem repozytoriow z remote na codeberg.org")

    open_issues = {}
    for slug, local in repos.items():
        owner, name = slug.split("/", 1)
        page = 1
        while True:
            q = urllib.parse.urlencode(
                {"state": "open", "type": "issues", "limit": 50, "page": page}
            )
            try:
                batch = api(f"/repos/{owner}/{name}/issues?{q}", tok)
            except urllib.error.HTTPError as e:
                print(f"  {slug}: HTTP {e.code} (pomijam)")
                break
            except Exception as e:
                print(f"  {slug}: {e} (pomijam)")
                break
            for i in batch:
                if i.get("pull_request"):
                    continue
                key = f"{slug}#{i['number']}"
                open_issues[key] = {
                    "title": i["title"],
                    "url": i["html_url"],
                    "project": local,
                    "labels": [lbl["name"] for lbl in i.get("labels", [])],
                }
            if len(batch) < 50:
                break
            page += 1

    have = existing()
    added = closed = 0

    for key, issue in open_issues.items():
        if key in have:
            continue
        args = [
            "add", issue["title"],
            f"project:{issue['project']}",
            f"cbissue:{key}",
            f"cburl:{issue['url']}",
            "+codeberg",
        ]
        task(*args)
        added += 1

    for key, row in have.items():
        if key not in open_issues and row.get("status") == "pending":
            task(row["uuid"], "done")
            closed += 1

    print(f"repozytoria: {len(repos)}  otwartych issue: {len(open_issues)}  "
          f"dodano: {added}  zamknieto: {closed}")


if __name__ == "__main__":
    main()
