{ pkgs, config, ... }:

let
  # Catppuccin Macchiato. Single source of truth for the configs below that
  # take 24-bit colour (neomutt has +truecolor, khal's palette takes #RRGGBB
  # in the high-colour slots). Terminal/btop/bat themes above predate this and
  # still carry their own copies.
  cat = {
    rosewater = "#f4dbd6";
    flamingo = "#f0c6c6";
    pink = "#f5bde6";
    mauve = "#c6a0f6";
    red = "#ed8796";
    maroon = "#ee99a0";
    peach = "#f5a97f";
    yellow = "#eed49f";
    green = "#a6da95";
    teal = "#8bd5ca";
    sky = "#91d7e3";
    sapphire = "#7dc4e4";
    blue = "#8aadf4";
    lavender = "#b7bdf8";
    text = "#cad3f5";
    subtext1 = "#b8c0e0";
    subtext0 = "#a5adcb";
    overlay2 = "#939ab7";
    overlay1 = "#8087a2";
    overlay0 = "#6e738d";
    surface2 = "#5b6078";
    surface1 = "#494d64";
    surface0 = "#363a4f";
    base = "#24273a";
    mantle = "#1e2030";
    crust = "#181926";
  };

  # Hand a file to the desktop's default handler. `open` is not a store path
  # because it is part of macOS itself.
  htmlOpener = if pkgs.stdenv.hostPlatform.isDarwin then "/usr/bin/open" else "${pkgs.xdg-utils}/bin/xdg-open";

  homeDir = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/twostal" else "/home/twostal";

  # Auto-tagging for notmuch, derived from what is actually in the mailbox:
  # 41k messages from 1045 sender domains, where the top 30 domains carry over
  # half the volume. Rules therefore key on domains, not on hand-listed
  # addresses. `from:adobe.com` also matches `mail.adobe.com` — notmuch matches
  # address tokens, so one entry covers a sender's marketing subdomains too.
  #
  # These tags DO reach Gmail: lieer pushes every tag that is not in its
  # ignore_tags as a label, and `/` nests them there. That is deliberate here,
  # but it means a wrong rule is visible on the account and on the phone, not
  # just locally.
  #
  # Only additive: nothing here touches inbox/unread/flagged, because removing
  # those would archive or mark mail in Gmail on the next push.
  notmuchTagRules = {
    "dev/github" = "from:github.com or from:email.github.com";
    "dev/codeberg" = "from:codeberg.org";
    "dev/security" = ''from:snyk.io or from:letsencrypt.org or from:security@ or subject:dependabot or subject:"security alert" or subject:CVE'';
    "dev/cloud" = "from:hetzner.com or from:hetzner.de or from:ovh.pl or from:ovhcloud.com or from:digitalocean.com or from:nabucasa.com or from:ngrok.com or from:cloudflare.com or from:linode.com or from:scaleway.com";
    "dev/vendor" = "from:atlassian.com or from:hashicorp.com or from:puppet.com or from:postman.com or from:smartbearmail.com or from:anthropic.com or from:docker.com or from:jetbrains.com or from:gitlab.com or from:openai.com or from:sourcegraph.com or from:grafana.com or from:elastic.co or from:mongodb.com or from:redis.com or from:microsoft.com or from:slack.com or from:influxdata.com or from:ollama.com or from:mozilla.org";
    "alerts/infra" = "from:synologynotification.com or from:io.adafruit.com or from:uptimerobot.com or from:statuspage.io or from:pagerduty.com or from:betteruptime.com";
    "jobs/recruiter" = "from:inhire.io or from:elitehunter.pl or from:eteaminc.com or from:jobleads.com or from:inmail-hit-reply@linkedin.com or from:hays.pl or from:antal.pl or from:devire.pl or from:hrk.pl";
    "jobs/alerts" = "from:nofluffjobs.com or from:jobalerts-noreply@linkedin.com or from:jobs-listings@linkedin.com or from:justjoin.it or from:pracuj.pl or from:bulldogjob.pl or from:theprotocol.it";
    "finance/banking" = "from:mbank.pl or from:pekao.com.pl or from:velobank.pl or from:gnb.pl or from:revolut.com or from:ing.pl or from:santander.pl or from:millenniumbank.pl or from:alior.pl or from:bnpparibas.pl";
    "finance/payments" = "from:przelewy24.pl or from:payu.com or from:stripe.com or from:mastercard.pl or from:paypal.com or from:payments-noreply@google.com or from:tpay.com or from:blik.com";
    # Subject-keyed, so it also catches invoices from the long tail of senders
    # that no domain rule will ever cover.
    "finance/invoices" = ''subject:faktura or subject:invoice or subject:rachunek or subject:"payment receipt" or subject:paragon'';
    "shop/orders" = "from:allegro.pl or from:allegromail.pl or from:ceneo.pl or from:mediaexpert.pl or from:decathlon.pl or from:temuemail.com or from:botland.com.pl or from:kamami.com or from:kamami.pl or from:rebel.pl or from:ikea.pl or from:deichmann.pl or from:amazon.com or from:olx.pl or from:morele.net or from:x-kom.pl or from:empik.com";
    "shop/promo" = "from:reeffactory.com or from:roslinyakwariowe.pl or from:yerbamatestore.pl or from:astrohunters.pl or from:trzmiel.com.pl or from:invital.pl or from:ostredzieje.pl or from:sony-europe.com or from:banggood.com or from:carrefour.pl or from:harley-davidson.com or from:iqos.com or from:easeus.com or from:ralphlauren.eu or from:kampanie. or from:deals.";
    "shop/delivery" = "from:inpost.pl or from:paczkomaty.pl or from:dhl.pl or from:dpd.com.pl or from:ups.com or from:fedex.com or from:poczta-polska.pl or from:gls-poland.com";
    "travel" = "from:booking.com or from:flixbus.com or from:airbnb.com or from:ryanair.com or from:wizzair.com or from:lot.com or from:intercity.pl or from:koleo.pl or from:trivago.com";
    "events" = "from:bandsintown.com or from:ticketmaster.de or from:ticketmaster.pl or from:multikino.pl or from:knockoutprod.net or from:eventim.pl or from:goingapp.pl or from:eventbrite.com";
    "food" = "from:pyszne.pl or from:glovoapp.com or from:bolt.eu or from:ubereats.com or from:wolt.com or from:mcdonalds.pl or from:zabka.pl";
    "services" = "from:booksy.com or from:cityfit.info.pl or from:medicover.pl or from:luxmed.pl or from:enel-med.pl";
    "telecom" = "from:t-mobile.pl or from:orange.pl or from:play.pl or from:plus.pl or from:vectra.pl or from:upc.pl";
    "news" = "from:oko.press or from:wyborcza.pl or from:sekurak.pl or from:programistamag.pl or from:patronite.pl or from:patronite.email or from:bookbeat.com or from:fourhourseo.com or from:mailliberland.org or from:substack.com or from:medium.com or from:tvn24.pl or from:onet.pl or from:interia.pl";
    # LinkedIn's job addresses are excluded so an offer lands in jobs/*, not here.
    "social" = "from:discord.com or from:redditmail.com or from:deviantart.com or from:spotify.com or from:youtube.com or from:roblox.com or from:steampowered.com or from:amateri.com or from:facebookmail.com or from:instagram.com or from:x.com or from:mastodon.social or (from:linkedin.com and not from:jobalerts-noreply@linkedin.com and not from:jobs-listings@linkedin.com and not from:inmail-hit-reply@linkedin.com)";
    "security/account" = ''from:accounts.google.com or from:accountprotection.microsoft.com or from:bitwarden.com or from:authy.com or from:1password.com or subject:"verification code" or subject:"kod weryfikacyjny" or subject:"two-factor" or subject:logowanie'';
    "calendar" = "from:calendar-notification@google.com or from:calendar-noreply@google.com or attachment:invite.ics";
    "family" = "from:families-noreply@google.com or from:life360.com or from:gokidz.pl or from:librus.pl or from:vulcan.edu.pl";
    "creative" = "from:adobe.com or from:creativemarket.com or from:visme.co or from:invideo.io or from:canva.com or from:figma.com";
    "google/services" = "from:googleplay-noreply@google.com or from:workspace-noreply@google.com or from:googleone-updates-noreply@google.com or from:noreply-maps-timeline@google.com or from:noreply-local-guides@google.com or from:actions-noreply@google.com or from:googleassistant-noreply@google.com or from:CloudPlatform-noreply@google.com";
    "newsletter" = "from:newsletter or from:news. or from:mailchimp or from:sendgrid.net or from:mailerlite.com or from:getresponse.com or subject:newsletter";
    # Cuts the mailbox in half: `not tag:automated` is what is left when every
    # machine-sent message is out of the way.
    "automated" = "from:noreply or from:no-reply or from:donotreply or from:do-not-reply or from:notifications or from:mailer-daemon";
  };

  # `and not tag:X` is what makes a run idempotent and cheap: a message is only
  # touched the first time a rule matches it, so the hook can run on every
  # `notmuch new` and still costs nothing once the backlog is tagged. It also
  # means a tag removed by hand does come back — remove the rule to make it
  # stick.
  notmuchTagBatch = pkgs.lib.concatStrings (
    pkgs.lib.mapAttrsToList (tag: query: "+${tag} -- (${query}) and not tag:${tag}\n") notmuchTagRules
  );

  # Ollama on the LAN box: pi's provider (models.json) and the pi-ollama-up probe
  # both come from here. The reviewer model is the one pr-review needs to be there.
  ollamaUrl = "http://192.168.1.37:11434";
  ollamaReviewModel = "qwen3-coder:30b-32k";

  # Argo Workflows UIs that CI statuses link to, and how pr-ci reaches each one:
  # the kubeconfig context of the cluster it runs in (kube mode), and the owner-only
  # argo-server in client auth mode on the tailnet (server mode, drift-warden DW-162)
  # with the <namespace>/<service account> pr-ci mints its token for.
  argoHosts = {
    "workflows.mistwolf.tech" = {
      kubeContext = "mistwolf-dev";
      cliServer = "workflows-cli.tailc90e09.ts.net";
      tokenAccount = "argo-workflows/argo-cli";
    };
  };

  # One argoHosts field as a bash associative array keyed by host, for pr-ci.
  argoHostsBash =
    name: field:
    "declare -A ${name}=(\n"
    + pkgs.lib.concatStrings (
      pkgs.lib.mapAttrsToList (
        host: a: "  [${pkgs.lib.escapeShellArg host}]=${pkgs.lib.escapeShellArg (a.${field} or "")}\n"
      ) argoHosts
    )
    + ")\n";

  # jq for pr-ci and pr-deploy: `table` pads an array of string rows into columns
  # (no column(1) needed), `norm` turns any git URL form into host/owner/repo.
  jqHelpers = ''
    def table: (.[0] | length) as $n
      | [range(0; $n) as $i | map(.[$i] | length) | max] as $w
      | .[] | [range(0; $n) as $i | .[$i] + (" " * ($w[$i] - (.[$i] | length)))]
      | join("  ") | sub(" +$"; "");
    def norm: ascii_downcase | sub("^[a-z0-9+.-]+://"; "") | sub("^[^@/]+@"; "")
      | sub(":[0-9]+/"; "/") | sub(":"; "/") | sub("\\.git/?$"; "") | sub("/+$"; "");
  '';

  # pr-ci `l`: what to fetch logs of, from `argo get -o json`. One line per failed
  # Pod node whose status names its pod ("pod<TAB>name"), and "workflow<TAB>names"
  # when nothing failed or a failed node carries no pod name. Pod names are never
  # rebuilt from node ids: a single-pod workflow's pod is named like the workflow,
  # and the format differs between Argo versions and settings.
  argoLogsJq = ''
    [.status.nodes // {} | .[] | select(.type == "Pod" and (.phase == "Failed" or .phase == "Error"))] as $failed
    | ($failed | map(select((.podName // "") != "") | "pod\t\(.podName)") | .[]),
      ([$failed[] | select((.podName // "") == "") | .displayName // .name]
        | if length > 0 or ($failed | length) == 0 then "workflow\t\(join(", "))" else empty end)
  '';

  # pr-ci `l` once the pods are gone: the Pod nodes whose archived main-logs to fetch
  # from the argo-cli server, as "node id<TAB>displayName<TAB>phase". The failed ones
  # if any, else all of them, in start order. The node id is the key in status.nodes.
  argoArchivedLogsJq = ''
    [.status.nodes // {} | to_entries[] | .value + {id: (.value.id // .key)} | select(.type == "Pod")]
    | sort_by(.startedAt // "") as $pods
    | [$pods[] | select(.phase == "Failed" or .phase == "Error")]
    | (if length > 0 then . else $pods end)[]
    | "\(.id)\t\(.displayName // .name // .id)\t\(.phase // "-")"
  '';

  # pr-ci `l`: argo logs appended to $tmp/live. stdout, stderr and the exit status
  # are kept apart: 0 with output; 1 when the pod is gone (empty successful output,
  # or a not-found error), so the caller falls back to the archive; 2 with any other
  # argo error, written to $tmp/live. A bash function on argo_at, also run by the
  # fixtures against a stub.
  prCiLiveLogs = ''
    live_logs() {
      local host=$1 rc=0
      shift
      argo_at "$host" logs "$@" > "$tmp/out" 2> "$tmp/logerr" || rc=$?
      if [ "$rc" -eq 0 ] && [ -s "$tmp/out" ]; then
        cat "$tmp/out" >> "$tmp/live"
      elif [ "$rc" -eq 0 ] || grep -qiE 'not ?found' "$tmp/logerr"; then
        echo "no logs" >> "$tmp/live"
        return 1
      else
        { echo "argo logs failed (exit $rc):"; cat "$tmp/logerr"; } >> "$tmp/live"
        return 2
      fi
    }
  '';

  # pr-deploy: sources of an Argo CD app and whether one comes from the repo $id
  # (host/owner/repo) named $repo. A Helm OCI source is `repoURL: registry/org` plus
  # `chart: name`, so its chart is compared; an OCI repoURL without a chart matches
  # when its last segment is the name. A scheme-less repoURL without a chart that is
  # an SCP-style git URL (user@host:path) or ends in .git is git, not OCI. Value file
  # paths are resolved against the source path, `.` and `..` included; a `$name/`
  # value file against the source with `ref: name`, only when that source is this repo.
  # A source that matches only as OCI has no path to compare: impact unknown, kept.
  argoAppsJq = jqHelpers + ''
    def srcs: [.spec.source // empty] + (.spec.sources // []);
    def ours: (.repoURL // "" | norm) == $id;
    def oci: (.repoURL // "") as $u | ($u | startswith("oci://"))
      or (($u | test("://") | not)
        and ((.chart // "") != "" or ($u | test("^[^/@:]+@[^/:]+:|[.]git/?$") | not)));
    def normpath: reduce (split("/")[] | select(. != "" and . != ".")) as $s ([];
        if $s == ".." and length > 0 and last != ".." then .[:-1] else . + [$s] end)
      | join("/");
    def oci_name: if (.chart // "") != "" then .chart else (.repoURL // "" | sub("/+$"; "") | split("/") | last) end;
    def from_repo: ours or (oci and (oci_name | ascii_downcase) == ($repo | ascii_downcase));
    def vfiles($ss): . as $s | [(.helm.valueFiles // [])[]
      | if startswith("$") then (capture("^[$](?<n>[^/]+)/(?<p>.*)$") // {}) as $r
          | if $r.n != null and any($ss[]; .ref == $r.n and ours) then $r.p else empty end
        elif ($s | ours) and ($s.path // "") != "" then ($s.path | sub("/+$"; "")) + "/" + .
        else empty end | normpath];
    def path_hit($files): if ours and (.path // "") != ""
      then (.path | sub("/+$"; "")) as $p | any($files[]; $p == "." or . == $p or startswith($p + "/"))
      else false end;
    def touched($files): srcs as $ss
      | any($ss[]; path_hit($files) or (vfiles($ss) as $v | any($files[]; . as $f | any($v[]; . == $f))));
    def impact_unknown: any(srcs[]; from_repo and (ours | not));
    def short: if test("^[0-9a-f]{40}$") then .[0:7] elif startswith("sha256:") then .[0:19] else . end;
    # A multi-source app has one revision per source: take the one of this repo.
    def rev: (if .status.sync.revision then .status.sync.revision
      else (.status.sync.revisions // []) as $r
        | [srcs | to_entries[] | select(.value | from_repo) | $r[.key] // empty][0] // $r[0] // "-" end) | short;
  '';

  # Fixtures for the two jq programs above. pr-ci and pr-deploy depend on this
  # derivation, so a build fails when one of them stops matching.
  prToolsFixtures =
    let
      json = name: value: pkgs.writeText "${name}.json" (builtins.toJSON value);
      node = id: attrs: { inherit id; name = id; displayName = id; } // attrs;
      # A single-pod workflow: the root node is the pod, named like the workflow.
      singlePod = json "single-pod" {
        metadata.name = "lint-x7k2p";
        status.nodes."lint-x7k2p" = node "lint-x7k2p" { type = "Pod"; phase = "Failed"; templateName = "lint"; };
      };
      # Steps: one failed pod with a pod name, one without, one that succeeded.
      multiStep = json "multi-step" {
        metadata.name = "ci-q9w4z";
        status.nodes = {
          "ci-q9w4z" = node "ci-q9w4z" { type = "Steps"; phase = "Failed"; displayName = "ci-q9w4z"; };
          "ci-q9w4z-111" = node "ci-q9w4z-111" { type = "Pod"; phase = "Succeeded"; displayName = "checkout"; podName = "ci-q9w4z-checkout-111"; };
          "ci-q9w4z-222" = node "ci-q9w4z-222" { type = "Pod"; phase = "Failed"; displayName = "build"; podName = "ci-q9w4z-build-222"; };
          "ci-q9w4z-333" = node "ci-q9w4z-333" { type = "Pod"; phase = "Error"; displayName = "test"; };
        };
      };
      succeeded = json "succeeded" {
        status.nodes."ok-1" = node "ok-1" { type = "Pod"; phase = "Succeeded"; podName = "ok-1"; };
      };
      # Archived: no pod names, one node without an id field (the key is the id).
      archived = json "archived" {
        metadata.uid = "0f2e";
        status.nodes = {
          "ar-1" = node "ar-1" { type = "DAG"; phase = "Succeeded"; };
          "ar-1-20" = node "ar-1-20" { type = "Pod"; phase = "Succeeded"; displayName = "lint"; startedAt = "2026-10-01T10:00:02Z"; };
          "ar-1-10" = { type = "Pod"; phase = "Succeeded"; displayName = "checkout"; startedAt = "2026-10-01T10:00:01Z"; };
        };
      };
      apps = json "apps" [
        { metadata.name = "git"; spec.source = { repoURL = "ssh://git@codeberg.org/mistwolftech/drift-warden.git"; path = "charts/x"; }; }
        { metadata.name = "helm-oci"; spec.source = { repoURL = "ghcr.io/mistwolftech"; chart = "drift-warden"; }; }
        { metadata.name = "oci-url"; spec.sources = [ { repoURL = "oci://ghcr.io/mistwolftech/drift-warden"; } ]; }
        { metadata.name = "other-chart"; spec.source = { repoURL = "ghcr.io/drift-warden"; chart = "other"; }; }
        { metadata.name = "other-git"; spec.source = { repoURL = "https://codeberg.org/mistwolftech/other.git"; path = "."; }; }
        { metadata.name = "scp-git"; spec.source = { repoURL = "git@codeberg.org:mistwolftech/drift-warden.git"; path = "."; }; }
        # Same basename, other owner and host, SCP-style without .git: git, not OCI.
        { metadata.name = "other-scp"; spec.source = { repoURL = "git@github.com:other-owner/drift-warden"; path = "."; }; }
      ];
      # Value files outside the chart directory, relative and through a $ref.
      valuesApps = json "values-apps" [
        {
          metadata.name = "up";
          spec.source = {
            repoURL = "https://codeberg.org/mistwolftech/drift-warden.git";
            path = "charts/example";
            helm.valueFiles = [ "../../values/prod.yaml" "./values-extra.yaml" ];
          };
        }
        {
          metadata.name = "ref";
          spec.sources = [
            { repoURL = "ghcr.io/mistwolftech"; chart = "other"; helm.valueFiles = [ "$values/charts/../values/qa.yaml" ]; }
            { repoURL = "https://codeberg.org/mistwolftech/drift-warden.git"; ref = "values"; }
          ];
        }
        # Same value file through a ref to another repo: not this repo's file.
        {
          metadata.name = "other-ref";
          spec.sources = [
            { repoURL = "ghcr.io/mistwolftech"; chart = "other"; helm.valueFiles = [ "$values/values/qa.yaml" ]; }
            { repoURL = "https://github.com/other/config.git"; ref = "values"; }
          ];
        }
      ];
      # More than 20 consumers of this repo's OCI chart: none has a path to compare.
      ociApps = json "oci-apps" (builtins.genList (i: {
        metadata.name = "oci-${toString i}";
        spec.source = { repoURL = "ghcr.io/mistwolftech"; chart = "drift-warden"; targetRevision = "1.0.0"; };
      }) 21);
    in
    pkgs.runCommand "pr-tools-fixtures" { nativeBuildInputs = [ pkgs.jq ]; } ''
      check() {
        if [ "$2" != "$3" ]; then
          printf '%s\n  want: %q\n  got:  %q\n' "$1" "$3" "$2" >&2
          exit 1
        fi
      }
      logs=${pkgs.lib.escapeShellArg argoLogsJq}
      check single-pod "$(jq -r "$logs" ${singlePod})" "$(printf 'workflow\tlint-x7k2p')"
      check multi-step "$(jq -r "$logs" ${multiStep})" "$(printf 'pod\tci-q9w4z-build-222\nworkflow\ttest')"
      check succeeded "$(jq -r "$logs" ${succeeded})" "$(printf 'workflow\t')"
      archived_logs=${pkgs.lib.escapeShellArg argoArchivedLogsJq}
      check archived-failed "$(jq -r "$archived_logs" ${multiStep})" \
        "$(printf 'ci-q9w4z-222\tbuild\tFailed\nci-q9w4z-333\ttest\tError')"
      check archived-all "$(jq -r "$archived_logs" ${archived})" \
        "$(printf 'ar-1-10\tcheckout\tSucceeded\nar-1-20\tlint\tSucceeded')"
      check oci-match "$(jq -r --arg id codeberg.org/mistwolftech/drift-warden --arg repo drift-warden \
        ${pkgs.lib.escapeShellArg argoAppsJq}' [.[] | select(any(srcs[]; from_repo)) | .metadata.name] | join(" ")' ${apps})" \
        "git helm-oci oci-url scp-git"
      apps_defs=${pkgs.lib.escapeShellArg argoAppsJq}
      touched() {
        jq -r --arg id codeberg.org/mistwolftech/drift-warden --arg repo drift-warden --argjson files "$1" \
          "$apps_defs"' [.[] | select(touched($files)) | .metadata.name] | join(" ")' ${valuesApps}
      }
      check values-up "$(touched '["values/prod.yaml"]')" up
      check values-dot "$(touched '["charts/example/values-extra.yaml"]')" up
      check values-ref "$(touched '["values/qa.yaml"]')" ref
      check values-none "$(touched '["charts/values/prod.yaml"]')" ""
      check oci-kept "$(jq -r --arg id codeberg.org/mistwolftech/drift-warden --arg repo drift-warden \
        "$apps_defs"' [.[] | select(touched(["charts/drift-warden/Chart.yaml"]) or impact_unknown)] | length' ${ociApps})" 21

      # live_logs against a stub argo: output, exit status and stderr per case.
      tmp=$(mktemp -d)
      argo_at() { shift; argo "$@"; }
      argo() { printf '%s' "$stub_out"; printf '%s' "$stub_err" >&2; return "$stub_rc"; }
      ${prCiLiveLogs}
      live() {
        stub_out=$1 stub_err=$2 stub_rc=$3
        : > "$tmp/live"
        rc=0
        live_logs host wf -n ns || rc=$?
        printf '%s|%s' "$rc" "$(cat "$tmp/live")"
      }
      check live-ok "$(live 'line 1' "" 0)" "0|line 1"
      check live-empty "$(live "" "" 0)" "1|no logs"
      # argo 4.0.5 on a garbage-collected pod: exit 1, nothing on stdout.
      check live-missing-pod "$(live "" 'level=fatal msg="pods \"wf-main-1\" not found"' 1)" "1|no logs"
      check live-error "$(live "" 'rpc error: code = Unavailable' 1)" \
        "$(printf '2|argo logs failed (exit 1):\nrpc error: code = Unavailable')"
      touch $out
    '';

  # (An xterm-256 approximation table used to live here for neomutt. It was
  # dropped: the 256-cube nearest neighbours are visibly off — notably base
  # #24273a landing on the neutral grey color235 — which left a seam between the
  # neomutt pane and everything else. neomutt now uses the ANSI 0-15 slots and
  # `default`, which the terminal already maps to exact Catppuccin values.)

  # pi-subagents reviewer for the PR flow (see pr-review). `label` names the review
  # file, and agent-review-post signs the PR comment with it, so the forge shows
  # which model wrote what. `isolated` keeps MCP and skills out of the prompt —
  # the Ollama models have 32k of context and nothing to spare. Frontmatter values are
  # double-quoted: pi-subagents drops an agent whose plain value contains ": ".
  piReviewer =
    {
      model,
      label,
      thinking,
      maxTurns,
    }:
    ''
      ---
      description: "Reviews one PR diff read-only and writes .workmux/review-${label}.md"
      model: ${model}
      thinking: ${thinking}
      tools: read, bash, grep, find, ls, write
      isolated: true
      max_turns: ${toString maxTurns}
      ---
      You review one pull request. The task names the PR number and its base ref.

      Review the change shown by `git diff <base>...HEAD`. Stay inside that diff: open
      another file only when a changed line calls into it, and do not read dependency
      sources or build the whole project. Look for correctness bugs first, then anything
      that would break on a clean machine.

      The repository's conventions on ticket keys, branch names, PR title format and
      commit footers apply to PRs written by people and coding agents. PRs opened by
      automation follow the format their automation documents: Renovate (branch
      renovate/*), release tooling (chore(release)), pipelines that pin images or bump
      dependencies, anything whose body says it is automated, and anything the
      repository's review guidelines list as automation. Do not report missing ticket
      keys or naming there; review the change itself as usual. The task names the PR
      author and head branch when they are known: use them to decide.

      Do not edit tracked files, commit, push or post anything to the forge. The only
      file you create is `.workmux/review-${label}.md` at the worktree root: the review in
      English, findings ordered by severity, each naming file:line, why it matters and
      what you would change, ending with one line: approve, or request changes. Write it
      before you finish, then reply with the same review.
    '';

  # .local/bin/pi-ollama-up. Exits 0 when Ollama answers within 2 s and has the reviewer model, 1 with one
  # line on stderr otherwise. pr-review uses it to leave reviewer-ollama out.
  piOllamaUp = pkgs.writeShellApplication {
    name = "pi-ollama-up";
    runtimeInputs = [
      pkgs.curl
      pkgs.jq
    ];
    text = ''
      url=${pkgs.lib.escapeShellArg ollamaUrl}
      model=${pkgs.lib.escapeShellArg ollamaReviewModel}
      if ! tags=$(curl -fsS --max-time 2 "$url/api/tags" 2> /dev/null); then
        echo "pi-ollama-up: Ollama at $url does not answer" >&2
        exit 1
      fi
      if ! jq -e --arg m "$model" 'any(.models[]?; .name == $m)' <<< "$tags" > /dev/null 2>&1; then
        echo "pi-ollama-up: Ollama at $url has no $model" >&2
        exit 1
      fi
    '';
  };

  # Signs an agent comment on a PR; used by the helper scripts below too.
  agentPrComment =
    pkgs.writeShellApplication {
      name = "agent-pr-comment";
      runtimeInputs = [
        pkgs.git
        pkgs.tea
        pkgs.gh
        pkgs.gnugrep
        pkgs.gawk
      ];
      text = ''
        if [ $# -lt 1 ] || [ $# -gt 2 ]; then
          echo "usage: agent-pr-comment <agent> [pr-number]  (comment body on stdin)" >&2
          exit 2
        fi
        agent=$1
        body=$(cat)

        if [ -z "$body" ]; then
          echo "empty comment body" >&2
          exit 1
        fi
        if printf '%s' "$body" | grep -q -P '[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]'; then
          echo "PR comments must be in English (Polish letters found)" >&2
          exit 1
        fi

        branch=$(git rev-parse --abbrev-ref HEAD)
        sha=$(git rev-parse --short HEAD)
        remote=$(git remote get-url origin)

        # Review worktrees are named review/pr-<n>, so the PR number is in the branch.
        pr=''${2:-}
        if [ -z "$pr" ] && [[ $branch =~ ^review/pr-([0-9]+)$ ]]; then
          pr=''${BASH_REMATCH[1]}
        fi

        # The comment is signed with the PR's head branch, not the checkout it was
        # posted from (a review worktree, or a local main that was pushed elsewhere).
        label=$branch
        case $remote in
          *codeberg.org*)
            prs=$(tea pulls ls --state open --limit 200 -f index,head -o simple)
            if [ -z "$pr" ]; then
              pr=$(awk -v b="$branch" '$2 == b { print $1; exit }' <<< "$prs")
            fi
            [ -n "$pr" ] || { echo "no open Codeberg PR for branch $branch" >&2; exit 1; }
            head=$(awk -v n="$pr" '$1 == n { print $2; exit }' <<< "$prs")
            [ -z "$head" ] || label=$head
            ;;
          *github.com*)
            if [ -z "$pr" ]; then
              pr=$(gh pr view --json number -q .number)
            fi
            head=$(gh pr view "$pr" --json headRefName -q .headRefName 2> /dev/null || true)
            [ -z "$head" ] || label=$head
            ;;
          *)
            echo "unsupported remote: $remote" >&2
            exit 1
            ;;
        esac

        # The backticks are literal Markdown, not command substitution.
        # shellcheck disable=SC2016
        comment=$(printf '**%s** · `%s@%s`\n\n%s\n' "$agent" "$label" "$sha" "$body")

        case $remote in
          *codeberg.org*) tea comment "$pr" "$comment" ;;
          *) gh pr comment "$pr" --body "$comment" ;;
        esac
      '';
    };
in
{
  ".local/bin/pinentry-auto".source = pkgs.writeShellScript "pinentry-auto" ''
    # Use curses pinentry for SSH, mac pinentry otherwise
    if [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]; then
      exec ${pkgs.pinentry-curses}/bin/pinentry-curses "$@"
    else
      exec /usr/local/MacGPG2/libexec/pinentry-mac.app/Contents/MacOS/pinentry-mac "$@"
    fi
  '';

  ".gnupg/gpg-agent.conf".text = ''
    default-cache-ttl 86400
    max-cache-ttl 86400
    pinentry-program /Users/twostal/.local/bin/pinentry-auto
  '';
  ".local/bin/tmux-cpu".source = pkgs.writeShellScript "tmux-cpu" ''
    if [ -f /proc/stat ]; then
      awk '/^cpu / {used=$2+$3+$4+$6+$7+$8; total=used+$5; printf "%d", used*100/total}' /proc/stat
    else
      /usr/bin/top -l 1 -n 0 2>/dev/null | awk '/CPU usage/ {gsub(/%/,""); printf "%d", $3+$5}'
    fi
  '';

  ".local/bin/tmux-mem".source = pkgs.writeShellScript "tmux-mem" ''
    if [ -f /proc/meminfo ]; then
      awk '/MemTotal/ {t=$2} /MemAvailable/ {printf "%d", 100-$2*100/t}' /proc/meminfo
    else
      /usr/bin/memory_pressure 2>/dev/null | awk '/percentage/ {printf "%d", 100-$5}'
    fi
  '';
  ".config/btop/themes/catppuccin_macchiato.theme".text = ''
    # Catppuccin Macchiato theme for btop
    # https://github.com/catppuccin/btop

    # Main background, empty for terminal default, need to be empty if you want transparent background
    theme[main_bg]="#24273a"

    # Main text color
    theme[main_fg]="#cad3f5"

    # Title color for boxes
    theme[title]="#cad3f5"

    # Highlight color for keyboard shortcuts
    theme[hi_fg]="#8aadf4"

    # Background color of selected item in processes box
    theme[selected_bg]="#494d64"

    # Foreground color of selected item in processes box
    theme[selected_fg]="#8aadf4"

    # Color of inactive/disabled text
    theme[inactive_fg]="#8087a2"

    # Color of text appearing on top of graphs, i.e uptime and current network graph scaling
    theme[graph_text]="#f4dbd6"

    # Background color of the percentage meters
    theme[meter_bg]="#494d64"

    # Misc colors for processes box including mini cpu graphs, subtle, etc.
    theme[proc_misc]="#f4dbd6"

    # CPU, Memory, Network, Proc box outline colors
    theme[cpu_box]="#c6a0f6"
    theme[mem_box]="#a6da95"
    theme[net_box]="#ee99a0"
    theme[proc_box]="#8aadf4"

    # Box divider line and target line colors
    theme[div_line]="#6e738d"

    # Temperature graph color (Green -> Yellow -> Red)
    theme[temp_start]="#a6da95"
    theme[temp_mid]="#eed49f"
    theme[temp_end]="#ed8796"

    # CPU graph colors (Teal -> Lavender)
    theme[cpu_start]="#8bd5ca"
    theme[cpu_mid]="#7dc4e4"
    theme[cpu_end]="#b7bdf8"

    # Mem/Disk free meter (Mauve -> Lavender -> Blue)
    theme[free_start]="#c6a0f6"
    theme[free_mid]="#b7bdf8"
    theme[free_end]="#8aadf4"

    # Mem/Disk cached meter (Sapphire -> Blue)
    theme[cached_start]="#7dc4e4"
    theme[cached_mid]="#8aadf4"
    theme[cached_end]="#b7bdf8"

    # Mem/Disk available meter (Peach -> Red)
    theme[available_start]="#f5a97f"
    theme[available_mid]="#ee99a0"
    theme[available_end]="#ed8796"

    # Mem/Disk used meter (Green -> Sky)
    theme[used_start]="#a6da95"
    theme[used_mid]="#8bd5ca"
    theme[used_end]="#91d7e3"

    # Download graph colors (Peach -> Red)
    theme[download_start]="#f5a97f"
    theme[download_mid]="#ee99a0"
    theme[download_end]="#ed8796"

    # Upload graph colors (Green -> Sky)
    theme[upload_start]="#a6da95"
    theme[upload_mid]="#8bd5ca"
    theme[upload_end]="#91d7e3"

    # Process box color gradient for threads, mem and cpu usage (Teal -> Mauve)
    theme[process_start]="#8bd5ca"
    theme[process_mid]="#8aadf4"
    theme[process_end]="#c6a0f6"
  '';

  ".config/bat/themes/Catppuccin Macchiato.tmTheme".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>name</key>
        <string>Catppuccin Macchiato</string>
        <key>semanticClass</key>
        <string>theme.dark.catppuccin-macchiato</string>
        <key>uuid</key>
        <string>02b2bdf3-9eb7-4396-bf04-f17f1468f99f</string>
        <key>author</key>
        <string>Catppuccin Org</string>
        <key>colorSpaceName</key>
        <string>sRGB</string>
        <key>settings</key>
        <array>
          <dict>
            <key>settings</key>
            <dict>
              <key>background</key>
              <string>#24273a</string>
              <key>foreground</key>
              <string>#cad3f5</string>
              <key>caret</key>
              <string>#f4dbd6</string>
              <key>lineHighlight</key>
              <string>#363a4f</string>
              <key>misspelling</key>
              <string>#ed8796</string>
              <key>accent</key>
              <string>#c6a0f6</string>
              <key>selection</key>
              <string>#939ab740</string>
              <key>activeGuide</key>
              <string>#494d64</string>
              <key>findHighlight</key>
              <string>#455c6d</string>
              <key>gutterForeground</key>
              <string>#8087a2</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Basic text and variable names</string>
            <key>scope</key>
            <string>text, source, variable.other.readwrite, punctuation.definition.variable</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#cad3f5</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Punctuation</string>
            <key>scope</key>
            <string>punctuation</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#939ab7</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Comments</string>
            <key>scope</key>
            <string>comment, punctuation.definition.comment</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#939ab7</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Strings</string>
            <key>scope</key>
            <string>string, punctuation.definition.string</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#a6da95</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Escape characters</string>
            <key>scope</key>
            <string>constant.character.escape</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#f5bde6</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Numbers and constants</string>
            <key>scope</key>
            <string>constant.numeric, variable.other.constant, entity.name.constant, constant.language.boolean, constant.language.false, constant.language.true, keyword.other.unit</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#f5a97f</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Keywords</string>
            <key>scope</key>
            <string>keyword, keyword.operator.word, keyword.operator.new, variable.language.super, support.type.primitive, storage.type, storage.modifier, punctuation.definition.keyword</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#c6a0f6</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Operators</string>
            <key>scope</key>
            <string>keyword.operator, punctuation.accessor, punctuation.definition.generic, punctuation.definition.tag, punctuation.separator.key-value</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#8bd5ca</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Functions</string>
            <key>scope</key>
            <string>entity.name.function, meta.function-call.method, support.function, variable.function</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#8aadf4</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Classes</string>
            <key>scope</key>
            <string>entity.name.class, entity.other.inherited-class, support.class, entity.name.struct</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#eed49f</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Types</string>
            <key>scope</key>
            <string>meta.type, support.type, entity.name.type</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#eed49f</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Parameters</string>
            <key>scope</key>
            <string>variable.parameter</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#ee99a0</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Built-ins</string>
            <key>scope</key>
            <string>constant.language, support.function.builtin</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#ed8796</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Property names</string>
            <key>scope</key>
            <string>support.type.property-name</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#8aadf4</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Tags</string>
            <key>scope</key>
            <string>entity.name.tag</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#8aadf4</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Attributes</string>
            <key>scope</key>
            <string>entity.other.attribute-name</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#eed49f</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Headings</string>
            <key>scope</key>
            <string>markup.heading</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#ed8796</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Bold</string>
            <key>scope</key>
            <string>markup.bold</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#ed8796</string>
              <key>fontStyle</key>
              <string>bold</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Italic</string>
            <key>scope</key>
            <string>markup.italic</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#ed8796</string>
              <key>fontStyle</key>
              <string>italic</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Code</string>
            <key>scope</key>
            <string>markup.raw, markup.inline.raw</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#a6da95</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Links</string>
            <key>scope</key>
            <string>markup.underline.link</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#8aadf4</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Diff inserted</string>
            <key>scope</key>
            <string>markup.inserted</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#a6da95</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Diff deleted</string>
            <key>scope</key>
            <string>markup.deleted</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#ed8796</string>
            </dict>
          </dict>
          <dict>
            <key>name</key>
            <string>Diff changed</string>
            <key>scope</key>
            <string>markup.changed</string>
            <key>settings</key>
            <dict>
              <key>foreground</key>
              <string>#f5a97f</string>
            </dict>
          </dict>
        </array>
      </dict>
    </plist>
  '';

  ".config/posting/config.yaml".text = ''
    theme: catppuccin-macchiato-blue
  '';

  ".local/share/posting/themes/catppuccin-macchiato-blue.yaml".source =
    pkgs.writeText "catppuccin-macchiato-blue.yaml" ''
      name: "catppuccin-macchiato-blue"
      primary: "#8aadf4"
      secondary: "#8aadf4"
      accent: "#bacff8"
      background: "#24273a"
      surface: "#363a4f"
      error: "#ed8796"
      success: "#a6da95"
      warning: "#eed49f"
      dark: "true"

      text_area:
        cursor: "reverse #f4dbd6"
        cursor_line: "underline #cad3f5"
        selection: "reverse #939ab7"
        gutter: "bold #a6da95"
        matched_bracket: "reverse #b8c0e0"

      url:
        base: "italic #8aadf4"
        protocol: "bold #8bd5ca"
        separator: "#cad3f5"

      syntax:
        json_key: "italic #8aadf4"
        json_number: "#f5a97f"
        json_string: "#a6da95"
        json_boolean: "#91d7e3"
        json_null: "#939ab7"

      method:
        get: "bold #8aadf4"
        post: "bold #a6da95"
        put: "bold #eed49f"
        delete: "bold #ed8796"
        patch: "bold #8bd5ca"
        options: "bold #b7bdf8"
        head: "bold #c6a0f6"
    '';

  # gh-dash for Codeberg. No instance URL or token here on purpose: tea-dash
  # reads both from tea's own config, so `tea login list` stays the single
  # source of truth and no credential lands in the world-readable /nix/store.
  # `login` is named explicitly because that login is not marked default.
  ".config/tea-dash/config.yml".text = ''
    instance:
      login: codeberg
    prSections:
      - title: My PRs
        filter:
          state: open
          createdBy: "@me"
      - title: Needs Review
        filter:
          reviewRequested: "@me"
      - title: All Open
        filter:
          state: open
    issuesSections:
      - title: My Issues
        filter:
          state: open
          createdBy: "@me"
      - title: Assigned
        filter:
          state: open
          assignedBy: "@me"
    # Only title/limit here — unlike gh-dash, tea-dash notification sections
    # take no filters, so the old reason:review-requested / reason:mention
    # splits have no equivalent and collapse into one list.
    notificationsSections:
      - title: Inbox
        limit: 20
    defaults:
      preview:
        open: true
        # Columns, not a fraction: gh-dash's 0.45 would be read as 0 here,
        # which happens to mean "automatic 50/50" — spelled out instead.
        width: 0
      prsLimit: 20
      issuesLimit: 20
      notificationsLimit: 20
      view: prs
      refetchIntervalMinutes: 30
    # No global `repos:` list: with one set, sections without their own repo:
    # fan out over just those repos instead of searching the whole instance,
    # which would quietly narrow "All Open".
    # Every repo is checked out as ~/projects/<repo>, whichever org owns it; the
    # three below are the exceptions (directory name differs, or outside ~/projects).
    repoPaths:
      "*/*": ~/projects/{{.Repo}}
      "mistwolftech/amateur-alchemist": ~/projects/amateur_alchemist
      "tomasz-wostal-eu/n8n-postiz-stack": ~/projects/n8n
      "tomasz-wostal-eu/nixos-config": ~/nixos-config
    # Custom keys are matched before tea-dash's own, so a custom one shadows the
    # default: that is why CI is `i` and deploy `D`, not `c` (comment) and `d`
    # (preview scroll, external diff).
    keybindings:
      prs:
        - key: g
          name: lazygit
          command: >-
            tmux new-window '
              cd {{.RepoPath}} && lazygit
            '
        - key: r
          name: review (pi + subagents)
          command: >-
            tmux new-window '
              cd {{.RepoPath}} && pr-review-repo {{.PrNumber}}; printf "press enter "; read x
            '
        - key: P
          name: post reviews to the PR
          command: >-
            tmux new-window '
              cd {{.RepoPath}} && agent-review-post "$(workmux path pr-{{.PrNumber}})"; printf "press enter "; read x
            '
        - key: i
          name: CI of the PR head (pr-ci)
          command: >-
            tmux new-window '
              cd {{.RepoPath}} && pr-ci {{.PrNumber}}; printf "press enter "; read x
            '
        - key: D
          name: Argo CD and Kargo state (pr-deploy)
          command: >-
            tmux new-window '
              cd {{.RepoPath}} && pr-deploy {{.PrNumber}}; printf "press enter "; read x
            '
        - key: C
          name: claude review
          command: >-
            tmux new-window '
              cd {{.RepoPath}} && claude "Review PR {{.PrNumber}} in {{.RepoName}}. Run: tea pulls {{.PrNumber}} --comments for the description, and git fetch origin pull/{{.PrNumber}}/head && git diff origin/main...FETCH_HEAD for the changes. Provide a thorough code review."
            '
    theme:
      icons: nerd
    confirmQuit: false
  '';

  # herdr — runtime that keeps coding agents (claude, codex, opencode, pi here)
  # alive per project in the background and reattaches from another machine over
  # SSH. Only values that differ from `herdr --default-config` are set; the rest
  # stays on its documented default so upstream can move them.
  #
  # Agent status integrations are NOT here: `herdr integration install <agent>`
  # writes executable hooks into ~/.claude/hooks, ~/.codex, ~/.config/opencode
  # and ~/.pi, none of which home-manager owns. They are mutable state, like the
  # workmux hooks in ~/.claude/settings.json.
  ".config/herdr/config.toml".text = ''
    # Configured declaratively, so the first-run wizard has nothing to ask.
    onboarding = false

    # Everything here is Catppuccin Macchiato, but herdr's built-in
    # "catppuccin" is the Mocha flavour — its own default config documents
    # #1e1e2e / #cdd6f4. These overrides move the tokens it exposes onto
    # Macchiato so it matches tmux, k9s and tea-dash above.
    [theme]
    name = "catppuccin"

    [theme.custom]
    sidebar_bg    = "#1e2030" # mantle
    active_row_bg = "#24273a" # base
    selection_bg  = "#363a4f" # surface0
    accent        = "#f5bde6" # pink
    red           = "#ed8796"
    green         = "#a6da95"

    # nixpkgs owns the version here, so both background calls to herdr.dev are
    # pure noise: `herdr update` cannot write into the read-only store, and a
    # discovered release could only nag. Upgrades arrive with `nix flake update`.
    [update]
    version_check = false
    manifest_check = false
  '';
  # Google Calendar -> local vdir. OAuth client lives in GCP project
  # gcalcli-tw-2026 (published, so the refresh token never expires).
  # The CalDAV API must stay enabled on that project or discovery 403s.
  # Secrets are read at runtime from ~/.config/vdirsyncer/{client_id,client_secret}
  # (mode 600) because this file lands world-readable in /nix/store.
  ".config/vdirsyncer/config".text = ''
    [general]
    status_path = "~/.local/share/vdirsyncer/status/"

    [pair google]
    a = "google_local"
    b = "google_remote"
    collections = ["from b"]
    conflict_resolution = "b wins"
    metadata = ["displayname", "color"]

    [storage google_local]
    type = "filesystem"
    path = "~/.local/share/calendars/"
    fileext = ".ics"

    [storage google_remote]
    type = "google_calendar"
    token_file = "~/.local/share/vdirsyncer/google_token"
    client_id.fetch = ["shell", "cat ~/.config/vdirsyncer/client_id"]
    client_secret.fetch = ["shell", "cat ~/.config/vdirsyncer/client_secret"]
    # Bounded window: keeps the vdir small and skips a legacy CNCF/Bevy invite
    # from 2025-03-12 whose UID contains slashes, which breaks filesystem storage.
    # Changing these bounds requires wiping the vdir + status first, otherwise
    # vdirsyncer reads the newly out-of-range events as local deletions.
    start_date = "datetime.now() - timedelta(days=90)"
    end_date = "datetime.now() + timedelta(days=730)"

    # Second Google account (Workspace, itomm.pl) — separate token, separate
    # vdir. Collections are pinned rather than "from b": that account also
    # exposes "Święta w Polsce" and "Holidays in Poland", which would duplicate
    # the holidays already synced from the personal account.
    [pair itomm]
    a = "itomm_local"
    b = "itomm_remote"
    collections = ["tomasz.wostal@itomm.pl"]
    conflict_resolution = "b wins"
    metadata = ["displayname", "color"]

    [storage itomm_local]
    type = "filesystem"
    path = "~/.local/share/calendars-itomm/"
    fileext = ".ics"

    [storage itomm_remote]
    type = "google_calendar"
    token_file = "~/.local/share/vdirsyncer/itomm_token"
    client_id.fetch = ["shell", "cat ~/.config/vdirsyncer/client_id"]
    client_secret.fetch = ["shell", "cat ~/.config/vdirsyncer/client_secret"]
    start_date = "datetime.now() - timedelta(days=90)"
    end_date = "datetime.now() + timedelta(days=730)"
  '';

  # Calendars are listed explicitly rather than `type = discover` so the colours
  # are Catppuccin instead of whatever Google assigned. The IDs are the vdir
  # directory names created by vdirsyncer; a new Google calendar needs an entry here.
  ".config/khal/config".text = ''
    [calendars]

      [[personal]]
      path = ~/.local/share/calendars/tomasz.wostal@gmail.com
      color = '${cat.blue}'

      [[family]]
      path = ~/.local/share/calendars/family01431012608072901150@group.calendar.google.com
      color = '${cat.green}'

      [[holidays]]
      path = ~/.local/share/calendars/e1m2ss3fdhkn6q13d1nmoqb4c5sk0pridtqn0bjm5phm2r35dpi62shectnmuprcckn66rrd@virtual
      color = '${cat.red}'
      readonly = True

      [[moon]]
      path = ~/.local/share/calendars/ht3jlfaac5lfd6263ulfh4tql8@group.calendar.google.com
      color = '${cat.lavender}'
      readonly = True

      [[work]]
      path = ~/.local/share/calendars-itomm/tomasz.wostal@itomm.pl
      color = '${cat.peach}'

    [locale]
    local_timezone = Europe/Warsaw
    default_timezone = Europe/Warsaw
    timeformat = %H:%M
    dateformat = %d.%m.
    longdateformat = %d.%m.%Y
    datetimeformat = %d.%m. %H:%M
    longdatetimeformat = %d.%m.%Y %H:%M
    firstweekday = 0
    unicode_symbols = True

    [view]
    theme = dark
    # Default format appends the full description, which makes `khal list`
    # unreadable for events with long notes. Use `khal at`/`khal search` for detail.
    agenda_event_format = {calendar-color}{start-end-time-style} {title}{repeat-symbol}{alarm-symbol}{reset}
    event_format = {calendar-color}{start-end-time-style} {title}{repeat-symbol}{alarm-symbol}{reset}

    # Catppuccin Macchiato for ikhal. Entries must be length 2, 3 or 5, and the
    # first two slots only accept the 16 named colours — so the real values go
    # in the trailing high-colour slots and the 16-colour slots stay empty.
    [palette]
    header = "", "", "", "${cat.subtext1}", "${cat.mantle}"
    footer = "", "", "", "${cat.subtext1}", "${cat.mantle}"
    line header = "", "", "", "${cat.text}", "${cat.surface0}"
    alt header = "", "", "", "${cat.overlay1}", "${cat.base}"
    bright = "", "", "", "${cat.blue}", "${cat.base}"
    list = "", "", "", "${cat.text}", "${cat.base}"
    list focused = "", "", "", "${cat.base}", "${cat.blue}"
    edit = "", "", "", "${cat.text}", "${cat.base}"
    edit focus = "", "", "", "${cat.base}", "${cat.blue}"
    editbx = "", "", "", "${cat.text}", "${cat.surface0}"
    editcp = "", "", "", "${cat.base}", "${cat.lavender}"
    button = "", "", "", "${cat.text}", "${cat.surface1}"
    button focused = "", "", "", "${cat.base}", "${cat.blue}"
    reveal focus = "", "", "", "${cat.base}", "${cat.lavender}"
    today = "", "", "", "${cat.base}", "${cat.peach}"
    today focus = "", "", "", "${cat.base}", "${cat.mauve}"
    date header = "", "", "", "${cat.subtext0}", "${cat.base}"
    date header focused = "", "", "", "${cat.base}", "${cat.sapphire}"
    date header selected = "", "", "", "${cat.base}", "${cat.teal}"
    dayname = "", "", "", "${cat.sky}", "${cat.base}"
    monthname = "", "", "", "${cat.mauve}", "${cat.base}"
    weeknumber_right = "", "", "", "${cat.overlay0}", "${cat.base}"
    alert = "", "", "", "${cat.base}", "${cat.red}"
    mark = "", "", "", "${cat.base}", "${cat.green}"
    frame = "", "", "", "${cat.surface2}", "${cat.base}"
    frame focus = "", "", "", "${cat.blue}", "${cat.base}"
    frame focus color = "", "", "", "${cat.blue}", "${cat.base}"
    frame focus top = "", "", "", "${cat.mauve}", "${cat.base}"
    popupbg = "", "", "", "${cat.text}", "${cat.mantle}"

    [default]
    # Must match a calendar *name* from [calendars] above, not the Google ID.
    default_calendar = personal
    highlight_event_days = True
  '';

  # notmuch indexes ~/Mail, which lieer fills from Gmail.
  # Paths are relative, which notmuch resolves against $HOME.
  ".config/notmuch/default/config".text = ''
    [database]
    path=Mail
    mail_root=Mail

    [user]
    name=Tomasz Wostal
    primary_email=tomasz@wostal.eu
    other_email=tomasz.wostal@itomm.pl;tomasz.wostal@gmail.com;tomasz.wostal@devops.toys;tomasz.wostal@mistwolf.tech;support@wostal.eu;info@wostal.eu;support@mistwolf.tech;info@mistwolf.tech

    # Runs post-new below. The default is <mail_root>/.notmuch/hooks, which is
    # inside the maildir lieer owns; keeping hooks in ~/.config keeps them under
    # nix and out of the synced tree.
    hook_dir=${homeDir}/.config/notmuch/hooks

    [new]
    # Deliberately empty: lieer derives tags from Gmail labels, and any tag added
    # here would be pushed back to Gmail as a stray label ("new" is not on
    # lieer's ignore list). Categorisation happens in the post-new hook instead,
    # where the tags are chosen deliberately and are meant to reach Gmail.
    tags=
    ignore=/.*[.](json|lock|bak|tmp)$/;.uidvalidity;.mbsyncstate;.notmuch

    [search]
    exclude_tags=trash;spam;deleted

    [maildir]
    synchronize_flags=true
  '';

  # Kept as a readable file rather than an anonymous store path so the rules can
  # be inspected (and dry-run with `notmuch count`) without rebuilding.
  ".config/notmuch/tag-rules".text = notmuchTagBatch;

  ".config/notmuch/hooks/post-new".source = pkgs.writeShellScript "notmuch-post-new" ''
    exec ${pkgs.notmuch}/bin/notmuch tag --batch --input=${homeDir}/.config/notmuch/tag-rules
  '';

  # Empty marker so the directory exists for neomutt's header cache.
  ".cache/neomutt/.keep".text = "";

  # neomutt renders no HTML on its own. `auto_view text/html` only means "run
  # whatever mailcap says for that type", so without a mailcap entry the pager
  # just prints "[-- text/html is unsupported --]" — which is exactly what it
  # did, since neither ~/.mailcap nor an entry in the neomutt config existed.
  # `copiousoutput` is the flag that makes the output go through the pager
  # inline instead of spawning a viewer; auto_view only considers entries that
  # carry it. The browser entry is listed first because interactive
  # <view-mailcap> takes the first match, while auto_view skips it for lack of
  # copiousoutput — so both routes get the viewer they should.
  ".config/neomutt/mailcap".text = ''
    text/html; ${htmlOpener} %s; nametemplate=%s.html
    text/html; ${pkgs.w3m}/bin/w3m -I %{charset} -T text/html -dump -o display_link_number=1 %s; nametemplate=%s.html; copiousoutput
  '';

  # Open the HTML part of the current message in the real browser, for the mail
  # that only makes sense with images and layout. Pipes the raw message in
  # rather than driving the attachment menu with <search>, which breaks as soon
  # as a message nests its parts differently. The rendered copy goes to a fixed
  # 0600 path under ~/.cache, not to /tmp: mail bodies are private and a
  # per-invocation temp file would just accumulate.
  ".local/bin/mail-html-open".source = pkgs.writeScript "mail-html-open" ''
    #!${pkgs.python3}/bin/python3
    import email
    import email.policy
    import os
    import subprocess
    import sys

    msg = email.message_from_binary_file(sys.stdin.buffer, policy=email.policy.default)
    body = msg.get_body(preferencelist=("html",))
    if body is None:
        sys.exit("this message has no text/html part")

    out = os.path.expanduser("~/.cache/neomutt/preview.html")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    fd = os.open(out, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8", errors="replace") as fh:
        fh.write(body.get_content())

    subprocess.run(["${htmlOpener}", out], check=False)
  '';

  ".config/neomutt/neomuttrc".text = ''
    # ---------------------------------------------------------------- identity
    set realname = "Tomasz Wostal"
    set from     = "tomasz@wostal.eu"
    set use_from = yes
    set reverse_name = yes      # reply from whichever identity received the mail
    alternates "^(tomasz\.wostal@gmail\.com|tomasz\.wostal@itomm\.pl|tomasz@wostal\.eu|tomasz\.wostal@devops\.toys|tomasz\.wostal@mistwolf\.tech|(support|info)@(wostal\.eu|mistwolf\.tech))$"

    # Pick the identity with <esc>1..<esc>5 while composing; msmtp follows the
    # From address on its own, so nothing else needs switching.
    macro compose <esc>1 "<edit-from><kill-line>tomasz@wostal.eu<enter>" "from: wostal.eu"
    macro compose <esc>2 "<edit-from><kill-line>tomasz.wostal@itomm.pl<enter>" "from: itomm.pl"
    macro compose <esc>3 "<edit-from><kill-line>tomasz.wostal@gmail.com<enter>" "from: gmail"
    macro compose <esc>4 "<edit-from><kill-line>tomasz.wostal@devops.toys<enter>" "from: devops.toys"
    macro compose <esc>5 "<edit-from><kill-line>tomasz.wostal@mistwolf.tech<enter>" "from: mistwolf.tech"
    macro compose <esc>6 "<edit-from><kill-line>support@mistwolf.tech<enter>" "from: support@mistwolf.tech"
    macro compose <esc>7 "<edit-from><kill-line>info@mistwolf.tech<enter>" "from: info@mistwolf.tech"
    macro compose <esc>8 "<edit-from><kill-line>support@wostal.eu<enter>" "from: support@wostal.eu"
    macro compose <esc>9 "<edit-from><kill-line>info@wostal.eu<enter>" "from: info@wostal.eu"

    # ---------------------------------------------------------------- notmuch
    # Absolute path required: neomutt does not expand ~ inside a notmuch:// URL.
    set nm_default_url   = "notmuch:///Users/twostal/Mail"
    # Note the underscore: the old `virtual_spoolfile` spelling is silently
    # mis-parsed into `spool_file = "yes"` instead of erroring out.
    set virtual_spool_file = yes
    set nm_record        = no
    set header_cache     = "~/.cache/neomutt"

    # notmuch indexes all of ~/Mail, so these span both accounts at once.
    virtual-mailboxes "Inbox"   "notmuch://?query=tag:inbox and not tag:trash"
    virtual-mailboxes "Unread"  "notmuch://?query=tag:unread and not tag:trash"
    virtual-mailboxes "Flagged" "notmuch://?query=tag:flagged"
    virtual-mailboxes "Sent"    "notmuch://?query=tag:sent"
    virtual-mailboxes "Archive" "notmuch://?query=not tag:inbox and not tag:trash and not tag:sent"
    virtual-mailboxes "All"     "notmuch://?query=not tag:trash"

    # Per-account views. The merged mailboxes above give no clue which account a
    # message came from; `path:` filters on the maildir, which is the only thing
    # that distinguishes them (Gmail labels become identical tags on both).
    virtual-mailboxes "· gmail"     "notmuch://?query=tag:inbox and not tag:trash and path:gmail/**"
    virtual-mailboxes "· itomm"     "notmuch://?query=tag:inbox and not tag:trash and path:itomm/**"
    virtual-mailboxes "· gmail new" "notmuch://?query=tag:unread and not tag:trash and path:gmail/**"
    virtual-mailboxes "· itomm new" "notmuch://?query=tag:unread and not tag:trash and path:itomm/**"

    # Views over the tags applied by the post-new hook. Each group is spelled
    # out because notmuch has no wildcard for tags: `tag:dev/*` matches nothing,
    # it does not expand.
    # "People" is the one that earns its place — roughly half the mailbox is
    # machine-sent, and this is the inbox with that half removed.
    virtual-mailboxes "People"   "notmuch://?query=tag:inbox and not tag:automated and not tag:newsletter and not tag:trash"
    virtual-mailboxes "Dev"      "notmuch://?query=(tag:dev/github or tag:dev/codeberg or tag:dev/security or tag:dev/cloud or tag:dev/vendor or tag:alerts/infra) and not tag:trash"
    virtual-mailboxes "Jobs"     "notmuch://?query=(tag:jobs/recruiter or tag:jobs/alerts) and not tag:trash"
    virtual-mailboxes "Finance"  "notmuch://?query=(tag:finance/banking or tag:finance/payments or tag:finance/invoices) and not tag:trash"
    virtual-mailboxes "Shopping" "notmuch://?query=(tag:shop/orders or tag:shop/delivery or tag:shop/promo) and not tag:trash"

    # ---------------------------------------------------------------- behaviour
    set sort          = threads
    set sort_aux      = reverse-last-date-received
    set mark_old      = no
    set help          = no
    set mail_check_stats = yes
    # Without mailcap_path neomutt looks at ~/.mailcap and /etc/mailcap only,
    # neither of which exists here, so auto_view would silently do nothing.
    set mailcap_path = "~/.config/neomutt/mailcap"
    auto_view text/html
    alternative_order text/plain text/enriched text/html
    # …but a multipart/alternative mail whose text/plain half is the usual
    # "view this in a browser" stub still reads better as HTML: <esc>h renders
    # the current message's HTML part in the real browser.
    macro index,pager <esc>h "<pipe-message>~/.local/bin/mail-html-open<enter>" "HTML in browser"

    # ---------------------------------------------------------------- sidebar
    set sidebar_visible = yes
    set sidebar_width   = 22
    set sidebar_short_path = yes
    set sidebar_format  = "%D%* %?N?%N/? %S"
    bind index,pager \Cp sidebar-prev
    bind index,pager \Cn sidebar-next
    bind index,pager \Co sidebar-open

    # ---------------------------------------------------------------- Catppuccin Macchiato
    set crypt_use_gpgme = yes

    # Uses the ANSI 0-15 slots and `default`, NOT 256-cube approximations.
    # Ghostty's palette (modules/darwin/files.nix) already sets 0-15 to the exact
    # Catppuccin Macchiato values, background #24273a and foreground #cad3f5 — so
    # color4 renders as exactly #8aadf4, the same value khal emits as truecolor.
    # `default` for the background is what removes the seam between panes: any
    # explicit dark here paints a slightly different black than the terminal's.
    # This also survives SSH, where TERM drops to xterm-256color but the remote
    # terminal still applies the same 16-colour palette.
    #   0 surface1  1 red     2 green  3 yellow  4 blue
    #   5 pink      6 teal    7 subtext1  8 surface2  15 subtext0
    color normal      default  default
    color indicator   default  color4
    color status      color7   color0
    color error       color1   default
    color message     color6   default
    color markers     color1   default
    color tilde       color8   default
    color tree        color4   default
    color search      color0   color3
    color attachment  color5   default
    color signature   color15  default
    color bold        color7   default
    color underline   color7   default
    color progress    color0   color4
    color prompt      default  default

    color hdrdefault  color6   default
    color header      color4   default "^(From|Subject):"
    color header      color2   default "^(To|Cc):"

    color quoted      color2   default
    color quoted1     color6   default
    color quoted2     color4   default
    color quoted3     color5   default
    color quoted4     color15  default

    color body        color4   default "(https?|ftp)://[^ ]+"
    color body        color5   default "[-a-z_0-9.%+]+@[-a-z_0-9.]+\.[a-z]+"

    color index         default  default "~A"
    color index         color2   default "~N"
    color index         color3   default "~F"
    color index         color1   default "~D"
    color index         color8   default "~Q"
    color index_author  color5   default "~A"
    color index_subject default  default "~A"
    color index_date    color6   default
    color index_number  color8   default
    color index_size    color15  default

    color sidebar_divider   color0   default
    color sidebar_new       color2   default
    color sidebar_highlight default  color0
    color sidebar_indicator default  color4

    # ---------------------------------------------------------------- sending
    set sendmail          = "${pkgs.msmtp}/bin/msmtp"
    set sendmail_wait     = 0
    set use_envelope_from = yes
    set copy              = no   # lieer pulls the Gmail copy back into notmuch
  '';

  # Prints a short-lived Gmail access token for msmtp's XOAUTH2. Takes the
  # account name and reads ~/.config/msmtp/<name>-oauth.json (mode 600, outside
  # the store); this script only reads it. Tool paths are pinned because msmtp
  # may be invoked from neomutt with a minimal PATH.
  ".local/bin/msmtp-oauth-token".source = pkgs.writeShellScript "msmtp-oauth-token" ''
    set -euo pipefail
    cfg="$HOME/.config/msmtp/''${1:?provide the account name}-oauth.json"
    jq="${pkgs.jq}/bin/jq"
    ${pkgs.curl}/bin/curl -s --fail \
      -d client_id="$("$jq" -r .client_id "$cfg")" \
      -d client_secret="$("$jq" -r .client_secret "$cfg")" \
      -d refresh_token="$("$jq" -r .refresh_token "$cfg")" \
      -d grant_type=refresh_token \
      https://oauth2.googleapis.com/token \
      | "$jq" -re .access_token
  '';

  # Three-pane dashboard for the sesh "inbox" window: neomutt on the left,
  # calendar top-right, tasks bottom-right.
  # Refresh is a plain `clear; cmd; sleep` loop rather than watch(1): `watch -c`
  # silently drops 24-bit sequences, so khal's Catppuccin colours would degrade
  # to plain SGR. Verified — direct khal emits four `38;2;` runs, through
  # `watch -c` zero, through this loop four.
  ".local/bin/tmux-inbox".source = pkgs.writeShellScript "tmux-inbox" ''
    set -u
    self="$0"
    case "''${1:-}" in
      --khal)
        while :; do
          clear
          ${pkgs.khal}/bin/khal --color list today 14d 2>&1
          sleep 60
        done
        ;;
      --task)
        while :; do
          clear
          ${pkgs.taskwarrior2}/bin/task rc._forcecolor=on rc.confirmation=no 2>&1
          sleep 60
        done
        ;;
      *)
        here="''${TMUX_PANE:-}"
        ${pkgs.tmux}/bin/tmux split-window -h -l 45% "$self --khal"
        ${pkgs.tmux}/bin/tmux split-window -v -l 50% "$self --task"
        [ -n "$here" ] && ${pkgs.tmux}/bin/tmux select-pane -t "$here"
        exec ${pkgs.neomutt}/bin/neomutt
        ;;
    esac
  '';

  # Codeberg's *native* issue tracker, which bugwarrior cannot reach: it has no
  # gitea/forgejo service and 2.1.0 is the newest upstream release. git-bug only
  # covers issues stored as git refs, so without this the Forgejo issues you
  # actually work from stay invisible. Repos are discovered from git remotes
  # rather than hardcoded. Token: ~/.config/codeberg/token (0600).
  ".local/bin/codeberg-tasks".source =
    pkgs.writeScript "codeberg-tasks" ''
      #!${pkgs.python3}/bin/python3
      import os
      os.environ["PATH"] = "${pkgs.taskwarrior2}/bin:${pkgs.git}/bin:" + os.environ.get("PATH", "")
      ${builtins.readFile ./codeberg-tasks.py}
    '';

  # One section per repo, each on its own port: bugwarrior's gitbug service
  # works by spawning `git-bug webui` and querying its GraphQL endpoint, and the
  # port setting defaults to 43915 for every service — leave it at the default
  # and the repos collide. Note this spawns one webui subprocess per repo per
  # pull, so the run cost grows linearly with this list.
  ".config/bugwarrior/bugwarrior.toml".text =
    let
      repos = [
        "cd-homelab"
        "drift-warden"
        "hydro-habitat"
        # "hydrohabitat" — stale local clone; mistwolftech/hydrohabitat no longer
        # exists on Codeberg ("Cannot find repository"). hydro-habitat is the live one.
        "iac-hetzner"
        "mistwolf-tech"
        "mistwolf-video-producer"
        "nexus-hetzner"
        "publishing-queue"
        "wostal-cloud"
        "wostal-eu"
      ];
      section = i: r: ''

        [${r}]
        service = "gitbug"
        path = "~/projects/${r}"
        port = ${toString (43915 + i)}
        add_tags = ["${r}"]
        # Default template renders "(bw)Bug# - <title>": it wants an issue
        # number and git-bug has none, leaving a bare "Bug#" stub.
        description_template = "{{gitbugtitle}}"
      '';
    in
    ''
      [general]
      targets = [${pkgs.lib.concatMapStringsSep ", " (r: ''"${r}"'') repos}]
      taskrc = "~/.taskrc"
      inline_links = false
      annotation_links = true
    ''
    + pkgs.lib.concatStrings (pkgs.lib.imap0 section repos);

  # Catppuccin Macchiato via the ANSI 0-15 slots, same reasoning as neomutt:
  # the terminal palette already *is* Catppuccin, so color4 is exactly #8aadf4
  # and `default` inherits the real background — no second, slightly-off black.
  ".taskrc".text = ''
    data.location=~/.task
    confirmation=no
    verbose=label,affected,blank,footnote,header,special
    news.version=2.6.2

    # --- report tweaks
    default.command=next
    report.next.columns=id,start.age,entry.age,depends,priority,project,tags,recur,scheduled.countdown,due.relative,until.remaining,description,urgency
    report.next.labels=ID,Active,Age,Deps,P,Project,Tag,Recur,S,Due,Until,Description,Urg
    # bugwarrior's gitbug service keeps returning closed bugs, so it never
    # "closes" the task — it only flips the gitbugstate UDA. Without this filter
    # every bug you ever closed stays on the list forever. Verified that tasks
    # with no gitbugstate at all (i.e. ones you added by hand) still show up.
    report.next.filter=status:pending -WAITING gitbugstate.isnt:CLOSED
    # Everything git-bug knows about, closed included.
    report.bugs.description=git-bug issues
    report.bugs.columns=id,project,tags,gitbugstate,description,urgency
    report.bugs.labels=ID,Project,Tag,State,Description,Urg
    report.bugs.filter=status:pending gitbugid.any:
    report.bugs.sort=urgency-

    # --- Catppuccin Macchiato
    rule.precedence.color=deleted,completed,active,keyword.,tag.,project.,overdue,scheduled,due.today,due,blocked,blocking,recurring,tagged,uda.
    color=on
    color.active=color0 on color3
    color.overdue=color1
    color.due.today=color1
    color.due=color3
    color.scheduled=color6
    color.recurring=color5
    color.blocked=color8
    color.blocking=color5
    color.tagged=color2
    color.completed=color8
    color.deleted=color8
    color.header=color4
    color.footnote=color6
    color.label=color7
    color.label.sort=color7
    color.error=color1
    color.debug=color8
    color.alternate=
    color.calendar.today=color0 on color4
    color.calendar.due=color0 on color1
    color.calendar.due.today=color0 on color1
    color.calendar.overdue=color0 on color5
    color.calendar.weekend=
    color.calendar.holiday=color0 on color3
    color.calendar.weeknumber=color8

    # --- UDAs written by bugwarrior's gitbug service.
    # Without these the description renders as a bare "(bw)Bug#" placeholder.
    uda.gitbugauthor.type=string
    uda.gitbugauthor.label=Gitbug Issue Author
    uda.gitbugid.type=string
    uda.gitbugid.label=Gitbug UUID
    uda.gitbugstate.type=string
    uda.gitbugstate.label=Gitbug state
    uda.gitbugtitle.type=string
    uda.gitbugtitle.label=Gitbug Title

    # --- UDAs for codeberg-tasks (Forgejo importer).
    # These MUST be declared here. `task config uda...` cannot add them at
    # runtime because this file is a read-only nix store symlink — the write
    # fails silently and taskwarrior then folds "cbissue:..." into the task
    # *description* instead, so `cbissue.any:` matches nothing and every run
    # re-adds every issue as a duplicate.
    uda.cbissue.type=string
    uda.cbissue.label=Codeberg Issue
    uda.cburl.type=string
    uda.cburl.label=Codeberg URL
  '';

  # pass holds the canonical copy of the *static* secrets. Runtime reads stay on
  # the plain 0600 files on purpose: the launchd sync agents run unattended, and
  # routing them through pass would make every cycle depend on an unlocked
  # gpg-agent (24h TTL here, GUI pinentry) — a cold cache would either pop a
  # dialog at a random moment or fail silently.
  ".local/bin/secrets-restore".source = pkgs.writeShellScript "secrets-restore" ''
    set -euo pipefail
    umask 077
    r() {
      mkdir -p "$(dirname "$2")"
      ${pkgs.pass}/bin/pass show "$1" > "$2"
      chmod 600 "$2"
      echo "  $2"
    }
    echo "Restoring from pass:"
    r email/oauth/vdirsyncer-client-id     "$HOME/.config/vdirsyncer/client_id"
    r email/oauth/vdirsyncer-client-secret "$HOME/.config/vdirsyncer/client_secret"
    r email/oauth/lieer-client.json        "$HOME/.config/lieer/client_secret.json"
    r email/oauth/msmtp-gmail.json         "$HOME/.config/msmtp/gmail-oauth.json"
    r email/oauth/msmtp-itomm.json         "$HOME/.config/msmtp/itomm-oauth.json"
    r codeberg/api-token                   "$HOME/.config/codeberg/token"
    r slack/mcp-client-secret              "$HOME/.config/slack/mcp-client-secret"
    r argocd/mcp-api-token                 "$HOME/.config/argocd/mcp-api-token"
    echo
    echo "NOT restorable (runtime state, rotated by the tools themselves):"
    echo "  ~/Mail/{gmail,itomm}/.credentials.gmailieer.json"
    echo "    -> gmi auth -C ~/Mail/<repo> -c ~/.config/lieer/client_secret.json"
    echo "  ~/.local/share/vdirsyncer/{google,itomm}_token"
    echo "    -> vdirsyncer discover"
    echo "  ~/.local/share/workspace-mcp/*.json"
    echo "    -> first google-workspace MCP call per account opens the consent page"
  '';

  # Counterpart: push the current on-disk secrets back into pass after a
  # re-authorisation issues a new refresh token.
  ".local/bin/secrets-backup".source = pkgs.writeShellScript "secrets-backup" ''
    set -euo pipefail
    b() {
      [ -f "$2" ] || { echo "  skipping (missing): $2"; return 0; }
      ${pkgs.pass}/bin/pass insert -m -f "$1" < "$2" >/dev/null
      echo "  $1 <- $2"
    }
    echo "Saving to pass:"
    b email/oauth/vdirsyncer-client-id     "$HOME/.config/vdirsyncer/client_id"
    b email/oauth/vdirsyncer-client-secret "$HOME/.config/vdirsyncer/client_secret"
    b email/oauth/lieer-client.json        "$HOME/.config/lieer/client_secret.json"
    b email/oauth/msmtp-gmail.json         "$HOME/.config/msmtp/gmail-oauth.json"
    b email/oauth/msmtp-itomm.json         "$HOME/.config/msmtp/itomm-oauth.json"
    b codeberg/api-token                   "$HOME/.config/codeberg/token"
    b slack/mcp-client-secret              "$HOME/.config/slack/mcp-client-secret"
    b argocd/mcp-api-token                 "$HOME/.config/argocd/mcp-api-token"
    if ${pkgs.git}/bin/git -C "$HOME/.password-store" rev-parse --git-dir >/dev/null 2>&1; then
      ${pkgs.pass}/bin/pass git push 2>/dev/null && echo "  pushed to remote" || echo "  (push failed - check remote)"
    fi
  '';

  # No password anywhere in here, so it is safe to live world-readable in the
  # nix store — msmtp only refuses that for configs containing a literal
  # `password` line. Gmail's SMTP needs the full https://mail.google.com/
  # scope; the narrower gmail.send that lieer-style scopes give is rejected.
  # Two real mailboxes, five identities. neomutt passes -f <address> (it has
  # use_envelope_from set), and msmtp picks the first account whose `from`
  # matches — so switching identity in neomutt switches the SMTP account with
  # no further wiring. The wostal.eu / devops.toys / mistwolf.tech identities
  # are Gmail "send as" aliases of the itomm mailbox, so they authenticate as
  # tomasz.wostal@itomm.pl and reuse its token.
  ".msmtprc".text = ''
    defaults
    auth           xoauth2
    tls            on
    tls_starttls   on
    logfile        ~/.cache/msmtp.log
    host           smtp.gmail.com
    port           587

    account        gmail
    from           tomasz.wostal@gmail.com
    user           tomasz.wostal@gmail.com
    passwordeval   "$HOME/.local/bin/msmtp-oauth-token gmail"

    account        itomm
    from           tomasz.wostal@itomm.pl
    user           tomasz.wostal@itomm.pl
    passwordeval   "$HOME/.local/bin/msmtp-oauth-token itomm"

    account        wostal
    from           tomasz@wostal.eu
    user           tomasz.wostal@itomm.pl
    passwordeval   "$HOME/.local/bin/msmtp-oauth-token itomm"

    account        devops
    from           tomasz.wostal@devops.toys
    user           tomasz.wostal@itomm.pl
    passwordeval   "$HOME/.local/bin/msmtp-oauth-token itomm"

    account        mistwolf
    from           tomasz.wostal@mistwolf.tech
    user           tomasz.wostal@itomm.pl
    passwordeval   "$HOME/.local/bin/msmtp-oauth-token itomm"

    account        support-mistwolf
    from           support@mistwolf.tech
    user           tomasz.wostal@itomm.pl
    passwordeval   "$HOME/.local/bin/msmtp-oauth-token itomm"

    account        info-mistwolf
    from           info@mistwolf.tech
    user           tomasz.wostal@itomm.pl
    passwordeval   "$HOME/.local/bin/msmtp-oauth-token itomm"

    account        support-wostal
    from           support@wostal.eu
    user           tomasz.wostal@itomm.pl
    passwordeval   "$HOME/.local/bin/msmtp-oauth-token itomm"

    account        info-wostal
    from           info@wostal.eu
    user           tomasz.wostal@itomm.pl
    passwordeval   "$HOME/.local/bin/msmtp-oauth-token itomm"

    # Matches the Gmail default sending identity of the itomm mailbox.
    account default : wostal
  '';

  # Leaves a trace on the PR for the current branch: `agent-pr-comment claude <<< "..."`.
  # The forge comes from the origin remote (Codeberg -> tea, GitHub -> gh), and the
  # comment is signed with the agent, branch and short SHA so the history says who
  # said what about which commit. Comments are English by rule, so the body is
  # rejected when it contains Polish letters.
  ".local/bin/agent-pr-comment".source = pkgs.lib.getExe agentPrComment;

  # Starts a task from a Jira key: `wja DW-123 short title words`. Always branches from a
  # freshly fetched default branch (the step agents used to forget), names the branch
  # type/KEY-slug and hands the agent a prompt that carries the key. `-t fix|chore|...`
  # sets the branch type, feat by default.
  ".local/bin/wja".source = pkgs.lib.getExe (
    pkgs.writeShellApplication {
      name = "wja";
      runtimeInputs = [
        pkgs.git
        pkgs.gnused
        pkgs.coreutils
      ];
      text = ''
        type=feat
        while getopts "t:" opt; do
          case $opt in
            t) type=$OPTARG ;;
            *) echo "usage: wja [-t type] KEY [title words...]" >&2; exit 2 ;;
          esac
        done
        shift $((OPTIND - 1))

        key=''${1:-}
        if ! [[ $key =~ ^[A-Z][A-Z0-9]+-[0-9]+$ ]]; then
          echo "usage: wja [-t type] KEY [title words...]  (KEY looks like DW-123)" >&2
          exit 2
        fi
        shift
        title="$*"

        # LC_ALL=C: GNU tr works on bytes and mangles UTF-8 letters otherwise.
        slug=$(printf '%s' "$title" | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' | cut -c1-40 | LC_ALL=C sed -E 's/-+$//')
        branch="$type/$key''${slug:+-$slug}"

        git rev-parse --git-dir > /dev/null
        git fetch --prune origin
        base=$(git symbolic-ref --short refs/remotes/origin/HEAD 2> /dev/null || echo origin/main)

        prompt="Task $key''${title:+: $title}. Read the task first (Jira $key, via the Atlassian MCP when it is available) and follow this repository's CLAUDE.md workflow. Commit footer: Refs: $key. PR titles, descriptions and comments are English."

        exec workmux add "$branch" --base "$base" -p "$prompt"
      '';
    }
  );

  # Is the Ollama reviewer usable right now? Silent on success (piOllamaUp above).
  ".local/bin/pi-ollama-up".source = pkgs.lib.getExe piOllamaUp;

  # Reviews a PR of the repo in the current directory: `pr-review 42 [--quick]
  # [--jira-prefix KEY]`. The one review flow: scripts/dw-review, met-review and we-review
  # are thin wrappers around it (DW-242). Any repo, on GitHub or Codeberg, gets a worktree
  # review/pr-<n> on the PR head with the `review` layout and the reviewers briefed with the
  # base branch's AGENTS.md. Reviews go out through agent-review-post. Source: pr-review.sh.
  ".local/bin/pr-review".source = pkgs.lib.getExe (
    pkgs.writeShellApplication {
      name = "pr-review";
      runtimeInputs = [
        pkgs.git
        pkgs.tea
        pkgs.gh
        pkgs.jq
        pkgs.coreutils
        pkgs.findutils
        pkgs.gnugrep
        piOllamaUp
      ];
      text = builtins.readFile ./pr-review.sh;
    }
  );

  # What tea-dash and gh-dash `r` run: the repo's own scripts/*-review wrapper when it has
  # exactly one (so the reviewers get the Jira key, DW-245), else pr-review. Source:
  # pr-review-repo.sh.
  ".local/bin/pr-review-repo".source = pkgs.lib.getExe (
    pkgs.writeShellApplication {
      name = "pr-review-repo";
      runtimeInputs = [ pkgs.coreutils ];
      text = builtins.readFile ./pr-review-repo.sh;
    }
  );

  # Collects what the reviewers wrote in a review worktree (.workmux/review-<agent>.md)
  # and posts each file to the PR as a comment signed with the agent, after a preview.
  # Posting is deliberately a step the user takes: it is visible on the forge.
  ".local/bin/agent-review-post".source = pkgs.lib.getExe (
    pkgs.writeShellApplication {
      name = "agent-review-post";
      runtimeInputs = [
        pkgs.git
        pkgs.coreutils
        agentPrComment
      ];
      text = ''
        yes=0
        if [ "''${1:-}" = "-y" ]; then
          yes=1
          shift
        fi
        dir=''${1:-.}
        cd "$dir"
        cd "$(git rev-parse --show-toplevel)"

        branch=$(git rev-parse --abbrev-ref HEAD)
        if ! [[ $branch =~ ^review/pr-[0-9]+$ ]]; then
          echo "not a review worktree (branch is $branch, expected review/pr-<n>)" >&2
          exit 1
        fi

        shopt -s nullglob
        files=(.workmux/review-*.md)
        if [ ''${#files[@]} -eq 0 ]; then
          echo "no .workmux/review-*.md files here; the reviewers have not written one yet" >&2
          exit 1
        fi

        for f in "''${files[@]}"; do
          agent=$(basename "$f" .md)
          agent=''${agent#review-}
          echo "=== $agent ($f)"
          cat "$f"
          echo
          if [ "$yes" -ne 1 ]; then
            read -r -p "Post this as '$agent' to the PR? [y/N] " answer
            [ "$answer" = "y" ] || { echo "skipped"; continue; }
          fi
          # One failed post must not stop the remaining reviews from going out.
          if agent-pr-comment "$agent" < "$f"; then
            mv "$f" "$f.posted"
          else
            echo "posting $agent failed; $f kept for a retry" >&2
          fi
        done
      '';
    }
  );

  # CI of a PR's head commit, from a repo checkout: `pr-ci 42`. Codeberg statuses come
  # from the Forgejo API (tea api, tea's own login), GitHub's from `gh pr checks`.
  # Every Argo Workflows run a status links to gets an `argo get`. Access per host is
  # argoHosts above. Server mode, when the argo-cli server answers and a token mints:
  # one short-lived service account token per run (kubectl create token), held in a
  # shell variable and passed only in argo's environment, never on a command line or
  # the screen; it also sees archived workflows and their logs. Otherwise kube mode,
  # with the host's kube context always passed explicitly, because the default
  # context is a dead local cluster.
  ".local/bin/pr-ci".source = pkgs.lib.getExe (
    pkgs.writeShellApplication {
      name = "pr-ci";
      # The jq programs are single-quoted on purpose: their $names are jq's.
      excludeShellChecks = [ "SC2016" ];
      runtimeInputs = [
        pkgs.git
        pkgs.tea
        pkgs.gh
        pkgs.jq
        pkgs.gnugrep
        pkgs.coreutils
        pkgs.curl
        pkgs.kubectl
        pkgs.argo-workflows
      ];
      derivationArgs.fixtures = prToolsFixtures;
      text = ''
        if ! [[ ''${1:-} =~ ^[0-9]+$ ]]; then
          echo "usage: pr-ci <pr-number>  (in a checkout of the PR's repo)" >&2
          exit 2
        fi
        pr=$1
        remote=$(git remote get-url origin)
        defs=${pkgs.lib.escapeShellArg jqHelpers}

        ${argoHostsBash "kube_context" "kubeContext"}
        ${argoHostsBash "cli_server" "cliServer"}
        ${argoHostsBash "token_account" "tokenAccount"}
        declare -A argo_mode=() argo_token=()

        # argo output goes through files, not $(...): a token re-minted in a
        # subshell would be lost to the rest of the run.
        tmp=$(mktemp -d)
        trap 'rm -rf "$tmp"' EXIT

        # A one-hour token for the argo-cli service account, kept in argo_token only.
        mint_token() {
          local acct=''${token_account[$1]:-}
          [ -n "$acct" ] || return 1
          argo_token[$1]=$(kubectl --context "''${kube_context[$1]:-}" -n "''${acct%%/*}" create token "''${acct#*/}" --duration=1h 2> /dev/null) || return 1
          [ -n "''${argo_token[$1]}" ]
        }

        # Server mode when the host's argo-cli server answers within 3 s and a token
        # mints, else kube mode with one line on why. Decided once per host and run.
        server_mode() {
          local host=$1 server=''${cli_server[$1]:-}
          if [ -z "''${argo_mode[$host]:-}" ]; then
            argo_mode[$host]=kube
            if [ -z "$server" ]; then
              :
            elif ! curl -s -o /dev/null --max-time 3 "https://$server/"; then
              echo "argo-cli server $server not reachable, kube mode: archived workflows not visible" >&2
            elif ! mint_token "$host"; then
              echo "could not mint an argo-cli token (''${token_account[$host]}), kube mode: archived workflows not visible" >&2
            else
              argo_mode[$host]=server
            fi
          fi
          [ "''${argo_mode[$host]}" = server ]
        }

        # The ARGO_* assignments reach argo's environment only.
        argo_server() {
          local host=$1
          shift
          ARGO_SERVER="''${cli_server[$host]}:443" ARGO_HTTP1=true ARGO_SECURE=true ARGO_TOKEN="Bearer ''${argo_token[$host]}" argo "$@"
        }

        # argo against one UI host; in server mode a rejected token is re-minted once.
        argo_at() {
          local host=$1 rc=0
          shift
          if server_mode "$host"; then
            argo_server "$host" "$@" 2> "$tmp/err" || rc=$?
            if [ "$rc" -ne 0 ] && grep -qiE 'unauthenticated|401' "$tmp/err" && mint_token "$host"; then
              rc=0
              argo_server "$host" "$@" 2> "$tmp/err" || rc=$?
            fi
            cat "$tmp/err" >&2
            return "$rc"
          elif [ -n "''${kube_context[$host]:-}" ]; then
            env -u ARGO_SERVER -u ARGO_TOKEN argo --context "''${kube_context[$host]}" "$@"
          else
            echo "no Argo access configured for $host (argoHosts in files.nix)" >&2
            return 1
          fi
        }

        # Sets sha, pr_url, checks (JSON: context, state, description, url) and wfs
        # ("host namespace name" of every linked Argo workflow, deduplicated).
        load_ci() {
          local pr_json raw
          case $remote in
            *codeberg.org*)
              pr_json=$(tea pulls "$pr" -o json) || return 1
              sha=$(jq -r '.headSha // empty' <<< "$pr_json")
              pr_url=$(jq -r '.url // empty' <<< "$pr_json")
              [ -n "$sha" ] || return 1
              raw=$(tea api "/repos/{owner}/{repo}/commits/$sha/status") || return 1
              checks=$(jq -c '[.statuses[]? | {context, state: (.status // .state), description: (.description // ""), url: (.target_url // "")}]' <<< "$raw") || return 1
              ;;
            *github.com*)
              pr_json=$(gh pr view "$pr" --json headRefOid,url) || return 1
              sha=$(jq -r .headRefOid <<< "$pr_json")
              pr_url=$(jq -r .url <<< "$pr_json")
              # gh pr checks exits non-zero while a check fails or is pending.
              raw=$(gh pr checks "$pr" --json name,state,description,link 2> /dev/null || true)
              checks=$(jq -c '[.[]? | {context: .name, state: (.state | ascii_downcase), description: (.description // ""), url: (.link // "")}]' <<< "''${raw:-[]}") || return 1
              ;;
            *)
              echo "unsupported remote: $remote" >&2
              exit 1
              ;;
          esac
          mapfile -t wfs < <(jq -r '[.[].url | capture("^https://(?<h>[^/]+)/workflows/(?<ns>[^/]+)/(?<n>[^/?#]+)") | "\(.h) \(.ns) \(.n)"] | unique | .[]' <<< "$checks")
        }

        show() {
          local host ns name
          load_ci || { echo "could not read the CI of PR #$pr" >&2; return 1; }
          echo "PR #$pr, head ''${sha:0:12}"
          if [ "$(jq length <<< "$checks")" -eq 0 ]; then
            echo "no CI statuses on this commit"
          else
            jq -r "$defs"' [["CONTEXT", "STATE", "DESCRIPTION"]] + map([.context, .state, .description]) | table' <<< "$checks"
          fi
          for wf in "''${wfs[@]}"; do
            read -r host ns name <<< "$wf"
            echo
            if server_mode "$host"; then
              echo "== $name ($host, server mode via ''${cli_server[$host]})"
            else
              echo "== $name ($host, kube context ''${kube_context[$host]:-none})"
            fi
            if argo_at "$host" get "$name" -n "$ns" > "$tmp/out" 2>&1; then
              cat "$tmp/out"
            elif ! server_mode "$host" && grep -q 'not found' "$tmp/out"; then
              echo "https://$host/workflows/$ns/$name"
              echo "gone from the cluster (garbage-collected); the workflow archive needs server mode"
            else
              cat "$tmp/out"
            fi
          done
        }

        # Sets picked to one of wfs, asking when there is more than one.
        pick_workflow() {
          local i
          picked=""
          case ''${#wfs[@]} in
            0)
              echo "no Argo workflow linked from this PR's CI"
              return 1
              ;;
            1) picked=''${wfs[0]} ;;
            *)
              for i in "''${!wfs[@]}"; do
                echo "  $((i + 1))  ''${wfs[$i]##* }"
              done
              read -r -p "workflow #: " i || return 1
              if ! [[ $i =~ ^[0-9]+$ ]] || [ "$i" -lt 1 ] || [ "$i" -gt ''${#wfs[@]} ]; then
                return 1
              fi
              picked=''${wfs[$((i - 1))]}
              ;;
          esac
        }

        # argo logs appended to $tmp/live; 1 when argo had nothing to say.
        ${prCiLiveLogs}

        # One archived main-logs artifact into $tmp/node.log; prints the HTTP status.
        # The token reaches curl as a config line on stdin, never as an argument.
        archived_get() {
          curl -s --max-time 30 -o "$tmp/node.log" -w '%{http_code}' --config - "$2" \
            <<< "header = \"Authorization: Bearer ''${argo_token[$1]}\"" || true
        }

        # Server mode, pods gone: main-logs of the failed Pod nodes (else all of them)
        # from S3 through the argo-cli server's artifact endpoint.
        archived_logs() {
          local host=$1 ns=$2 uid id node phase url code
          uid=$(jq -r '.metadata.uid // empty' "$tmp/wf.json")
          if [ -z "$uid" ]; then
            echo "no logs: the workflow has no uid"
            return 0
          fi
          jq -r ${pkgs.lib.escapeShellArg argoArchivedLogsJq} "$tmp/wf.json" > "$tmp/nodes" || return 0
          if ! [ -s "$tmp/nodes" ]; then
            echo "no logs: the workflow has no pod steps"
            return 0
          fi
          while IFS=$'\t' read -r id node phase; do
            echo "== $node ($phase, archived)"
            url="https://''${cli_server[$host]}/artifact-files/$ns/archived-workflows/$uid/$id/outputs/main-logs"
            code=$(archived_get "$host" "$url")
            if [ "$code" = 401 ] && mint_token "$host"; then
              code=$(archived_get "$host" "$url")
            fi
            if [ "$code" = 200 ] && [ -s "$tmp/node.log" ]; then
              cat "$tmp/node.log"
            elif [ "$code" = 200 ] || [ "$code" = 404 ]; then
              echo "no archived logs for $node"
            else
              echo "could not fetch the archived logs of $node (HTTP $code)"
            fi
          done < "$tmp/nodes"
        }

        # Logs of the failed pods the workflow status names, else of the whole
        # workflow (this argo has no --node-field-selector to narrow it). When argo
        # has no logs at all, the pods are gone (pod GC): server mode fetches the
        # archived logs per node, kube mode cannot. Any other argo error is shown
        # as it is, without the archive.
        logs() {
          local host ns name kind arg rc found=0 failed=0
          pick_workflow || return 0
          read -r host ns name <<< "$picked"
          argo_at "$host" get "$name" -n "$ns" -o json > "$tmp/wf.json" || return 0
          jq -r ${pkgs.lib.escapeShellArg argoLogsJq} "$tmp/wf.json" > "$tmp/plan" || return 0
          : > "$tmp/live"
          while IFS=$'\t' read -r kind arg; do
            if [ "$kind" = pod ]; then
              echo "== $arg" >> "$tmp/live"
              rc=0
              live_logs "$host" "$name" "$arg" -n "$ns" || rc=$?
            else
              if [ -n "$arg" ]; then
                echo "== $name (failed, no pod name in the node status: $arg)" >> "$tmp/live"
              else
                echo "== $name" >> "$tmp/live"
              fi
              rc=0
              live_logs "$host" "$name" -n "$ns" || rc=$?
            fi
            case $rc in
              0) found=1 ;;
              2) failed=1 ;;
            esac
          done < "$tmp/plan"
          if [ "$found" = 1 ] || [ "$failed" = 1 ]; then
            cat "$tmp/live"
          elif server_mode "$host"; then
            archived_logs "$host" "$ns"
          else
            echo "no logs: the pods are gone (pod GC); archived logs need server mode"
          fi
        }

        open_ui() {
          local host ns name url=$pr_url
          if pick_workflow; then
            read -r host ns name <<< "$picked"
            url="https://$host/workflows/$ns/$name"
          fi
          [ -z "$url" ] || ${htmlOpener} "$url"
        }

        # Ctrl-C stops argo watch/logs, not the whole loop.
        trap : INT
        show
        while read -r -n 1 -p "[r]efresh [w]atch [l]ogs [o]pen [q]uit: " key; do
          echo
          case $key in
            r) show || true ;;
            w)
              if pick_workflow; then
                read -r host ns name <<< "$picked"
                argo_at "$host" watch "$name" -n "$ns" || true
              fi
              ;;
            l) logs ;;
            o) open_ui ;;
            q) break ;;
          esac
        done
      '';
    }
  );

  # What Argo CD and Kargo do with the repo in the current directory: `pr-deploy 42`.
  # Read-only: no sync, no promotion. Argo CD apps are the ones whose source is this
  # repo (or an OCI chart named like it); a repo with more than 20 (drift-warden has
  # over a hundred) is narrowed to the apps whose path or value files the PR touches,
  # diffed against the PR's own base branch. Apps on this repo's OCI chart are kept:
  # their impact is unknown.
  # Kargo shows the project named like the repo, if there is one. Both CLIs use
  # their own SSO logins.
  ".local/bin/pr-deploy".source = pkgs.lib.getExe (
    pkgs.writeShellApplication {
      name = "pr-deploy";
      # The jq programs are single-quoted on purpose: their $names are jq's.
      excludeShellChecks = [ "SC2016" ];
      runtimeInputs = [
        pkgs.git
        pkgs.tea
        pkgs.gh
        pkgs.jq
        pkgs.gnugrep
        pkgs.argocd
        pkgs.kargo
      ];
      derivationArgs.fixtures = prToolsFixtures;
      text = ''
        if ! [[ ''${1:-} =~ ^[0-9]+$ ]]; then
          echo "usage: pr-deploy <pr-number>  (in a checkout of the PR's repo)" >&2
          exit 2
        fi
        pr=$1
        remote=$(git remote get-url origin)
        defs=${pkgs.lib.escapeShellArg jqHelpers}
        repo_id=$(jq -rn --arg u "$remote" "$defs"' $u | norm')
        repo=''${repo_id##*/}

        # Sources of an app, and whether one comes from this repo.
        apps_defs=${pkgs.lib.escapeShellArg argoAppsJq}

        # Sets files to the JSON list of paths the PR changes against its base branch,
        # or why_not to the reason it cannot. Base and head are fetched into refs of
        # their own: with two refs, FETCH_HEAD holds only the first.
        pr_files() {
          local base out refs=refs/pr-deploy/$pr
          case $remote in
            *codeberg.org*) base=$(tea pulls "$pr" -o json 2> /dev/null | jq -r '.base // empty') || base= ;;
            *github.com*) base=$(gh pr view "$pr" --json baseRefName -q .baseRefName 2> /dev/null) || base= ;;
            *) base= ;;
          esac
          if [ -z "$base" ]; then
            why_not="could not look up the PR's base branch"
            return 1
          fi
          if ! out=$(git fetch --quiet --no-tags origin "+refs/heads/$base:$refs/base" "+refs/pull/$pr/head:$refs/head" 2>&1); then
            why_not="could not fetch $base and the PR head: ''${out//$'\n'/ }"
            return 1
          fi
          # --no-renames: a moved file counts for the app it left and the one it joined.
          if ! out=$(git diff --no-renames --name-only "$refs/base...$refs/head" 2>&1); then
            why_not="git diff $base...PR head failed: ''${out//$'\n'/ }"
            git update-ref -d "$refs/base" || true
            git update-ref -d "$refs/head" || true
            return 1
          fi
          git update-ref -d "$refs/base" || true
          git update-ref -d "$refs/head" || true
          files=$(jq -Rsc 'split("\n") | map(select(. != ""))' <<< "$out")
        }

        # Sets apps: this repo's Argo CD apps (narrowed to the PR when there are many),
        # OutOfSync/Degraded first.
        load_apps() {
          local all total files why_not kept
          apps="[]"
          if ! all=$(argocd app list -o json 2>&1); then
            echo "argocd: $all" >&2
            return 1
          fi
          all=$(jq --arg id "$repo_id" --arg repo "$repo" "$apps_defs"' [.[] | select(any(srcs[]; from_repo))]' <<< "$all")
          total=$(jq length <<< "$all")
          if [ "$total" -gt 20 ]; then
            if pr_files; then
              kept=$(jq --arg id "$repo_id" --arg repo "$repo" --argjson files "$files" "$apps_defs"' [.[] | select((touched($files) | not) and impact_unknown)] | length' <<< "$all")
              all=$(jq --arg id "$repo_id" --arg repo "$repo" --argjson files "$files" "$apps_defs"' [.[] | select(touched($files) or impact_unknown)]' <<< "$all")
              echo "Argo CD: $total apps from this repo, $(($(jq length <<< "$all") - kept)) touched by this PR, $kept kept: OCI chart, impact unknown ($(jq length <<< "$files") files changed)"
            else
              echo "Argo CD: $total apps from this repo, not narrowed to the PR: $why_not"
            fi
          else
            echo "Argo CD: $total apps from this repo"
          fi
          apps=$(jq --arg id "$repo_id" --arg repo "$repo" "$apps_defs"' sort_by([(.status.sync.status == "OutOfSync" or .status.health.status == "Degraded" | not), .metadata.name])' <<< "$all")
        }

        show_apps() {
          load_apps || return 0
          [ "$(jq length <<< "$apps")" -gt 0 ] || return 0
          jq -r --arg id "$repo_id" --arg repo "$repo" "$apps_defs"'
            [["#", "APP", "SYNC", "HEALTH", "REVISION", "LAST OPERATION"]]
            + [to_entries[] | .key as $k | .value | [
                ($k + 1 | tostring),
                .metadata.name,
                (.status.sync.status // "-"),
                (.status.health.status // "-"),
                rev,
                (.status.operationState.finishedAt // "-")
              ]]
            | table' <<< "$apps"
        }

        show_kargo() {
          local out stages freight
          echo
          if ! out=$(kargo get project "$repo" 2>&1); then
            if grep -q 'not found' <<< "$out"; then
              echo "Kargo: no project named $repo"
            else
              echo "kargo: $out" >&2
            fi
            return 0
          fi
          stages=$(kargo get stages --project "$repo" -o json) || return 0
          freight=$(kargo get freight --project "$repo" -o json) || return 0
          echo "Kargo: project $repo"
          jq -r --argjson freight "$freight" "$defs"'
            ([$freight.items[]? | {key: .metadata.name, value: (.alias // .metadata.name[0:7])}] | from_entries) as $alias
            | [["STAGE", "FREIGHT", "HEALTH", "PHASE"]]
              + [.items[]? | [
                  .metadata.name,
                  ([(.status.freightHistory[0].items // {})[] | $alias[.name] // .name[0:7]] | join(",") | if . == "" then "-" else . end),
                  (.status.health.status // "-"),
                  (.status.phase // ([.status.conditions[]? | select(.type == "Ready") | .reason][0]) // "-")
                ]]
            | table' <<< "$stages"
          jq -r '
            [.items[]?] | sort_by(.metadata.creationTimestamp) | last // empty
            | "newest freight: \(.alias // "-") (\(.metadata.name[0:7])), created \(.metadata.creationTimestamp)",
              ([(.images // [])[] | "  image \(.repoURL):\(.tag)"],
               [(.commits // [])[] | "  commit \(.repoURL)@\((.id // .tag // "-")[0:7])"],
               [(.charts // [])[] | "  chart \(.repoURL) \(.name // "") \(.version)"]
               | .[]),
              "  in: \((.status.currentlyIn // {}) | keys | join(", ") | if . == "" then "no stage" else . end)"
          ' <<< "$freight"
        }

        show() {
          echo "PR #$pr, repo $repo_id"
          show_apps
          show_kargo
        }

        show
        while read -r -n 1 -p "[r]efresh [a]rgocd app get [q]uit: " key; do
          echo
          case $key in
            r) show ;;
            a)
              read -r -p "app #: " n || continue
              app=$(jq -r --arg n "$n" '($n | tonumber? // 0) as $i | if $i >= 1 then .[$i - 1] // empty | (if (.metadata.namespace // "argocd") == "argocd" then "" else .metadata.namespace + "/" end) + .metadata.name else empty end' <<< "$apps")
              if [ -n "$app" ]; then
                argocd app get "$app" || true
              else
                echo "no app #$n"
              fi
              ;;
            q) break ;;
          esac
        done
      '';
    }
  );

  # workmux — shared settings. The binary is installed by hand with
  # `nix profile install github:raine/workmux` (no package or overlay here, so a
  # fresh machine needs that one command), only the config is declarative. Per-repo overrides
  # stay in <repo>/.workmux.yaml.
  ".config/workmux/config.yaml".text = ''
    # workmux — global configuration.
    # Per-repo overrides: <repo>/.workmux.yaml (pattern: content-ops).

    nerdfont: true

    #-------------------------------------------------------------------------------
    # Paths and naming
    #-------------------------------------------------------------------------------

    # One worktree location for every repo. Without this, drift-warden scattered 28
    # worktrees across ~/.worktrees/, ~/dev/worktrees/ and the repo directory itself —
    # every change of convention left sediment, because the default sibling directory
    # applied. {project} keeps repositories apart.
    worktree_dir: ~/dev/worktrees/{project}

    # Branches are named fix/..., feat/..., docs/... — basename gives flat directories
    # and readable session names instead of nesting. Same as content-ops.
    worktree_naming: basename

    # 30 repositories, and agents are addressed as project:handle. The tmux session
    # name has to say which repo it belongs to. content-ops overrides this with "co-".
    window_prefix: "{project}-"

    #-------------------------------------------------------------------------------
    # Git
    #-------------------------------------------------------------------------------

    base_branch: auto

    # 28 unmerged branches in drift-warden alone. The confirmation before removing an
    # unmerged branch stays on deliberately, not by accident.
    confirm_unmerged_removal: true

    #-------------------------------------------------------------------------------
    # Tmux
    #-------------------------------------------------------------------------------

    # One session per worktree. Required by `windows:` blocks and consistent with content-ops.
    mode: session

    #-------------------------------------------------------------------------------
    # Agents
    #-------------------------------------------------------------------------------

    agent: claude

    # The default timeout is too short: this repo's build-switch alone took 50 minutes,
    # and an agent working longer than an hour is not abandoned.
    stale_after: 2h

    status_icons:
      working: "🤖"
      waiting: "💬"
      done: "✅"

    #-------------------------------------------------------------------------------
    # Hooks
    #-------------------------------------------------------------------------------

    # Fresh fetch on every new worktree — the "stale clone" class of bug stops being
    # something to remember. `|| true` is required: post_create blocks window creation,
    # so a failed fetch would break `workmux add`. speedway has a remote pointing at a
    # repo that does not exist on Codeberg yet, and the fetch there returns
    # "Cannot find repository" — a real case, not a theoretical one.
    post_create:
      - git fetch --prune origin || true

    #-------------------------------------------------------------------------------
    # Dashboard
    #-------------------------------------------------------------------------------

    dashboard:
      sort_mode: priority
      preview_size: 60
      commit: "Commit staged changes with a descriptive message"
      merge: "!workmux merge"

    #-------------------------------------------------------------------------------
    # Sidebar
    #-------------------------------------------------------------------------------

    sidebar:
      position: left
      layout: tiles
      # Grouping by project only pays off with many repos — and there are 30.
      group_by: project
      collapse_stale: true

    #-------------------------------------------------------------------------------
    # Named pane layouts (selected with `workmux add -l <name>`)
    #-------------------------------------------------------------------------------

    # Status hooks are installed for every agent CLI (~/.claude/settings.json,
    # ~/.codex/hooks.json, ~/.pi/agent/extensions/workmux-status.ts), so each reports
    # 🤖/💬/✅ to the dashboard and sidebar.
    #
    # Note: `-l` replaces `panes` and does NOT combine with `--agent`. They are separate modes:
    #   workmux add X -l duel          -> one worktree, two models on shared files
    #   workmux add X -a claude,codex  -> two worktrees, a separate branch per model
    layouts:
      # One worktree, Claude and Codex side by side. They share the same working tree,
      # so this is a "one writes, the other reads/reviews" layout, not for parallel editing.
      duel:
        panes:
          - command: <agent>
            focus: true
          - command: <agent:codex>
            split: vertical

      # PR review: pi (default model in ~/.pi/agent/settings.json) orchestrates the
      # pi-subagents reviewers — reviewer-openai always, reviewer-ollama when the user
      # says yes. Each writes .workmux/review-<model>.md and `agent-review-post` posts
      # it. `pi` must stay a literal command: that is how workmux recognises it and
      # injects the pr-review prompt. pi asks for no approvals; only the prompt keeps
      # the reviewers from editing the worktree.
      # The subagents live inside pi; pi-agent-pane gives each one a pane with its
      # transcript and a sidebar/dashboard entry. A reviewer pi does not start just
      # waits and never registers.
      # Repos with their own `review` in .workmux.yaml (drift-warden, metanol) override it.
      review:
        panes:
          - command: pi
            focus: true
          - command: pi-agent-pane reviewer-openai
            split: horizontal
          - command: pi-agent-pane reviewer-ollama
            split: vertical

      # Agent plus a free shell for manual checks (tests, logs, git).
      solo:
        panes:
          - command: <agent>
            focus: true
          - split: horizontal
            size: 20
  '';

  # pi — Ollama on the LAN box. Only models.json is declarative: pi rewrites
  # settings.json itself (default model, packages), so that stays mutable.
  # Ollama ignores the API key; pi just needs a non-empty one to list the models.
  ".pi/agent/models.json".text = builtins.toJSON {
    providers.ollama = {
      baseUrl = "${ollamaUrl}/v1";
      api = "openai-completions";
      apiKey = "ollama";
      # The *-32k variants live on the Ollama host (created via /api/create with
      # parameters.num_ctx = 32768); /v1 ignores num_ctx per request, so the
      # context has to be baked into the model. contextWindow must match it:
      # pi assumes 128k and 16k output when unset, so it never compacts and
      # Ollama cuts the reply with finish_reason "length". Thinking tokens count
      # against maxTokens, hence the larger budget for the reasoning models.
      models = [
        { id = "qwen3.8:27b-32k"; reasoning = true; contextWindow = 32768; maxTokens = 24576; }
        { id = "deepseek-r1:32b-32k"; reasoning = true; contextWindow = 32768; maxTokens = 24576; }
        { id = "devstral:24b-32k"; contextWindow = 32768; maxTokens = 16384; }
        { id = "qwen3-coder:30b-32k"; contextWindow = 32768; maxTokens = 16384; }
      ];
    };
  };

  # Catppuccin Macchiato for pi, from the pi-catppuccin npm package (schema
  # matches pi's theme-schema.json). Selected via "theme" in the mutable
  # settings.json (or /settings).
  ".pi/agent/themes/catppuccin-macchiato.json".source = "${pkgs.fetchzip {
    url = "https://registry.npmjs.org/@sherif-fanous/pi-catppuccin/-/pi-catppuccin-0.3.0.tgz";
    hash = "sha256-bQcwdIkvftARigfQ3WnimdONBu+ubx4UnXmqFzHxiVA=";
  }}/themes/catppuccin-macchiato.json";

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
  ".config/mcp/mcp.json".text = builtins.toJSON {
    mcpServers = {
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
        args = [ "ha-mcp==8.7.0" ];
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
    };
  };

  # pi-subagents reviewers for pr-review (piReviewer above). gpt-6-astra is the top
  # OpenAI tier pi lists (ChatGPT OAuth). On the Ollama box the speed is set by VRAM
  # (~10 GB): the dense qwen3.8:27b reasons better but spills half of its 19.8 GB to
  # the CPU, and a review of a 180-line diff ran past 78 minutes without finishing.
  # qwen3-coder:30b is a MoE with ~3B active parameters that fits in VRAM: a warm
  # tool call takes ~5 s. It does not reason, hence thinking off.
  # Symlinks into the store, so `/agents` in pi shows them but cannot edit them.
  ".pi/agent/agents/reviewer-openai.md".text = piReviewer {
    model = "openai/gpt-6-astra";
    label = "gpt-6-astra";
    thinking = "high";
    maxTurns = 60;
  };
  ".pi/agent/agents/reviewer-ollama.md".text = piReviewer {
    model = "ollama/${ollamaReviewModel}";
    label = "qwen3-coder-30b";
    thinking = "off";
    maxTurns = 15;
  };

  # Cheap general-purpose subagents, on the Claude subscription. Always a full
  # claude-bridge/<id>: a bare "sonnet" resolves to the pay-per-use anthropic provider,
  # and ChatGPT OAuth rejects the mini OpenAI models. Descriptions stay double-quoted
  # (see piReviewer). Not `isolated`: that loads no extensions, and pi-claude-bridge
  # refuses a subagent whose system prompt its own before_agent_start hook never
  # recorded ("prompt-capture: no capture for this ... system prompt"). So load the
  # bridge alone, which keeps MCP and skills out just the same.
  ".pi/agent/agents/scout.md".text = ''
    ---
    description: "Fast read-only search: find files, grep symbols, answer where X is defined; returns paths and short excerpts"
    model: claude-bridge/claude-haiku-4-5
    thinking: off
    tools: read, bash, grep, find, ls
    extensions: [pi-claude-bridge]
    skills: false
    max_turns: 20
    ---
    You search a codebase and report what you find. You are read-only: never edit,
    create, delete or move a file, and never run a command that changes state.

    Answer the question in the task, nothing more. Report each hit as file:line with a
    short excerpt. Be concise: no preamble, no recap of the task.
  '';
  ".pi/agent/agents/worker.md".text = ''
    ---
    description: "Implements a well-specified change: edits, docs, mechanical refactors, running checks"
    model: claude-bridge/claude-sonnet-5-5
    thinking: low
    tools: read, bash, grep, find, ls, edit, write
    extensions: [pi-claude-bridge]
    skills: false
    ---
    You implement one well-specified change. Do exactly the task, and touch only the
    paths it names. Do not commit, push or post anything to a forge unless the task
    says so. Match the style of the surrounding code.

    End with a short report: what changed (files) and what you verified (commands and
    their result).
  '';

  # Global context for every pi session: keeps the main (Opus) session cheap by
  # pushing search and well-specified edits down to the subagents above.
  ".pi/agent/AGENTS.md".text = ''
    # Delegation

    Keep the main context and its cost low by delegating:

    - `scout` for searching and reading (find files, grep symbols, where is X defined).
    - `worker` for well-specified edits, docs and running checks.
    - Keep design decisions, integration and the final verification in the main session.
    - Launch independent subagents in parallel.

    # Models

    When you override a subagent's model, always give a full `claude-bridge/<id>` id.
    Never a bare name such as "sonnet" or "haiku": it resolves to the paid `anthropic`
    provider. Bridge models: `claude-haiku-4-5`, `claude-sonnet-5-5`, `claude-opus-5-5`.
    OpenAI via ChatGPT accepts only the top tiers (`gpt-6-*`), not the mini models.

    # Panes

    Every subagent gets its own tmux pane and workmux sidebar entry automatically
    (subagents-workmux.ts). Set `PI_AGENT_PANES=0` to turn that off.
  '';

  # pi-subagents run inside the pi process, so workmux (which tracks panes) never
  # sees them. This bridges them out:
  # - `suba:activity` is what workmux-status.ts (from `workmux setup`) counts to keep
  #   pi at working while background agents run. pi-subagents does not emit it, so
  #   without this pi showed done while its reviewers were still going.
  # - .workmux/agents/<type>.json is what the layout's `pi-agent-pane <type>` follows
  #   (the review layout pre-creates one per reviewer).
  # - .workmux/agents/by-id/<id>.json carries the same payload plus the type. Every
  #   other subagent, in any pi session inside tmux, gets a pane of its own that
  #   follows it (`pi-agent-pane --id`), opened here on start. No pane when: there is
  #   no tmux, pi has no UI (`pi -p`, e.g. dw-review --quick), PI_AGENT_PANES=0, or a
  #   layout pane already follows that type (its pid in .workmux/agents/<type>.pane).
  ".pi/agent/extensions/subagents-workmux.ts".text = ''
    import { execFileSync } from "node:child_process";
    import { mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
    import { join } from "node:path";
    import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

    type Lifecycle = { id?: unknown; type?: unknown };

    export default function (pi: ExtensionAPI) {
      const running = new Set<string>();
      let cwd: string | undefined;
      let hasUI = false;
      // Most recent dynamic pane; the next one is split off it, so they stack.
      let lastPane: string | undefined;

      const publish = () => pi.events.emit("suba:activity", { activeCount: running.size });

      function write(file: string, payload: object) {
        writeFileSync(`''${file}.tmp`, JSON.stringify(payload));
        renameSync(`''${file}.tmp`, file);
      }

      function record(data: Lifecycle, status: string) {
        if (!cwd || typeof data.id !== "string" || typeof data.type !== "string") return;
        if (!/^[\w.-]+$/.test(data.type) || !/^[\w.-]+$/.test(data.id)) return;
        const manager = (globalThis as any)[Symbol.for("pi-subagents:manager")];
        const rec = manager?.getRecord?.(data.id);
        const payload = {
          id: data.id,
          status,
          outputFile: rec?.outputFile,
          updated: Date.now(),
        };
        try {
          const dir = join(cwd, ".workmux", "agents");
          mkdirSync(join(dir, "by-id"), { recursive: true });
          write(join(dir, `''${data.type}.json`), payload);
          write(join(dir, "by-id", `''${data.id}.json`), { ...payload, type: data.type });
        } catch {
          // A read-only or vanished worktree must not break the session.
        }
      }

      // A layout pane (`pi-agent-pane <type>`) is alive while its claim file holds a live pid.
      function claimed(type: string): boolean {
        try {
          const pid = parseInt(readFileSync(join(cwd!, ".workmux", "agents", `''${type}.pane`), "utf8"), 10);
          if (!pid) return false;
          process.kill(pid, 0);
          return true;
        } catch {
          return false;
        }
      }

      function tmux(...args: string[]): string {
        return execFileSync("tmux", args, { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
      }

      function openPane(data: Lifecycle) {
        const origin = process.env.TMUX_PANE;
        if (!origin || !hasUI || !cwd || process.env.PI_AGENT_PANES === "0") return;
        if (typeof data.id !== "string" || typeof data.type !== "string") return;
        if (!/^[\w.-]+$/.test(data.id) || !/^[\w.-]+$/.test(data.type)) return;
        if (claimed(data.type)) return;
        try {
          let below: string | undefined;
          if (lastPane) {
            try {
              below = tmux("display", "-p", "-t", lastPane, "#{pane_id}");
            } catch {
              // The previous pane has closed; start a new column instead.
            }
          }
          const place = below ? ["-v", "-t", below] : ["-h", "-l", "40%", "-t", origin];
          lastPane = tmux(
            "split-window", "-d", ...place, "-P", "-F", "#{pane_id}", "-c", cwd,
            "pi-agent-pane", "--id", data.id,
          );
        } catch {
          // No tmux server, no room for a split: the subagent still runs.
        }
      }

      function on(event: string, status: string, active: boolean) {
        pi.events.on(event, (data) => {
          const d = (data ?? {}) as Lifecycle;
          if (typeof d.id !== "string") return;
          if (active) running.add(d.id);
          else running.delete(d.id);
          record(d, status);
          if (event === "subagents:started") openPane(d);
          publish();
        });
      }

      pi.on("session_start", async (_event, ctx) => {
        cwd = ctx.cwd;
        hasUI = ctx.hasUI;
        lastPane = undefined;
        running.clear();
      });
      // workmux-status asks once it has subscribed, in case agents already run.
      pi.events.on("suba:activity:request", publish);
      on("subagents:started", "working", true);
      on("subagents:completed", "done", false);
      on("subagents:failed", "failed", false);
    }
  '';

  # One pane per subagent. Two modes:
  # - `pi-agent-pane <type>` (the `review` layout, one per reviewer) waits for pi to
  #   start that type and follows .workmux/agents/<type>.json. It claims the type
  #   (.workmux/agents/<type>.pane, its pid) so the extension does not open a second
  #   pane for the same reviewer.
  # - `pi-agent-pane --id <id>` (opened by the extension for every other subagent)
  #   follows .workmux/agents/by-id/<id>.json, is named after its `type`, registers
  #   at once, and closes as soon as the run succeeds. A failed or stopped run keeps
  #   the pane PI_AGENT_PANE_LINGER seconds (default 30), long enough to read why.
  # Either way it mirrors the agent's status (sidebar, dashboard) and its transcript.
  # It has to be one long-lived process: workmux forgets an agent whose pane changes
  # its foreground command.
  ".local/bin/pi-agent-pane".source = pkgs.lib.getExe (
    pkgs.writers.writePython3Bin "pi-agent-pane" { flakeIgnore = [ "E501" ]; } ''
      import atexit
      import glob
      import json
      import os
      import re
      import signal
      import subprocess
      import sys
      import tempfile
      import time

      DIM, BOLD, RED, GREEN, OFF = "\033[2m", "\033[1m", "\033[31m", "\033[32m", "\033[0m"
      USAGE = "usage: pi-agent-pane <subagent-type> | --id <run-id>"

      args = sys.argv[1:]
      by_id = len(args) == 2 and args[0] == "--id"
      name = args[-1] if by_id or len(args) == 1 else sys.exit(USAGE)
      if not re.fullmatch(r"[\w.-]+", name):
          sys.exit(USAGE)
      # An --id pane starts in pi's cwd (split-window -c), which is where the extension
      # writes; a layout pane starts at the worktree root.
      git = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True)
      root = os.getcwd() if by_id else (git.stdout.strip() or os.getcwd())
      agents_dir = os.path.join(root, ".workmux", "agents")
      state_file = os.path.join(agents_dir, "by-id", f"{name}.json") if by_id else os.path.join(agents_dir, f"{name}.json")
      try:
          linger = int(os.environ.get("PI_AGENT_PANE_LINGER", "30"))
      except ValueError:
          linger = 30


      def workmux(*args):
          subprocess.run(["workmux", *args], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


      def title(text):
          sys.stdout.write(f"\033]2;{text}\033\\")
          sys.stdout.flush()


      def transcript(state, agent_id):
          path = state.get("outputFile")
          if path and os.path.exists(path):
              return path
          # pi-subagents' layout: <tmp>/pi-subagents-<uid>/<cwd, / -> ->/<session>/tasks/<id>.output
          cwd = root.replace("/", "-").lstrip("-")
          base = os.path.join(tempfile.gettempdir(), f"pi-subagents-{os.getuid()}", cwd)
          found = glob.glob(os.path.join(glob.escape(base), "*", "tasks", f"{glob.escape(agent_id)}.output"))
          return found[0] if found else None


      def clip(text, width=200):
          text = " ".join(str(text).split())
          return text if len(text) <= width else text[: width - 1] + "…"


      def render(line):
          try:
              message = json.loads(line).get("message") or {}
          except json.JSONDecodeError:
              return
          role, content = message.get("role"), message.get("content")
          blocks = content if isinstance(content, list) else [{"type": "text", "text": content or ""}]
          for block in blocks:
              kind = block.get("type")
              if role == "assistant" and kind == "text" and block.get("text", "").strip():
                  print(block["text"].strip())
              elif role == "assistant" and kind == "toolCall":
                  args = block.get("arguments") or {}
                  shown = args.get("command") or args.get("path") or json.dumps(args)
                  print(f"{BOLD}› {block.get('name')}{OFF} {clip(shown)}")
              elif role == "toolResult" and kind == "text":
                  colour = RED if message.get("isError") else DIM
                  print(f"{colour}  {clip(block.get('text', '''), 160)}{OFF}")
              elif role == "user" and kind == "text":
                  print(f"{DIM}task: {clip(block.get('text', '''), 400)}{OFF}")
          sys.stdout.flush()


      def claim():
          path = os.path.join(agents_dir, f"{name}.pane")
          os.makedirs(agents_dir, exist_ok=True)
          with open(path, "w") as f:
              f.write(str(os.getpid()))

          def release():
              try:
                  with open(path) as f:
                      mine = f.read().strip() == str(os.getpid())
                  if mine:
                      os.remove(path)
              except OSError:
                  pass

          def stop(*_):
              sys.exit(0)

          atexit.register(release)
          signal.signal(signal.SIGTERM, stop)
          signal.signal(signal.SIGHUP, stop)


      def follow():
          label = name
          title(f"{label} · idle")
          registered, current, path, offset, buffer, shown_status = False, None, None, 0, "", None
          started, finished = time.time(), None
          if by_id:
              print(f"{DIM}{name}: starting{OFF}", flush=True)
              workmux("register-agent")
              registered = True
          else:
              print(f"{DIM}{name}: waiting for pi to start it{OFF}", flush=True)
          while True:
              try:
                  with open(state_file) as f:
                      state = json.load(f)
              except (OSError, json.JSONDecodeError):
                  state = None
              if state and by_id and state.get("type"):
                  label = state["type"]
              if state and state.get("id") != current:
                  current, path, offset, buffer, shown_status = state["id"], None, 0, "", None
                  print(f"\n{BOLD}── {label} run {current}{OFF}", flush=True)
                  if not registered:
                      workmux("register-agent")
                      registered = True
              if state:
                  path = path or transcript(state, current)
                  if path:
                      try:
                          with open(path) as f:
                              f.seek(offset)
                              chunk = f.read()
                              offset = f.tell()
                      except OSError:
                          chunk = ""
                      buffer += chunk
                      *lines, buffer = buffer.split("\n")
                      for line in lines:
                          render(line)
                  status = state.get("status")
                  if status != shown_status:
                      shown_status = status
                      workmux("set-window-status", "working" if status == "working" else "done")
                      title(f"{label} · {status}")
                      if status == "done":
                          print(f"{GREEN}── {label} done{OFF}", flush=True)
                      elif status == "failed":
                          print(f"{RED}── {label} failed or was stopped{OFF}", flush=True)
                      if by_id and status == "done":
                          return
                      if by_id and status == "failed":
                          finished = time.time()
                          closes = time.strftime("%H:%M:%S", time.localtime(finished + linger))
                          print(f"{DIM}pane closes at {closes} (PI_AGENT_PANE_LINGER={linger}s){OFF}", flush=True)
                      elif status == "working":
                          finished = None
              if by_id:
                  now = time.time()
                  # A run that never wrote its state would otherwise leave the pane for good.
                  if finished and now - finished >= linger or not state and now - started >= linger:
                      return
              time.sleep(1)


      if not by_id:
          claim()
      follow()
    ''
  );

}
