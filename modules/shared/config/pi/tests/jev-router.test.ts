/**
 * CO-117: jev/auto must keep working after an in-process subagent session (which shares the
 * parent's ModelRuntime and loads the same extensions) is disposed.
 *
 * Run: node --test modules/shared/config/pi/tests/jev-router.test.ts   (node >= 23.6)
 * The pi SDK is taken from $PI_SDK_DIR (default: the pi-clean install).
 */
import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { join } from "node:path";
import { after, before, beforeEach, describe, test } from "node:test";
import { pathToFileURL } from "node:url";
import jevRouter from "../jev-router.ts";

const SDK_DIR = process.env.PI_SDK_DIR ?? join(homedir(), "dev/pi-clean/node_modules/@earendil-works/pi-coding-agent");
const sdk: any = await import(pathToFileURL(join(SDK_DIR, "dist/index.js")).href);
const { createAgentSession, DefaultResourceLoader, SessionManager, SettingsManager } = sdk;

const STALE = /stale/;
let dir: string;

before(() => {
	dir = mkdtempSync(join(tmpdir(), "jev-router-test-"));
	// The router needs a physical model with credentials to route to.
	process.env.ANTHROPIC_API_KEY ||= "test-key";
});
beforeEach(() => {
	delete (globalThis as Record<symbol, unknown>)[Symbol.for("pi-clean.jev-router.owner")];
});
after(() => rmSync(dir, { recursive: true, force: true }));

async function newSession(modelRuntime?: unknown) {
	const settingsManager = SettingsManager.inMemory();
	const resourceLoader = new DefaultResourceLoader({
		cwd: dir,
		agentDir: dir,
		settingsManager,
		noExtensions: true,
		noSkills: true,
		noPromptTemplates: true,
		noThemes: true,
		noContextFiles: true,
		extensionFactories: [jevRouter],
	});
	await resourceLoader.reload();
	const { session } = await createAgentSession({
		cwd: dir,
		agentDir: dir,
		settingsManager,
		resourceLoader,
		sessionManager: SessionManager.inMemory(dir),
		...(modelRuntime ? { modelRuntime } : {}),
	});
	await session.bindExtensions({});
	return session;
}

/** Route a request outside the agent loop (reason "direct"): no network, no classifier. */
async function routeDirect(session: any) {
	const runtime = session.modelRuntime;
	const virtual = runtime.getModel("jev", "auto");
	assert.ok(virtual, "jev/auto is registered");
	return runtime.resolveModel(virtual, [{ role: "user", content: "hi", timestamp: Date.now() }], {
		reason: "direct",
		thinkingLevel: "medium",
	});
}

describe("jev-router", () => {
	test("parent keeps routing jev/auto after a subagent session sharing its runtime is disposed", async () => {
		const parent = await newSession();
		try {
			const before = await routeDirect(parent);
			assert.equal(before.model.id, "claude-sonnet-5-5");

			// What @tintinweb/pi-subagents does: a child session on the parent's ModelRuntime, same extensions.
			const child = await newSession(parent.modelRuntime);
			child.dispose();

			const after = await routeDirect(parent).catch((error: Error) => error);
			assert.ok(!(after instanceof Error), `routing failed: ${(after as Error).message}`);
			assert.doesNotMatch(String((after as any)?.message), STALE);
			assert.equal(after.model.id, "claude-sonnet-5-5");
		} finally {
			parent.dispose();
		}
	});

	for (const shutdownEvent of [true, false]) {
		test(`jev/auto is registered again after the owning session is replaced (${shutdownEvent ? "session_shutdown, then dispose" : "dispose only"})`, async () => {
			const first = await newSession();
			const runtime = first.modelRuntime;
			const owner = (globalThis as Record<symbol, any>)[Symbol.for("pi-clean.jev-router.owner")];
			assert.ok(owner?.pi, "first session owns the registration");
			if (shutdownEvent) {
				await first.extensionRunner.emit({ type: "session_shutdown", reason: "reload" });
				assert.equal(owner.pi, undefined, "owner released on session_shutdown");
			}
			first.dispose();

			const second = await newSession(runtime);
			try {
				const routed = await routeDirect(second);
				assert.equal(routed.model.id, "claude-sonnet-5-5");
			} finally {
				second.dispose();
			}
		});
	}
});
