import { execFileSync } from "node:child_process";
import { mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type Lifecycle = { id?: unknown; type?: unknown; workflowId?: unknown };

// Upper bound on dynamic panes open at once (PI_AGENT_PANES_MAX, default 4).
const parsedMax = Number.parseInt(process.env.PI_AGENT_PANES_MAX ?? "", 10);
const MAX_PANES = Number.isInteger(parsedMax) && parsedMax >= 0 ? parsedMax : 4;

export default function (pi: ExtensionAPI) {
  const running = new Set<string>();
  let cwd: string | undefined;
  let hasUI = false;
  // Most recent dynamic pane; the next one is split off it, so they stack.
  let lastPane: string | undefined;
  // Ids of the dynamic panes this session opened and that may still exist.
  const openPanes = new Set<string>();

  const publish = () => pi.events.emit("suba:activity", { activeCount: running.size });

  function write(file: string, payload: object) {
    writeFileSync(`${file}.tmp`, JSON.stringify(payload));
    renameSync(`${file}.tmp`, file);
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
      write(join(dir, `${data.type}.json`), payload);
      write(join(dir, "by-id", `${data.id}.json`), { ...payload, type: data.type });
    } catch {
      // A read-only or vanished worktree must not break the session.
    }
  }

  // A layout pane (`pi-agent-pane <type>`) is alive while its claim file holds a live pid.
  function claimed(type: string): boolean {
    try {
      const pid = parseInt(readFileSync(join(cwd!, ".workmux", "agents", `${type}.pane`), "utf8"), 10);
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
    // Agents owned by a pi-subagents workflow are shown in its own workflow inspector;
    // a fan-out would otherwise open one pane per child without limit.
    if (typeof data.workflowId === "string") return;
    if (typeof data.id !== "string" || typeof data.type !== "string") return;
    if (!/^[\w.-]+$/.test(data.id) || !/^[\w.-]+$/.test(data.type)) return;
    if (claimed(data.type)) return;
    // Forget panes that have closed, then respect the cap.
    for (const id of [...openPanes]) {
      try {
        tmux("display", "-p", "-t", id, "#{pane_id}");
      } catch {
        openPanes.delete(id);
      }
    }
    if (openPanes.size >= MAX_PANES) return;
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
      openPanes.add(lastPane);
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
    openPanes.clear();
    running.clear();
  });
  // workmux-status asks once it has subscribed, in case agents already run.
  pi.events.on("suba:activity:request", publish);
  on("subagents:started", "working", true);
  on("subagents:completed", "done", false);
  on("subagents:failed", "failed", false);
}
