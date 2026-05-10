{
  alias = {
    metadata = {
      name = "alias";
      description = "A channel to select from shell aliases";
    };
    source = {
      command = "$SHELL -ic 'alias'";
      output = "{split:=:0}";
    };
    preview = {
      command = "$SHELL -ic 'alias' | grep -E '^(alias )?{split:=:0}='";
    };
    ui = {
      preview_panel = {
        size = 30;
      };
    };
  };

  "aws-buckets" = {
    metadata = {
      name = "aws-buckets";
      description = "List and preview AWS S3 Buckets";
      requirements = [ "aws" ];
    };
    source = {
      command = "aws s3 ls --output text";
      output = "{split: :3|trim}";
    };
    preview = {
      command = "aws s3 ls s3://{split: :3|trim} --human-readable --summarize";
    };
    ui = {
      layout = "portrait";
      preview_panel = {
        size = 60;
      };
    };
    actions = {
      list = {
        description = "List all objects in the selected bucket";
        command = "aws s3 ls s3://{split: :3|trim} --recursive --human-readable | less";
        mode = "execute";
      };
    };
  };

  "aws-instances" = {
    metadata = {
      name = "aws-instances";
      description = "List and preview AWS EC2 Instances";
      requirements = [ "aws" ];
    };
    source = {
      command = "aws ec2 describe-instances --output text --query \"Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name']|[0].Value]\"";
    };
    preview = {
      command = "aws ec2 describe-instances --output json --instance-ids {split:	:0} --query 'Reservations[*].Instances[0]'";
    };
    ui = {
      layout = "portrait";
      preview_panel = {
        size = 60;
      };
    };
    actions = {
      start = {
        description = "Start the selected EC2 instance";
        command = "aws ec2 start-instances --instance-ids {split:	:0}";
        mode = "fork";
      };
      stop = {
        description = "Stop the selected EC2 instance";
        command = "aws ec2 stop-instances --instance-ids {split:	:0}";
        mode = "fork";
      };
      ssm = {
        description = "Start an SSM session on the selected instance";
        command = "aws ssm start-session --target {split:	:0}";
        mode = "execute";
      };
    };
  };

  "aws-profiles" = {
    metadata = {
      name = "aws-profiles";
      description = "List and switch AWS CLI profiles";
      requirements = [ "aws" "grep" "nu" ];
    };
    source = {
      command = "grep '\\[profile' ~/.aws/config | sed 's/\\[profile //' | sed 's/\\]//'";
    };
    preview = {
      command = "aws configure list --profile '{}'";
    };
    keybindings = {
      enter = "actions:export";
    };
    actions = {
      export = {
        description = "Export the selected profile (sets AWS_PROFILE)";
        command = "^sh -c 'export AWS_PROFILE=\"{}\"; echo AWS_PROFILE set to {}; exec $SHELL'";
        mode = "execute";
      };
    };
  };

  "bash-history" = {
    metadata = {
      name = "bash-history";
      description = "A channel to select from your bash history";
      requirements = [ "bash" ];
    };
    source = {
      command = "sed '1!G;h;$!d' \${HISTFILE:-\${HOME}/.bash_history}";
      no_sort = true;
      frecency = false;
    };
  };

  "brew-packages" = {
    metadata = {
      name = "brew-packages";
      description = "List and manage Homebrew packages";
      requirements = [ "brew" ];
    };
    source = {
      command = [ "brew list --formula" "brew list --cask" ];
    };
    preview = {
      command = "brew info '{}'";
    };
    ui = {
      layout = "portrait";
    };
    keybindings = {
      "ctrl-u" = "actions:upgrade";
      "ctrl-d" = "actions:uninstall";
    };
    actions = {
      upgrade = {
        description = "Upgrade the selected package";
        command = "brew upgrade '{}'";
        mode = "execute";
      };
      uninstall = {
        description = "Uninstall the selected package";
        command = "brew uninstall '{}'";
        mode = "execute";
      };
    };
  };

  "cargo-commands" = {
    metadata = {
      name = "cargo-commands";
      description = "List available cargo commands and extensions";
      requirements = [ "cargo" ];
    };
    source = {
      command = "cargo --list 2>/dev/null | tail -n +2 | awk '{print $1}'";
    };
    preview = {
      command = "cargo {} --help 2>/dev/null | head -50";
    };
    ui = {
      layout = "portrait";
      preview_panel = {
        size = 60;
      };
    };
    keybindings = {
      enter = "actions:run";
    };
    actions = {
      run = {
        description = "Run the selected cargo command";
        command = "cargo '{}'";
        mode = "execute";
      };
    };
  };

  "cargo-crates" = {
    metadata = {
      name = "cargo-crates";
      description = "List installed cargo crates";
      requirements = [ "cargo" ];
    };
    source = {
      command = "cargo install --list 2>/dev/null | grep -v '^    ' | sed 's/:$//'";
      display = "{split: :0} {split: :1}";
      output = "{split: :0}";
    };
    preview = {
      command = "cargo install --list 2>/dev/null | sed -n '/^{split: :0} /,/^[^ ]/p' | head -20";
    };
    actions = {
      uninstall = {
        description = "Uninstall the selected crate";
        command = "cargo uninstall '{split: :0}'";
        mode = "execute";
      };
    };
  };

  channels = {
    metadata = {
      name = "channels";
      description = "A channel to find and select other channels";
    };
    source = {
      command = "tv list-channels";
    };
    keybindings = {
      enter = "actions:zap";
    };
    actions = {
      zap = {
        description = "Switch to the channel";
        command = "tv '{}'";
        mode = "execute";
      };
    };
  };

  crontab = {
    metadata = {
      name = "crontab";
      description = "List and manage crontab entries";
    };
    source = {
      command = "crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$'";
      no_sort = true;
      frecency = false;
    };
    preview = {
      command = "echo 'Schedule: {split: :..5}' && echo '' && echo 'Command:' && echo '{split: :5..}' ";
    };
    ui = {
      layout = "portrait";
      preview_panel = {
        size = 30;
      };
    };
    actions = {
      edit = {
        description = "Open crontab for editing";
        command = "crontab -e";
        mode = "execute";
      };
    };
  };

  dirs = {
    metadata = {
      name = "dirs";
      description = "A channel to select from directories";
      requirements = [ "fd" ];
    };
    source = {
      command = [ "fd -t d" "fd -t d --hidden" ];
    };
    preview = {
      command = "eza -la --color=always '{}'";
    };
    keybindings = {
      shortcut = "f2";
    };
    actions = {
      cd = {
        description = "Open a shell in the selected directory";
        command = "cd '{}' && $SHELL";
        mode = "execute";
      };
      goto_parent_dir = {
        description = "Re-opens tv in the parent directory";
        command = "tv dirs ..";
        mode = "execute";
      };
    };
  };

  "docker-compose" = {
    metadata = {
      name = "docker-compose";
      description = "Manage Docker Compose services";
      requirements = [ "docker" ];
    };
    source = {
      command = "docker compose ps --format '{{.Name}}	{{.Service}}	{{.Status}}'";
      display = "{split:	:1} ({split:	:2})";
      output = "{split:	:1}";
    };
    preview = {
      command = "docker compose logs --tail=30 --no-log-prefix '{split:	:1}'";
    };
    actions = {
      up = {
        description = "Start the selected service";
        command = "docker compose up -d '{split:	:1}'";
        mode = "fork";
      };
      down = {
        description = "Stop and remove the selected service";
        command = "docker compose down '{split:	:1}'";
        mode = "fork";
      };
      restart = {
        description = "Restart the selected service";
        command = "docker compose restart '{split:	:1}'";
        mode = "fork";
      };
      logs = {
        description = "Follow logs of the selected service";
        command = "docker compose logs -f '{split:	:1}'";
        mode = "execute";
      };
    };
  };

  "docker-containers" = {
    metadata = {
      name = "docker-containers";
      description = "List and manage Docker containers";
      requirements = [ "docker" "jq" ];
    };
    source = {
      command = [ "docker ps --format '{{.Names}}\\t{{.Image}}\\t{{.Status}}'" "docker ps -a --format '{{.Names}}\\t{{.Image}}\\t{{.Status}}'" ];
      display = "{split:\\t:0} ({split:\\t:2})";
      output = "{split:\\t:0}";
    };
    preview = {
      command = "docker inspect '{split:\\t:0}' | jq -C '.[0] | {Name, State, Config: {Image: .Config.Image, Cmd: .Config.Cmd}, NetworkSettings: {IPAddress: .NetworkSettings.IPAddress}}'";
    };
    ui = {
      layout = "portrait";
    };
    keybindings = {
      "ctrl-s" = "actions:start";
      f2 = "actions:stop";
      "ctrl-r" = "actions:restart";
      "ctrl-l" = "actions:logs";
      "ctrl-e" = "actions:exec";
      "ctrl-d" = "actions:remove";
    };
    actions = {
      start = {
        description = "Start the selected container";
        command = "docker start '{split:\\t:0}'";
        mode = "fork";
      };
      stop = {
        description = "Stop the selected container";
        command = "docker stop '{split:\\t:0}'";
        mode = "fork";
      };
      restart = {
        description = "Restart the selected container";
        command = "docker restart '{split:\\t:0}'";
        mode = "fork";
      };
      logs = {
        description = "Follow logs of the selected container";
        command = "docker logs -f '{split:\\t:0}'";
        mode = "execute";
      };
      exec = {
        description = "Execute shell in the selected container";
        command = "docker exec -it '{split:\\t:0}' /bin/sh";
        mode = "execute";
      };
      remove = {
        description = "Remove the selected container";
        command = "docker rm '{split:\\t:0}'";
        mode = "execute";
      };
    };
  };

  "docker-images" = {
    metadata = {
      name = "docker-images";
      description = "A channel to select from Docker images";
      requirements = [ "docker" "jq" ];
    };
    source = {
      command = "docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}'";
      output = "{split: :-1}";
    };
    preview = {
      command = "docker image inspect '{split: :-1}' | jq -C";
    };
    ui = {
      layout = "portrait";
    };
    keybindings = {
      "ctrl-r" = "actions:run";
      "ctrl-d" = "actions:remove";
      "ctrl-s" = "actions:shell";
    };
    actions = {
      run = {
        description = "Run a container from the selected image";
        command = "docker run -it '{split: :-1}'";
        mode = "execute";
      };
      shell = {
        description = "Run a shell in the selected image";
        command = "docker run -it '{split: :-1}' /bin/sh";
        mode = "execute";
      };
      remove = {
        description = "Remove the selected image";
        command = "docker rmi '{split: :-1}'";
        mode = "execute";
      };
    };
  };

  "docker-networks" = {
    metadata = {
      name = "docker-networks";
      description = "List and manage Docker networks";
      requirements = [ "docker" "jq" ];
    };
    source = {
      command = "docker network ls --format '{{.Name}}	{{.Driver}}	{{.Scope}}'";
      display = "{split:	:0} ({split:	:1}, {split:	:2})";
      output = "{split:	:0}";
    };
    preview = {
      command = "docker network inspect '{split:	:0}' | jq -C '.[0] | {Name, Driver, Scope, IPAM, Containers: (.Containers // {} | to_entries | map({name: .value.Name, ipv4: .value.IPv4Address}))}'";
    };
    ui = {
      layout = "portrait";
    };
    actions = {
      remove = {
        description = "Remove the selected network";
        command = "docker network rm '{split:	:0}'";
        mode = "execute";
      };
    };
  };

  "docker-volumes" = {
    metadata = {
      name = "docker-volumes";
      description = "List and manage Docker volumes";
      requirements = [ "docker" "jq" ];
    };
    source = {
      command = "docker volume ls --format '{{.Name}}	{{.Driver}}'";
      display = "{split:	:0} ({split:	:1})";
      output = "{split:	:0}";
    };
    preview = {
      command = "docker volume inspect '{split:	:0}' | jq -C '.[0]'";
    };
    ui = {
      layout = "portrait";
    };
    actions = {
      remove = {
        description = "Remove the selected volume";
        command = "docker volume rm '{split:	:0}'";
        mode = "execute";
      };
      inspect = {
        description = "Inspect the selected volume in a pager";
        command = "docker volume inspect '{split:	:0}' | jq -C '.[0]' | less -R";
        mode = "execute";
      };
    };
  };

  dotfiles = {
    metadata = {
      name = "dotfiles";
      description = "A channel to select from your user's dotfiles";
      requirements = [ "fd" "bat" ];
    };
    source = {
      command = "fd -t f . $HOME/.config";
    };
    preview = {
      command = "bat -n --color=always '{}'";
    };
    keybindings = {
      enter = "actions:edit";
    };
    actions = {
      edit = {
        description = "Edit the selected dotfile";
        command = "\${EDITOR:-vim} '{}'";
        shell = "bash";
        mode = "execute";
      };
    };
  };

  downloads = {
    metadata = {
      name = "downloads";
      description = "Browse recent files in Downloads folder";
      requirements = [ "fd" "bat" ];
    };
    source = {
      command = "fd -t f . ~/Downloads 2>/dev/null | head -200";
    };
    preview = {
      command = "bat -n --color=always '{}' 2>/dev/null || file '{}'";
      env = {
        BAT_THEME = "ansi";
      };
    };
    keybindings = {
      enter = "actions:open";
      "ctrl-d" = "actions:delete";
      "ctrl-m" = "actions:move";
    };
    actions = {
      open = {
        description = "Open the selected file with default application";
        command = "xdg-open '{}' 2>/dev/null || open '{}'";
        mode = "fork";
      };
      delete = {
        description = "Delete the selected file";
        command = "rm -i '{}'";
        mode = "execute";
      };
      move = {
        description = "Move the selected file to current directory";
        command = "mv '{}' .";
        mode = "fork";
      };
    };
  };

  env = {
    metadata = {
      name = "env";
      description = "A channel to select from environment variables";
    };
    source = {
      command = "printenv";
      output = "{split:=:1..}";
    };
    preview = {
      command = "echo '{split:=:1..}'";
    };
    ui = {
      layout = "portrait";
      preview_panel = {
        size = 20;
        header = "{split:=:0}";
      };
    };
    keybindings = {
      shortcut = "f3";
    };
    actions = {
      name = {
        description = "Output the variable name instead of the value";
        command = "echo '{split:=:0}'";
        mode = "execute";
      };
    };
  };

  files = {
    metadata = {
      name = "files";
      description = "A channel to select files and directories";
      requirements = [ "fd" "bat" ];
    };
    source = {
      command = [ "fd -t f" "fd -t f -H" "fd -t f -H -I" ];
    };
    preview = {
      command = "bat -n --color=always '{}'";
      env = {
        BAT_THEME = "ansi";
      };
    };
    keybindings = {
      shortcut = "f1";
      enter = "actions:edit";
      "ctrl-up" = "actions:goto_parent_dir";
    };
    actions = {
      edit = {
        description = "Opens the selected entries with the default editor (falls back to vim)";
        command = "nvim '{}'";
        shell = "nu";
        mode = "execute";
      };
      goto_parent_dir = {
        description = "Re-opens tv in the parent directory";
        command = "tv files ..";
        mode = "execute";
      };
    };
    ui = {
      preview_panel = {
        hidden = true;
      };
    };
  };

  fonts = {
    metadata = {
      name = "fonts";
      description = "List installed system fonts";
      requirements = [ "fc-list" ];
    };
    source = {
      command = "fc-list --format='%{family}\n' | sort -uf";
    };
    preview = {
      command = "fc-list '{}' --format='%{file}\n%{style}\n%{family}\n' | head -20";
    };
    ui = {
      preview_panel = {
        size = 70;
      };
    };
  };

  "gh-issues" = {
    metadata = {
      name = "gh-issues";
      description = "List GitHub issues for the current repo";
      requirements = [ "gh" "jq" ];
    };
    source = {
      command = "gh issue list --state open --limit 100 --json number,title,createdAt,author,labels | jq -r 'sort_by(.createdAt) | reverse | .[] | \"  \\u001b[32m#\\(.number)\\u001b[39m   \\(.title) \\u001b[33m@\\(.author.login)\\u001b[39m\" + (if (.labels | length) > 0 then \" \" + ([.labels[] | \"\\u001b[35m\" + .name + \"\\u001b[39m\"] | join(\" \")) else \"\" end)'\n";
      ansi = true;
      output = "{strip_ansi|split:#:1|split: :0}";
    };
    ui = {
      layout = "portrait";
      preview_panel = {
        header = "{strip_ansi|split:#:1|split: :0}";
      };
    };
    preview = {
      command = "gh issue view '{strip_ansi|split:#:1|split:   :0}' --json number,title,body,state,author,createdAt,updatedAt,labels,assignees | jq -r '\n\"  \" + .title,\n\"  #\" + (.number | tostring),\n\"\",\n\"  \\u001b[36mStatus:\\u001b[39m \\u001b[32m\" + .state + \"\\u001b[39m\",\n\"  \\u001b[36mAuthor:\\u001b[39m \\u001b[33m\" + .author.login + \"\\u001b[39m\",\n\"  \\u001b[36mCreated:\\u001b[39m \" + (.createdAt | fromdateiso8601 | (now - .) | if . < 3600 then (./60|floor|tostring) + \" minutes ago\" elif . < 86400 then (./3600|floor|tostring) + \" hours ago\" else (./86400|floor|tostring) + \" days ago\" end),\n\"  \\u001b[36mUpdated:\\u001b[39m \" + (.updatedAt | fromdateiso8601 | (now - .) | if . < 3600 then (./60|floor|tostring) + \" minutes ago\" elif . < 86400 then (./3600|floor|tostring) + \" hours ago\" else (./86400|floor|tostring) + \" days ago\" end),\n(if (.labels | length) > 0 then \"  \\u001b[36mLabels:\\u001b[39m \" + ([.labels[] | \"\\u001b[35m\" + .name + \"\\u001b[39m\"] | join(\" \")) else \"\" end),\n(if (.assignees | length) > 0 then \"  \\u001b[36mAssignees:\\u001b[39m \" + ([.assignees[].login] | join(\", \")) else \"\" end),\n\"\",\n\"  \\u001b[90m────────────────────────────────────────────────────────────\\u001b[39m\",\n\"\",\n(.body // \"\")'\n";
    };
    actions = {
      open = {
        description = "Open the issue in the browser";
        command = "gh issue view {strip_ansi|split:#:1|split: :0} --web";
        mode = "fork";
      };
      close = {
        description = "Close the selected issue";
        command = "gh issue close {strip_ansi|split:#:1|split: :0}";
        mode = "fork";
      };
      comment = {
        description = "Add a comment to the selected issue";
        command = "gh issue comment {strip_ansi|split:#:1|split: :0}";
        mode = "execute";
      };
    };
  };

  "gh-prs" = {
    metadata = {
      name = "gh-prs";
      description = "List GitHub PRs for the current repo";
      requirements = [ "gh" "jq" ];
    };
    source = {
      command = "gh pr list --state open --limit 100 --json number,title,createdAt,author,labels | jq -r 'sort_by(.createdAt) | reverse | .[] | \"  \\u001b[32m#\\(.number)\\u001b[39m   \\(.title) \\u001b[33m@\\(.author.login)\\u001b[39m\" + (if (.labels | length) > 0 then \" \" + ([.labels[] | \"\\u001b[35m\" + .name + \"\\u001b[39m\"] | join(\" \")) else \"\" end)'\n";
      output = "{strip_ansi|split:#:1|split:   :0}";
      ansi = true;
    };
    ui = {
      layout = "portrait";
    };
    preview = {
      command = "gh pr view '{strip_ansi|split:#:1|split:   :0}' --json number,title,body,state,headRefName,baseRefName,author,createdAt,updatedAt,mergeable,changedFiles,additions,deletions,labels,assignees,reviewDecision,headRepository,headRepositoryOwner | jq -r '\n\"  \" + .title,\n\"  #\" + (.number | tostring),\n\"\",\n\"  \\u001b[36mStatus:\\u001b[39m \\u001b[32m\" + .state + \"\\u001b[39m  \" + .baseRefName + \" ← \" + .headRefName,\n\"  \\u001b[36mRepo:\\u001b[39m \\u001b[34m\" + (.headRepositoryOwner.login) + \"/\" + (.headRepository.name) + \"\\u001b[39m\",\n\"  \\u001b[36mAuthor:\\u001b[39m \\u001b[33m\" + .author.login + \"\\u001b[39m\",\n\"  \\u001b[36mCreated:\\u001b[39m \" + (.createdAt | fromdateiso8601 | (now - .) | if . < 3600 then (./60|floor|tostring) + \" minutes ago\" elif . < 86400 then (./3600|floor|tostring) + \" hours ago\" else (./86400|floor|tostring) + \" days ago\" end),\n\"  \\u001b[36mUpdated:\\u001b[39m \" + (.updatedAt | fromdateiso8601 | (now - .) | if . < 3600 then (./60|floor|tostring) + \" minutes ago\" elif . < 86400 then (./3600|floor|tostring) + \" hours ago\" else (./86400|floor|tostring) + \" days ago\" end),\n(if (.labels | length) > 0 then \"  \\u001b[36mLabels:\\u001b[39m \" + ([.labels[] | \"\\u001b[35m\" + .name + \"\\u001b[39m\"] | join(\" \")) else \"\" end),\n\"  \\u001b[36mMerge Status:\\u001b[39m \" + (if .mergeable == \"MERGEABLE\" then \"\\u001b[32m✓ Clean\\u001b[39m\" elif .mergeable == \"CONFLICTING\" then \"\\u001b[31m✗ Dirty\\u001b[39m\" else \"\\u001b[33m? Unknown\\u001b[39m\" end),\n\"  \\u001b[36mChanges:\\u001b[39m \" + (.changedFiles | tostring) + \" files  \\u001b[32m+\" + (.additions | tostring) + \"\\u001b[39m \\u001b[31m-\" + (.deletions | tostring) + \"\\u001b[39m\",\n\"\",\n\"  \\u001b[90m────────────────────────────────────────────────────────────\\u001b[39m\",\n\"\",\n(.body // \"\")'\n";
    };
    actions = {
      open = {
        description = "Open the PR in the browser";
        command = "gh pr view {strip_ansi|split:#:1|split:   :0} --web";
        mode = "execute";
      };
      checkout = {
        description = "Checkout the PR branch locally";
        command = "gh pr checkout {strip_ansi|split:#:1|split:   :0}";
        mode = "execute";
      };
      merge = {
        description = "Merge the selected PR";
        command = "gh pr merge {strip_ansi|split:#:1|split:   :0}";
        mode = "execute";
      };
      diff = {
        description = "View the PR diff";
        command = "gh pr diff {strip_ansi|split:#:1|split:   :0} | less";
        mode = "execute";
      };
    };
  };

  "git-branch" = {
    metadata = {
      name = "git-branch";
      description = "A channel to select from git branches";
      requirements = [ "git" ];
    };
    source = {
      command = "git --no-pager branch --all --format=\"%(refname:short)\"";
      output = "{split: :0}";
    };
    preview = {
      command = "git show -p --stat --pretty=fuller --color=always '{0}'";
    };
    keybindings = {
      enter = "actions:checkout";
      "ctrl-d" = "actions:delete";
      "ctrl-m" = "actions:merge";
      "ctrl-r" = "actions:rebase";
    };
    actions = {
      checkout = {
        description = "Checkout the selected branch";
        command = "git checkout '{0}'";
        mode = "execute";
      };
      delete = {
        description = "Delete the selected branch";
        command = "git branch -d '{0}'";
        mode = "execute";
      };
      merge = {
        description = "Merge the selected branch into current branch";
        command = "git merge '{0}'";
        mode = "execute";
      };
      rebase = {
        description = "Rebase current branch onto the selected branch";
        command = "git rebase '{0}'";
        mode = "execute";
      };
    };
  };

  "git-diff" = {
    metadata = {
      name = "git-diff";
      description = "A channel to select files from git diff commands";
      requirements = [ "git" ];
    };
    source = {
      command = "git diff --name-only HEAD";
    };
    preview = {
      command = "git diff HEAD --color=always -- '{}'";
    };
    ui = {
      layout = "portrait";
    };
    keybindings = {
      "ctrl-s" = "actions:stage";
      "ctrl-r" = "actions:restore";
      "ctrl-e" = "actions:edit";
    };
    actions = {
      stage = {
        description = "Stage the selected file";
        command = "git add '{}'";
        mode = "fork";
      };
      restore = {
        description = "Discard changes in the selected file";
        command = "git restore '{}'";
        mode = "fork";
      };
      edit = {
        description = "Open the selected file in editor";
        command = "\${EDITOR:-vim} '{}'";
        shell = "bash";
        mode = "execute";
      };
    };
  };

  "git-files" = {
    metadata = {
      name = "git-files";
      description = "A channel to list the files currently tracked in the Git repository";
      requirements = [ "git" "bat" ];
    };
    source = {
      command = "git ls-files $(git rev-parse --show-toplevel)";
    };
    preview = {
      command = "bat -n --color=always '{}'";
      env = {
        BAT_THEME = "ansi";
      };
    };
    keybindings = {
      f12 = "actions:edit";
    };
    actions = {
      edit = {
        description = "Opens the selected entries with the default editor (falls back to vim)";
        command = "\${EDITOR:-vim} '{}'";
        shell = "bash";
        mode = "execute";
      };
    };
  };

  "git-log" = {
    metadata = {
      name = "git-log";
      description = "A channel to select from git log entries";
      requirements = [ "git" ];
    };
    source = {
      command = "git log --graph --pretty=format:'%C(yellow)%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --color=always";
      output = "{strip_ansi|split: :1}";
      ansi = true;
      no_sort = true;
      frecency = false;
    };
    preview = {
      command = "git show -p --stat --pretty=fuller --color=always '{strip_ansi|split: :1}' | head -n 1000";
    };
    keybindings = {
      "ctrl-y" = "actions:cherry-pick";
      "ctrl-r" = "actions:revert";
      "ctrl-o" = "actions:checkout";
    };
    actions = {
      "cherry-pick" = {
        description = "Cherry-pick the selected commit";
        command = "git cherry-pick '{strip_ansi|split: :1}'";
        mode = "execute";
      };
      revert = {
        description = "Revert the selected commit";
        command = "git revert '{strip_ansi|split: :1}'";
        mode = "execute";
      };
      checkout = {
        description = "Checkout the selected commit";
        command = "git checkout '{strip_ansi|split: :1}'";
        mode = "execute";
      };
    };
  };

  "git-reflog" = {
    metadata = {
      name = "git-reflog";
      description = "A channel to select from git reflog entries";
      requirements = [ "git" ];
    };
    source = {
      command = "git reflog --decorate --color=always";
      output = "{0|strip_ansi}";
      ansi = true;
      no_sort = true;
      frecency = false;
    };
    preview = {
      command = "git show -p --stat --pretty=fuller --color=always '{0|strip_ansi}'";
    };
    keybindings = {
      "ctrl-o" = "actions:checkout";
      "ctrl-r" = "actions:reset";
    };
    actions = {
      checkout = {
        description = "Checkout the selected reflog entry";
        command = "git checkout '{0|strip_ansi}'";
        mode = "execute";
      };
      reset = {
        description = "Reset --hard to the selected reflog entry";
        command = "git reset --hard '{0|strip_ansi}'";
        mode = "execute";
      };
    };
  };

  "git-remotes" = {
    metadata = {
      name = "git-remotes";
      description = "List and manage git remotes";
      requirements = [ "git" ];
    };
    source = {
      command = "git remote";
    };
    preview = {
      command = "git remote show '{}'";
    };
    actions = {
      fetch = {
        description = "Fetch from the selected remote";
        command = "git fetch '{}'";
        mode = "execute";
      };
      remove = {
        description = "Remove the selected remote";
        command = "git remote remove '{}'";
        mode = "execute";
      };
    };
  };

  "git-repos" = {
    metadata = {
      name = "git-repos";
      requirements = [ "fd" "git" ];
      description = "A channel to select from git repositories on your local machine.\n\nThis channel uses `fd` to find directories that contain a `.git` subdirectory, and then allows you to preview the git log of the selected repository.\n";
    };
    source = {
      command = "fd -g .git -HL -t d -d 10 --prune ~ -E 'Library' -E 'Application Support' --exec dirname '{}'";
      display = "{split:/:-1}";
    };
    preview = {
      command = "cd '{}'; git log -n 200 --pretty=medium --all --graph --color";
    };
    keybindings = {
      enter = "actions:cd";
      "ctrl-e" = "actions:edit";
    };
    actions = {
      cd = {
        description = "Open a new shell in the selected repository";
        command = "cd '{}' && $SHELL";
        mode = "execute";
      };
      edit = {
        description = "Open the repository in editor";
        command = "\${EDITOR:-vim} '{}'";
        shell = "bash";
        mode = "execute";
      };
    };
  };

  "git-stash" = {
    metadata = {
      name = "git-stash";
      description = "Browse and manage git stash entries";
      requirements = [ "git" ];
    };
    source = {
      command = "git stash list --color=always";
      ansi = true;
      output = "{strip_ansi|split:\\::0}";
      no_sort = true;
      frecency = false;
    };
    preview = {
      command = "git stash show -p --color=always '{strip_ansi|split:\\::0}'";
    };
    ui = {
      layout = "portrait";
    };
    keybindings = {
      enter = "actions:apply";
      "ctrl-p" = "actions:pop";
      "ctrl-d" = "actions:drop";
    };
    actions = {
      apply = {
        description = "Apply the selected stash";
        command = "git stash apply '{strip_ansi|split:\\::0}'";
        mode = "execute";
      };
      pop = {
        description = "Pop the selected stash (apply and remove)";
        command = "git stash pop '{strip_ansi|split:\\::0}'";
        mode = "execute";
      };
      drop = {
        description = "Drop the selected stash";
        command = "git stash drop '{strip_ansi|split:\\::0}'";
        mode = "execute";
      };
    };
  };

  "git-submodules" = {
    metadata = {
      name = "git-submodules";
      description = "List and manage git submodules";
      requirements = [ "git" ];
    };
    source = {
      command = "git submodule status | awk '{print $2}'";
    };
    preview = {
      command = "git -C '{}' log --oneline -10 --color=always";
    };
    actions = {
      update = {
        description = "Update the selected submodule";
        command = "git submodule update --init --recursive '{}'";
        mode = "execute";
      };
      sync = {
        description = "Sync the selected submodule URL";
        command = "git submodule sync '{}'";
        mode = "execute";
      };
    };
  };

  "git-tags" = {
    metadata = {
      name = "git-tags";
      description = "Browse and checkout git tags";
      requirements = [ "git" ];
    };
    source = {
      command = "git tag --sort=-creatordate";
      no_sort = true;
      frecency = false;
    };
    preview = {
      command = "git show --color=always '{}'";
    };
    keybindings = {
      enter = "actions:checkout";
      "ctrl-d" = "actions:delete";
    };
    actions = {
      checkout = {
        description = "Checkout the selected tag";
        command = "git checkout '{}'";
        mode = "execute";
      };
      delete = {
        description = "Delete the selected tag";
        command = "git tag -d '{}'";
        mode = "execute";
      };
    };
  };

  "git-worktrees" = {
    metadata = {
      name = "git-worktrees";
      description = "List and switch between git worktrees";
      requirements = [ "git" ];
    };
    source = {
      command = "git worktree list --porcelain | grep '^worktree' | cut -d' ' -f2-";
    };
    preview = {
      command = "cd '{}'; git log --oneline -10 --color=always; echo; git status --short";
    };
    keybindings = {
      enter = "actions:cd";
      "ctrl-d" = "actions:remove";
    };
    actions = {
      cd = {
        description = "Change to the selected worktree";
        command = "cd '{}'; $SHELL";
        mode = "execute";
      };
      remove = {
        description = "Remove the selected worktree";
        command = "git worktree remove '{}'";
        mode = "execute";
      };
    };
  };

  "k8s-contexts" = {
    metadata = {
      name = "k8s-contexts";
      description = "List and switch kubectl contexts";
      requirements = [ "kubectl" ];
    };
    source = {
      command = "kubectl config get-contexts -o name";
    };
    preview = {
      command = "kubectl config view --minify --context='{}' -o yaml";
    };
    ui = {
      layout = "portrait";
    };
    keybindings = {
      enter = "actions:use";
      "ctrl-d" = "actions:delete";
    };
    actions = {
      use = {
        description = "Switch to the selected context";
        command = "kubectl config use-context '{}'";
        mode = "execute";
      };
      delete = {
        description = "Delete the selected context";
        command = "kubectl config delete-context '{}'";
        mode = "execute";
      };
    };
  };

  "k8s-deployments" = {
    metadata = {
      name = "k8s-deployments";
      description = "List and preview Deployments in a Kubernetes Cluster.\n\nThe first source lists only from the current namespace, while the second lists from all.\n\nKeybindings\n\nPress `ctrl-d` to delete the selected Deployment.\n";
      requirements = [ "kubectl" ];
    };
    source = {
      command = [ "  kubectl get deployments -o go-template --template '{{range .items}}{{.metadata.namespace}} {{.metadata.name}}{{\"\\n\"}}{{end}}'\n  " "  kubectl get deployments -o go-template --template '{{range .items}}{{.metadata.namespace}} {{.metadata.name}}{{\"\\n\"}}{{end}}' --all-namespaces\n  " ];
      output = "{1}";
    };
    preview = {
      command = "kubectl describe -n {0} deployments/{1}";
    };
    ui = {
      layout = "portrait";
      preview_panel = {
        size = 60;
      };
    };
    keybindings = {
      "ctrl-d" = "actions:delete";
    };
    actions = {
      delete = {
        description = "Delete the selected Deployment";
        command = "kubectl delete -n {0} deployments/{1}";
        mode = "execute";
      };
    };
  };

  "k8s-pods" = {
    metadata = {
      name = "k8s-pods";
      description = "List and preview Pods in a Kubernetes Cluster.\n\nThe first source lists only from the current namespace, while the second lists from all.\n\nKeybindings\n\nPress `ctrl-e` to execute shell inside the selected Pod.\nPress `ctrl-d` to delete the selected Pod.\nPress `ctrl-l` to print and follow the logs of the selected Pod.\n";
      requirements = [ "kubectl" ];
    };
    source = {
      command = [ "  kubectl get pods -o go-template --template '{{range .items}}{{.metadata.namespace}} {{.metadata.name}}{{\"\\n\"}}{{end}}'\n  " "  kubectl get pods -o go-template --template '{{range .items}}{{.metadata.namespace}} {{.metadata.name}}{{\"\\n\"}}{{end}}' --all-namespaces\n  " ];
      output = "{1}";
    };
    preview = {
      command = "kubectl describe -n {0} pods/{1}";
    };
    ui = {
      layout = "portrait";
      preview_panel = {
        size = 60;
      };
    };
    keybindings = {
      "ctrl-d" = "actions:delete";
      "ctrl-e" = "actions:exec";
      "ctrl-l" = "actions:logs";
    };
    actions = {
      exec = {
        description = "Execute shell inside the selected Pod";
        command = "kubectl exec -i -t -n {0} pods/{1} -- /bin/sh";
        mode = "execute";
      };
      delete = {
        description = "Delete the selected Pod";
        command = "kubectl delete -n {0} pods/{1}";
        mode = "execute";
      };
      logs = {
        description = "Follow logs of the selected Pod";
        command = "kubectl logs -f -n {0} pods/{1}";
        mode = "execute";
      };
    };
  };

  "k8s-services" = {
    metadata = {
      name = "k8s-services";
      description = "List and preview Services in a Kubernetes Cluster.\n\nThe first source lists only from the current namespace, while the second lists from all.\n\nkeybindings\n\nPress `ctrl-d` to delete the selected Service.\n";
      requirements = [ "kubectl" ];
    };
    source = {
      command = [ "  kubectl get services -o go-template --template '{{range .items}}{{.metadata.namespace}} {{.metadata.name}}{{\"\\n\"}}{{end}}'\n  " "  kubectl get services -o go-template --template '{{range .items}}{{.metadata.namespace}} {{.metadata.name}}{{\"\\n\"}}{{end}}' --all-namespaces\n  " ];
      output = "{1}";
    };
    preview = {
      command = "kubectl describe -n {0} services/{1}";
    };
    ui = {
      layout = "portrait";
      preview_panel = {
        size = 60;
      };
    };
    keybindings = {
      "ctrl-d" = "actions:delete";
    };
    actions = {
      delete = {
        description = "Delete the selected Service";
        command = "kubectl delete -n {0} services/{1}";
        mode = "execute";
      };
    };
  };

  "make-targets" = {
    metadata = {
      name = "make-targets";
      description = "List and run Makefile targets";
      requirements = [ "make" "awk" ];
    };
    source = {
      command = "make -pRrq 2>/dev/null | awk -F: '/^[a-zA-Z0-9][^$#\\/\\t=]*:([^=]|$)/ {split($1,a,\" \"); print a[1]}' | sort -u | grep -v '^Makefile$'";
    };
    preview = {
      command = "awk '/^{}[[:space:]]*:/{found=1} found{print; if(/^[^\\t]/ && NR>1 && !/^{}[[:space:]]*:/) exit}' Makefile";
    };
    keybindings = {
      enter = "actions:run";
    };
    actions = {
      run = {
        description = "Run the selected make target";
        command = "make {}";
        mode = "execute";
      };
    };
  };

  "man-pages" = {
    metadata = {
      name = "man-pages";
      description = "Browse and preview system manual pages";
      requirements = [ "apropos" "man" ];
    };
    source = {
      command = "apropos .";
    };
    preview = {
      command = "man '{0}'";
      env = {
        MANWIDTH = "80";
      };
    };
    keybindings = {
      enter = "actions:open";
    };
    actions = {
      open = {
        description = "Open the selected man page in the system pager";
        command = "man '{0}'";
        mode = "execute";
      };
    };
    ui = {
      layout = "portrait";
      preview_panel = {
        header = "{0}";
      };
    };
  };

  mounts = {
    metadata = {
      name = "mounts";
      description = "List mounted filesystems";
      requirements = [ "df" "awk" ];
    };
    source = {
      command = "df -h --output=target,fstype,size,used,avail,pcent 2>/dev/null | tail -n +2";
      display = "{split: :0}";
    };
    preview = {
      command = "df -h '{}' && echo && ls -la '{}' 2>/dev/null | head -20";
    };
    keybindings = {
      enter = "actions:cd";
    };
    actions = {
      cd = {
        description = "Open a shell in the selected mount point";
        command = "cd '{}' && $SHELL";
        mode = "execute";
      };
    };
  };

  "node-packages" = {
    metadata = {
      name = "node-packages";
      description = "Browse local node_modules dependencies";
      requirements = [ "node" ];
    };
    source = {
      command = "ls -d node_modules/*/ 2>/dev/null | sed 's|node_modules/||;s|/$||' | grep -v '^\\.'";
      output = "{}";
    };
    preview = {
      command = "cat 'node_modules/{}/package.json' 2>/dev/null | jq -C '{name, version, description, license, homepage, main}'";
    };
    actions = {
      readme = {
        description = "View the package README";
        command = "cat node_modules/{}/README.md 2>/dev/null | less";
        mode = "execute";
      };
      homepage = {
        description = "Open the package homepage";
        command = "node -e \"const p=require('./node_modules/{}/package.json'); const u=p.homepage||'https://www.npmjs.com/package/'+p.name; require('child_process').exec('xdg-open '+u)\"";
        mode = "fork";
      };
    };
  };

  "npm-packages" = {
    metadata = {
      name = "npm-packages";
      description = "List globally installed npm packages";
      requirements = [ "npm" ];
    };
    source = {
      command = "npm list -g --depth=0 --parseable 2>/dev/null | tail -n +2 | xargs -I{} basename {}";
    };
    preview = {
      command = "npm info '{}' 2>/dev/null | head -30";
    };
    actions = {
      uninstall = {
        description = "Uninstall the selected global package";
        command = "npm uninstall -g '{}'";
        mode = "execute";
      };
      update = {
        description = "Update the selected global package";
        command = "npm update -g '{}'";
        mode = "execute";
      };
    };
  };

  "npm-scripts" = {
    metadata = {
      name = "npm-scripts";
      description = "List and run npm scripts from package.json";
      requirements = [ "jq" ];
    };
    source = {
      command = "jq -r '.scripts | to_entries[] | \"\\(.key)\\t\\(.value)\"' package.json 2>/dev/null";
      display = "{split:\\t:0}";
    };
    preview = {
      command = "jq -r '.scripts[\"{split:\\t:0}\"]' package.json";
    };
    ui = {
      preview_panel = {
        size = 30;
      };
    };
    keybindings = {
      enter = "actions:run";
    };
    actions = {
      run = {
        description = "Run the selected npm script";
        command = "npm run '{split:\\t:0}'";
        mode = "execute";
      };
    };
  };

  "nu-history" = {
    metadata = {
      name = "nu-history";
      description = "A channel to select from your nu history";
    };
    source = {
      command = "nu -c 'open $nu.history-path | lines | uniq | reverse | to text'";
      no_sort = true;
      frecency = false;
    };
  };

  path = {
    metadata = {
      name = "path";
      description = "Investigate PATH contents";
      requirements = [ "fd" "bat" ];
    };
    source = {
      command = "printf '%s\n' \"$PATH\" | tr ':' '\n'";
    };
    preview = {
      command = "fd -tx -d1 . \"{}\" -X printf \"%s\n\" \"{/}\" | sort -f | bat -n --color=always";
    };
    actions = {
      cd = {
        description = "Open a shell in the selected PATH directory";
        command = "cd '{}' && $SHELL";
        mode = "execute";
      };
    };
  };

  "pip-packages" = {
    metadata = {
      name = "pip-packages";
      description = "List installed Python packages";
      requirements = [ "pip" ];
    };
    source = {
      command = "pip list --format=freeze 2>/dev/null | cut -d= -f1";
    };
    preview = {
      command = "pip show '{}'";
    };
    ui = {
      layout = "portrait";
    };
    keybindings = {
      "ctrl-u" = "actions:upgrade";
      "ctrl-d" = "actions:uninstall";
    };
    actions = {
      upgrade = {
        description = "Upgrade the selected package";
        command = "pip install --upgrade '{}'";
        mode = "execute";
      };
      uninstall = {
        description = "Uninstall the selected package";
        command = "pip uninstall '{}'";
        mode = "execute";
      };
    };
  };

  procs = {
    metadata = {
      name = "procs";
      description = "A channel to find and manage running processes";
      requirements = [ "ps" "awk" ];
    };
    source = {
      command = "ps -e -o pid=,ucomm= | awk '{print $1, $2}'";
      display = "{split: :1}";
      output = "{split: :0}";
    };
    preview = {
      command = "ps -p '{split: :0}' -o user,pid,ppid,state,%cpu,%mem,command | fold";
    };
    keybindings = {
      "ctrl-k" = "actions:kill";
      f2 = "actions:term";
      "ctrl-s" = "actions:stop";
      "ctrl-c" = "actions:cont";
    };
    actions = {
      kill = {
        description = "Kill the selected process (SIGKILL)";
        command = "kill -9 {split: :0}";
        mode = "execute";
      };
      term = {
        description = "Terminate the selected process (SIGTERM)";
        command = "kill -15 {split: :0}";
        mode = "execute";
      };
      stop = {
        description = "Stop/pause the selected process (SIGSTOP)";
        command = "kill -STOP {split: :0}";
        mode = "fork";
      };
      cont = {
        description = "Continue/resume the selected process (SIGCONT)";
        command = "kill -CONT {split: :0}";
        mode = "fork";
      };
    };
  };

  "python-venvs" = {
    metadata = {
      name = "python-venvs";
      description = "Find Python virtual environments";
      requirements = [ "find" ];
    };
    source = {
      command = "find ~ -maxdepth 5 -type f -name 'pyvenv.cfg' 2>/dev/null | xargs -I{} dirname {}";
    };
    preview = {
      command = "cat '{}/pyvenv.cfg' 2>/dev/null && echo '' && echo 'Packages:' && '{}/bin/pip' list --format=columns 2>/dev/null | head -20";
    };
    actions = {
      activate = {
        description = "Open a shell with the selected venv activated";
        command = "source '{}/bin/activate' && $SHELL";
        mode = "execute";
      };
      packages = {
        description = "List all packages in the selected venv";
        command = "'{}/bin/pip' list | less";
        mode = "execute";
      };
    };
  };

  "recent-files" = {
    metadata = {
      name = "recent-files";
      description = "List recently modified files (via git or filesystem)";
      requirements = [ "git" "bat" ];
    };
    source = {
      command = [ "git diff --name-only HEAD~10 HEAD 2>/dev/null || find . -type f -mtime -7 -not -path '*/.*' 2>/dev/null | head -100" "find . -type f -mmin -60 -not -path '*/.*' 2>/dev/null | head -100" ];
    };
    preview = {
      command = "bat -n --color=always '{}'";
      env = {
        BAT_THEME = "ansi";
      };
    };
    keybindings = {
      enter = "actions:edit";
    };
    actions = {
      edit = {
        description = "Open the selected file in editor";
        command = "\${EDITOR:-vim} '{}'";
        shell = "bash";
        mode = "execute";
      };
    };
  };

  rustup = {
    metadata = {
      name = "rustup";
      description = "Manage Rust toolchains";
      requirements = [ "rustup" ];
    };
    source = {
      command = "rustup toolchain list";
    };
    preview = {
      command = "rustup run '{split: :0}' rustc --version --verbose 2>/dev/null";
    };
    actions = {
      default = {
        description = "Set the selected toolchain as default";
        command = "rustup default '{split: :0}'";
        mode = "execute";
      };
      uninstall = {
        description = "Uninstall the selected toolchain";
        command = "rustup toolchain uninstall '{split: :0}'";
        mode = "execute";
      };
    };
  };

  sesh = {
    metadata = {
      name = "sesh";
      description = "Session manager integrating tmux sessions, zoxide directories, and config paths";
      requirements = [ "sesh" "fd" ];
    };
    source = {
      command = [ "sesh list --icons" "sesh list -t --icons" "sesh list -c --icons" "sesh list -z --icons" "fd -H -d 2 -t d -E .Trash . ~" ];
      ansi = true;
      output = "{strip_ansi|split: :1..|join: }";
    };
    preview = {
      command = "sesh preview '{strip_ansi|split: :1..|join: }'";
    };
    keybindings = {
      enter = "actions:connect";
      "ctrl-d" = [ "actions:kill_session" "reload_source" ];
    };
    actions = {
      connect = {
        description = "Connect to selected session";
        command = "sesh connect '{strip_ansi|split: :1..|join: }'";
        mode = "execute";
      };
      kill_session = {
        description = "Kill selected tmux session (press Ctrl+r to reload)";
        command = "tmux kill-session -t '{strip_ansi|split: :1..|join: }'";
        mode = "fork";
      };
    };
  };

  "ssh-hosts" = {
    metadata = {
      name = "ssh-hosts";
      description = "A channel to select hosts from your SSH config";
      requirements = [ "grep" "tr" "cut" "awk" ];
    };
    source = {
      command = "grep -E '^Host(name)? ' $HOME/.ssh/config | tr -s ' ' | cut -d' ' -f2- | tr ' ' '\n' | grep -v '^$'";
    };
    preview = {
      command = "awk '/^Host / { found=0 } /^Host (.*[[:space:]])?'{}'([[:space:]].*)?$/ { found=1 } found' $HOME/.ssh/config";
    };
    keybindings = {
      enter = "actions:connect";
    };
    actions = {
      connect = {
        description = "SSH into the selected host";
        command = "ssh '{}'";
        mode = "execute";
      };
    };
  };

  text = {
    metadata = {
      name = "text";
      description = "A channel to find and select text from files";
      requirements = [ "rg" "bat" ];
    };
    source = {
      command = [ "rg . --no-heading --line-number --colors 'match:fg:white' --colors 'path:fg:blue' --color=always" "rg . --no-heading --line-number --hidden --colors 'match:fg:white' --colors 'path:fg:blue' --color=always" ];
      ansi = true;
      output = "{strip_ansi|split:\\::..2}";
    };
    preview = {
      command = "bat -n --color=always '{strip_ansi|split:\\::0}'";
      env = {
        BAT_THEME = "ansi";
      };
      offset = "{strip_ansi|split:\\::1}";
    };
    ui = {
      preview_panel = {
        header = "{strip_ansi|split:\\::..2}";
      };
    };
    keybindings = {
      enter = "actions:edit";
    };
    actions = {
      edit = {
        description = "Open file in editor at line";
        command = "\${EDITOR:-vim} '+{strip_ansi|split:\\::1}' '{strip_ansi|split:\\::0}'";
        shell = "bash";
        mode = "execute";
      };
    };
  };

  "tmux-sessions" = {
    metadata = {
      name = "tmux-sessions";
      description = "List and manage tmux sessions";
      requirements = [ "tmux" ];
    };
    source = {
      command = "tmux list-sessions -F '#{session_name}	#{session_windows} windows	#{session_created_string}'";
      display = "{split:	:0} ({split:	:1})";
      output = "{split:	:0}";
    };
    preview = {
      command = "tmux capture-pane -t '{split:	:0}' -p";
    };
    actions = {
      attach = {
        description = "Attach to the selected session";
        command = "tmux attach-session -t '{split:	:0}'";
        mode = "execute";
      };
      kill = {
        description = "Kill the selected session";
        command = "tmux kill-session -t '{split:	:0}'";
        mode = "fork";
      };
    };
  };

  "tmux-windows" = {
    metadata = {
      name = "tmux-windows";
      description = "List and switch between tmux windows";
      requirements = [ "tmux" ];
    };
    source = {
      command = "tmux list-windows -a -F '#{session_name}:#{window_index}	#{window_name}	#{pane_current_command}'";
      display = "{split:	:0} - {split:	:1} ({split:	:2})";
      output = "{split:	:0}";
    };
    preview = {
      command = "tmux capture-pane -t '{split:	:0}' -p 2>/dev/null || echo 'No preview available'";
    };
    actions = {
      select = {
        description = "Switch to the selected window";
        command = "tmux select-window -t '{split:	:0}'";
        mode = "execute";
      };
      kill = {
        description = "Kill the selected window";
        command = "tmux kill-window -t '{split:	:0}'";
        mode = "fork";
      };
    };
  };

  "todo-comments" = {
    metadata = {
      name = "todo-comments";
      description = "Find TODO, FIXME, HACK, and XXX comments in codebase";
      requirements = [ "rg" "bat" ];
    };
    source = {
      command = "rg -n --color=always '(TODO|FIXME|HACK|XXX|BUG|WARN):?'";
      ansi = true;
      output = "{strip_ansi|split:\\::..2}";
    };
    preview = {
      command = "bat -n --color=always --highlight-line '{strip_ansi|split:\\::1}' '{strip_ansi|split:\\::0}'";
      env = {
        BAT_THEME = "ansi";
      };
      offset = "{strip_ansi|split:\\::1}";
    };
    ui = {
      preview_panel = {
        header = "{strip_ansi|split:\\::..2}";
      };
    };
    keybindings = {
      enter = "actions:edit";
    };
    actions = {
      edit = {
        description = "Open file in editor at the comment";
        command = "\${EDITOR:-vim} '+{strip_ansi|split:\\::1}' '{strip_ansi|split:\\::0}'";
        shell = "bash";
        mode = "execute";
      };
    };
  };

  unicode = {
    metadata = {
      name = "unicode";
      description = "Search and insert unicode characters\n\nThe UnicodeData.txt file is included by many packages.\n\nIn addition to:\n\nAlpine Linux: unicode-character-database\nArch: unicode-character-database\nDebian/Ubuntu: unicode-data\nFedora / RHEL / CentOS unicode-ucd\nGentoo: app-i18n/unicode-data\nNixOS: unicode/unicode-data\nopenSUSE: unicode-ucd\n\nUnicodData.txt may also aleady be provided by:\n\n1) Many java packages\n2) Latex packages\n3) Still others\n\nIt may in some cases be necessary to alter UNICODE_FILE below.\n\n";
      requirements = [ "awk" "perl" ];
    };
    source = {
      command = "UNICODE_FILE=\"/usr/share/unicode/ucd/UnicodeData.txt\"\nawk -F';' '\n  $2 !~ /^</ { print $1 \"|\" $2 }\n' \"$UNICODE_FILE\" \\\n| perl -CS -F'\\|' -lane '\n    $code = $F[0];\n    $desc = $F[1];\n    $char = chr(hex($code));\n    print \"U+$code|$char|$desc\" if $char =~ /\\p{Print}/;\n'\n";
      display = "{split:|:0}    {split:|:1}    {split:|:2}";
      output = "{split:|:1}";
    };
  };

  "wt-list" = {
    metadata = {
      name = "wt";
      description = "A channel to list worktrunk worktrees";
    };
    source = {
      command = "wt list --format json | jq '.[].branch'";
    };
    preview = {
      command = "wt switch '{}'; git log --oneline -10";
    };
    ui = { };
    keybindings = { };
    actions = { };
  };

  zoxide = {
    metadata = {
      name = "zoxide";
      description = "Browse zoxide directory history";
      requirements = [ "zoxide" ];
    };
    source = {
      command = "zoxide query -l";
      no_sort = true;
      frecency = false;
    };
    preview = {
      command = "eza -la --color=always '{}'";
    };
    keybindings = {
      enter = "actions:cd";
      "ctrl-d" = "actions:remove";
    };
    actions = {
      cd = {
        description = "Change to the selected directory";
        command = "cd '{}' && $SHELL";
        mode = "execute";
      };
      remove = {
        description = "Remove the selected directory from zoxide";
        command = "zoxide remove '{}'";
        mode = "fork";
      };
    };
  };

  "zsh-history" = {
    metadata = {
      name = "zsh-history";
      description = "A channel to select from your zsh history";
      requirements = [ "zsh" ];
    };
    source = {
      command = "sed '1!G;h;$!d' \${HISTFILE:-\${HOME}/.zsh_history}";
      display = "{split:;:1..}";
      output = "{split:;:1..}";
      no_sort = true;
      frecency = false;
    };
    actions = {
      execute = {
        description = "Execute the selected command";
        command = "zsh -c '{split:;:1..}'";
        mode = "execute";
      };
    };
  };

}
