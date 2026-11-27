/**
 * Jev router: `jev/auto` uses a decision model to pick a Claude tier per user turn.
 *
 *   fast (Haiku)  <-  trivial questions, lookups, one-line edits
 *   balanced (Sonnet)  <-  ordinary features, fixes, reviews
 *   strong (Opus)  <-  design, hard debugging, cross-cutting changes
 *
 * How it decides, in order:
 *  1. Tool follow-ups stay on the model that started the turn (prompt cache, thinking signatures).
 *     Exception: after 3 failed tool calls in a row the turn moves up one tier, once.
 *  2. Retries stay on the failed model, unless the provider is overloaded or rate limited: then
 *     the same tier on another provider.
 *  3. A new user message is classified:
 *     - a bare acknowledgement ("ok", "tak", "dalej") keeps the current tier
 *     - "still broken" / "nadal nie działa" moves up one tier
 *     - otherwise a decision model rates the prompt (2.5 s budget); without one, the fast tier
 *       model rates it (5 s budget); keyword rules are the last resort
 *  4. A trivial question in a large conversation with a warm prompt cache stays on the current
 *     model: one cached request is cheaper than a cache miss on a smaller model.
 *
 * The thinking level of `router/auto` is a budget dial, not a reasoning effort:
 *   low = never above balanced, medium = free choice, high = never below balanced.
 *
 * Usage: pi --model jev/auto[:low|medium|high]     Debug: PI_JEV_ROUTER_DEBUG=1
 */

import type { Api, Message, Model, ModelThinkingLevel } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext, ModelRoute, ModelRouteRequest } from "@earendil-works/pi-coding-agent";

type Tier = "fast" | "balanced" | "strong";
const ORDER: Tier[] = ["fast", "balanced", "strong"];

/** Candidates per tier, first one with credentials wins. */
const PROVIDERS = ["claude-bridge", "anthropic", "radius"];
const TIERS: Record<Tier, { id: string; thinking: ModelThinkingLevel }> = {
	fast: { id: "claude-haiku-5-5", thinking: "low" },
	balanced: { id: "claude-sonnet-5-5", thinking: "medium" },
	strong: { id: "claude-opus-5-5", thinking: "high" },
};

/** Decision models to rate prompts with, in order of preference. */
const CLASSIFIERS: [provider: string, id: string][] = [
	["typesafe", "jev-latest"],
	["openai", "gpt-6-luna"],
];
const LOCAL_CLASSIFIER = /qwen|jev/i;
const CLASSIFY_TIMEOUT_MS = 2500;
const JUDGE_TIMEOUT_MS = 5000;

/** Prompt caches live about 5 minutes; below this size a cache miss is not worth avoiding. */
const CACHE_TTL_MS = 5 * 60_000;
const WARM_CACHE_MIN_TOKENS = 30_000;
const STUCK_AFTER_TOOL_ERRORS = 3;

const ACK = /^(ok(ay)?|yes|yep|sure|go( ahead)?|do it|continue|proceed|thanks?|lgtm|tak|dobra|dobrze|dalej|kontynuuj|zr[oó]b( to)?|dawaj|super|dzi[eę]ki)[\s.!]*$/i;
const FRUSTRATED = /(?<!\p{L})(still (not|doesn'?t|broken|fail)|doesn'?t work|not working|same error|again|wrong|nadal|wci[aą][zż]|dalej nie|nie dzia[lł]a|znowu|ten sam b[lł][aą]d|[zź]le)(?!\p{L})/iu;
const COMPLEX = /\b(architect|design|refactor|migrat|race condition|deadlock|concurren|security|vulnerab|performance|optimi[sz]e|root cause|investigat|debug|trade-?offs?|plan|architektur|zaprojektuj|refaktor|migracj|wydajno[sś]|bezpiecze[nń]stw|przeanalizuj|zbadaj|zdebuguj|zaplanuj)/i;
const TRIVIAL = /^(what('s| is)|where|which|show|list|print|rename|fix (the )?typo|how do i|co to|gdzie|kt[oó]ry|poka[zż]|wylistuj|wypisz|zmie[nń] nazw|popraw liter[oó]wk|jak)\b/i;

interface State {
	tier: Tier;
	/** Why this tier was chosen; shown in the footer. */
	why: string;
	/** The turn already moved up a tier after failed tool calls. */
	escalated?: boolean;
}
type Request = ModelRouteRequest<State>;

const debug = (...args: unknown[]) => process.env.PI_JEV_ROUTER_DEBUG && console.error("[jev-router]", ...args);
const up = (tier: Tier): Tier => ORDER[Math.min(ORDER.indexOf(tier) + 1, 2)];
const tierOf = (model?: Model<Api>): Tier | undefined => ORDER.find((tier) => TIERS[tier].id === model?.id);

function pick(ctx: ExtensionContext, tier: Tier, excludeProvider?: string): Model<Api> | undefined {
	for (const provider of PROVIDERS) {
		if (provider === excludeProvider) continue;
		const model = ctx.modelRegistry.find(provider, TIERS[tier].id);
		if (model && ctx.modelRegistry.hasConfiguredAuth(model)) return model;
	}
}

function textOf(message?: Message): string {
	const content = message?.content ?? "";
	if (typeof content === "string") return content;
	return content.flatMap((block) => (block.type === "text" ? [block.text] : [])).join("\n");
}

/** Failed tool results at the end of the conversation, without a success in between. */
function trailingToolErrors(messages: readonly Message[]): number {
	let errors = 0;
	for (let i = messages.length - 1; i >= 0; i--) {
		const message = messages[i];
		if (message.role === "assistant") continue;
		if (message.role !== "toolResult" || !message.isError) break;
		errors++;
	}
	return errors;
}

function byKeywords(prompt: string): { tier: Tier; why: string } {
	if (COMPLEX.test(prompt) || prompt.length > 1500) return { tier: "strong", why: "rules: complex" };
	if (prompt.length < 160 && TRIVIAL.test(prompt.trim())) return { tier: "fast", why: "rules: trivial" };
	return { tier: "balanced", why: "rules: standard" };
}

let classifier: Promise<ReturnType<ExtensionContext["modelRegistry"]["findOfType"]> | undefined> | undefined;

/** First preferred Jev-compatible decision model with credentials, looked up once per process. */
function findClassifier(ctx: ExtensionContext) {
	classifier ??= ctx.modelRegistry
		.getAvailableOfType("classifier")
		.then((available) => {
			const local = available.find((model) => model.provider === "llama.cpp" && LOCAL_CLASSIFIER.test(model.id));
			if (local) return local;
			for (const [provider, id] of CLASSIFIERS) {
				const found = available.find((model) => model.provider === provider && model.id === id);
				if (found) return found;
			}
		})
		.catch(() => undefined);
	return classifier;
}

async function byClassifier(request: Request, ctx: ExtensionContext, prompt: string, previousReply: string) {
	const model = await findClassifier(ctx);
	if (!model) return undefined;
	const timeout = AbortSignal.timeout(CLASSIFY_TIMEOUT_MS);
	const result = await ctx.modelRegistry.classify(
		model,
		{
			state: { prompt: prompt.slice(0, 8000), previous_assistant_reply: previousReply.slice(-1500) },
			questions: {
				difficulty: {
					type: "choice",
					instructions:
						"How demanding is the work a coding agent must do to answer `prompt`? `previous_assistant_reply` is context only.",
					criteria: {
						trivial: "A quick factual answer, lookup, single command, or one-line mechanical edit",
						standard: "An ordinary feature, bug fix, review, explanation, or multi-file edit with a clear path",
						complex: "Subtle design, architecture, hard debugging, cross-cutting changes, or ambiguous requirements",
					},
				},
			},
		},
		{ signal: request.signal ? AbortSignal.any([request.signal, timeout]) : timeout },
	);
	const answer = result.stopReason === "stop" ? result.answers.difficulty : undefined;
	if (answer?.type !== "choice") {
		debug("classifier failed:", result.errorMessage ?? result.stopReason);
		return undefined;
	}
	const p = answer.probabilities;
	const pct = (value = 0) => Math.round(value * 100);
	// Under-powering a hard task costs more than over-powering an easy one: lean upward when unsure.
	let tier: Tier = "balanced";
	if ((p.complex ?? 0) >= 0.4) tier = "strong";
	else if ((p.trivial ?? 0) >= 0.7) tier = "fast";
	return { tier, why: `${model.id}: ${answer.choice} ${pct(p[answer.choice])}%` };
}

/** Without a decision model: ask the fast tier model for a one-word rating. */
async function byJudge(request: Request, ctx: ExtensionContext, prompt: string, previousReply: string) {
	const model = pick(ctx, "fast");
	if (!model) return undefined;
	const timeout = AbortSignal.timeout(JUDGE_TIMEOUT_MS);
	const context = previousReply ? `<previous_assistant_reply>\n${previousReply.slice(-1500)}\n</previous_assistant_reply>\n` : "";
	try {
		const reply = await ctx.modelRegistry
			.streamSimple(
				model,
				{
					systemPrompt:
						"You rate how demanding a request is for a coding agent. Do not answer the request. Judge the reasoning and " +
						"expertise it needs, not the length of the answer it asks for. Reply with one word:\n" +
						"trivial: a quick factual answer, lookup, single command, or one-line mechanical edit\n" +
						"standard: an ordinary feature, bug fix, review, explanation, or multi-file edit with a clear path\n" +
						"complex: subtle design, architecture, hard debugging, cross-cutting changes, or ambiguous requirements",
					messages: [
						{ role: "user", content: `${context}<request>\n${prompt.slice(0, 8000)}\n</request>`, timestamp: Date.now() },
					],
				},
				{ maxTokens: 16, signal: request.signal ? AbortSignal.any([request.signal, timeout]) : timeout },
			)
			.result();
		const word = textOf(reply).toLowerCase().match(/trivial|standard|complex/)?.[0];
		if (reply.stopReason !== "stop" || !word) {
			debug("judge failed:", reply.errorMessage ?? reply.stopReason);
			return undefined;
		}
		const tier: Tier = word === "trivial" ? "fast" : word === "complex" ? "strong" : "balanced";
		// A hard topic phrased as a short question still deserves more than the fast tier.
		if (tier === "fast" && COMPLEX.test(prompt)) return { tier: "balanced", why: "judge: trivial, but a hard topic" };
		return { tier, why: `judge: ${word}` };
	} catch (error) {
		debug("judge failed:", error);
		return undefined;
	}
}

async function routeUserTurn(request: Request, ctx: ExtensionContext): Promise<ModelRoute<State>> {
	const lastUser = request.messages.findLast((message) => message.role === "user");
	const lastReply = request.messages.findLast((message) => message.role === "assistant");
	const prompt = textOf(lastUser);
	const previousTier = request.state?.tier ?? tierOf(request.previous?.model);

	let decision: { tier: Tier; why: string };
	if (previousTier && ACK.test(prompt.trim())) {
		decision = { tier: previousTier, why: "acknowledgement: same tier" };
	} else if (previousTier && prompt.length < 400 && FRUSTRATED.test(prompt)) {
		decision = { tier: up(previousTier), why: "not solved yet: one tier up" };
	} else {
		const reply = textOf(lastReply);
		decision =
			(await byClassifier(request, ctx, prompt, reply)) ?? (await byJudge(request, ctx, prompt, reply)) ?? byKeywords(prompt);
	}

	// The selected level is a budget dial.
	let { tier, why } = decision;
	if (request.thinkingLevel === "low" && tier === "strong") [tier, why] = ["balanced", `${why}, capped by :low`];
	if (request.thinkingLevel === "high" && tier === "fast") [tier, why] = ["balanced", `${why}, raised by :high`];

	// A one-shot answer over a large, still cached conversation: stay where the cache is.
	const previous = request.previous;
	if (tier === "fast" && previous && previousTier && previousTier !== "fast" && lastReply?.role === "assistant") {
		const usage = lastReply.usage;
		const contextTokens = usage.input + usage.cacheRead + usage.cacheWrite;
		const warm = Date.now() - lastReply.timestamp < CACHE_TTL_MS;
		if (warm && contextTokens >= WARM_CACHE_MIN_TOKENS && ctx.modelRegistry.hasConfiguredAuth(previous.model)) {
			return finish(ctx, previous.model, previous.thinkingLevel ?? TIERS[previousTier].thinking, {
				tier: previousTier,
				why: `${why}, kept on warm cache`,
			});
		}
	}

	return finish(ctx, pick(ctx, tier), TIERS[tier].thinking, { tier, why });
}

function finish(ctx: ExtensionContext, model: Model<Api> | undefined, thinkingLevel: ModelThinkingLevel, state: State) {
	if (!model) throw new Error(`jev-router: no credentials for ${TIERS[state.tier].id} on ${PROVIDERS.join(", ")}`);
	debug(`${state.tier} -> ${model.provider}/${model.id}:${thinkingLevel} (${state.why})`);
	if (ctx.hasUI) ctx.ui.setStatus("jev-router", `jev → ${state.tier} · ${state.why}`);
	return { model, thinkingLevel, state };
}

export default function (pi: ExtensionAPI) {
	pi.registerVirtualModel<State>({
		provider: "jev",
		id: "auto",
		name: "Auto (Jev → Claude)",
		thinkingLevels: ["low", "medium", "high"],
		// Shared by all three tiers; shown before the first response.
		contextWindow: 1_000_000,
		maxTokens: 128_000,
		async route(request, ctx) {
			const { reason, previous, failed, state } = request;

			// Compaction summaries and other requests outside the agent loop.
			if (reason === "direct") {
				const model = pick(ctx, "balanced") ?? previous?.model;
				if (!model) throw new Error("jev-router: no model with credentials");
				return { model, thinkingLevel: "low" };
			}

			if (reason === "retry" && failed) {
				const overloaded = /overload|rate.?limit|capacity|quota|too many requests|\b(429|503|529)\b/i.test(
					failed.message.errorMessage ?? "",
				);
				const tier = tierOf(failed.model) ?? state?.tier ?? "balanced";
				const other = overloaded ? pick(ctx, tier, failed.model.provider) : undefined;
				if (other) debug(`retry: ${failed.model.provider} overloaded -> ${other.provider}/${other.id}`);
				return { model: other ?? failed.model, thinkingLevel: failed.thinkingLevel ?? TIERS[tier].thinking };
			}

			if (reason !== "user" && previous) {
				const tier = state?.tier ?? tierOf(previous.model);
				const stuck = trailingToolErrors(request.messages) >= STUCK_AFTER_TOOL_ERRORS;
				if (stuck && tier && tier !== "strong" && !state?.escalated && request.thinkingLevel !== "low") {
					const next = up(tier);
					const model = pick(ctx, next);
					if (model) {
						return finish(ctx, model, TIERS[next].thinking, {
							tier: next,
							why: `${STUCK_AFTER_TOOL_ERRORS} failed tool calls: one tier up`,
							escalated: true,
						});
					}
				}
				return { model: previous.model, thinkingLevel: previous.thinkingLevel ?? "medium" };
			}

			return routeUserTurn(request, ctx);
		},
	});
}
