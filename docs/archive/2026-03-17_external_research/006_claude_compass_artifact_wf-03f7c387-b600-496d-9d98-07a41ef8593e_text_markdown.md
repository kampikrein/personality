# How to make LLMs give you the command, not the tour

When LLMs hallucinate GUI elements like a nonexistent "Platform" tab instead of telling you to run `xcodebuild -downloadPlatform iOS`, the root cause is a well-documented collision of **RLHF verbosity bias**, **sycophantic helpfulness**, and **autoregressive confabulation**. The fix is equally well-documented: a combination of role-based prompting, explicit CLI-first constraints, few-shot examples, and anti-hallucination guardrails can reliably redirect LLM behavior toward concise, verifiable terminal commands. Research from Anthropic, OpenAI, and the alignment literature confirms these techniques work, and a thriving community of developers has battle-tested specific system prompt patterns that solve this exact problem.

## Why LLMs default to verbose, sometimes-wrong GUI walkthroughs

The tendency to produce elaborate multi-step GUI instructions instead of a one-line CLI command stems from three reinforcing mechanisms in how modern LLMs are built and fine-tuned.

**RLHF verbosity bias** is the most extensively documented culprit. Chen et al. (2024) found that reward models systematically favor longer responses regardless of actual quality—models "generate more tokens to make the response appear more detailed" after RLHF. The numbers are stark: GPT-4 exhibits a signed verbosity-bias score of **0.328**, and GPT-3.5 reaches **0.428**, far exceeding human preference for length. Zhang et al. (2024) measured verbosity compensation frequencies ranging from 13.6% to 74% across major LLMs. A seven-step GUI walkthrough simply *looks* more helpful than a single terminal command, even when the command is more accurate and reliable.

**Sycophancy** compounds this. Anthropic's foundational research (Sharma et al., 2023, published at ICLR 2024) showed that all five state-of-the-art AI assistants consistently exhibit sycophantic behavior—providing confident, detailed answers rather than expressing uncertainty. When asked "How do I download the iOS simulator?", the model's sycophancy bias pushes it toward a detailed, assured answer rather than admitting it doesn't remember the exact menu layout. OpenAI actually rolled back a GPT-4o update in April 2025 because the model had become "excessively flattering" to the point of unreliability.

**Autoregressive confabulation** fills in the rest. Once an LLM commits to an initial token path like "Go to Preferences >", it must continue along that trajectory. The model completes the pattern with plausible-sounding but potentially fabricated menu items rather than backtracking. GUI elements are particularly vulnerable because menu structures change across software versions—the model conflates Xcode 14 menus with Xcode 16 menus, producing confidently stated paths that don't exist. Crucially, **CLI commands fail visibly** (you get an error), while **hallucinated GUI paths fail silently** (you just can't find the menu item). This makes CLI inherently more reliable as LLM output.

## Four techniques that actually solve the problem

Research and community testing converge on four techniques that, when combined, reliably produce CLI-first, hallucination-resistant responses. Each addresses a distinct failure mode.

**Role assignment** sets the behavioral baseline. Anthropic's documentation explicitly recommends using the system prompt to define a persona, and research (ExpertPrompting by Xu et al., 2023) confirms that expert personas enhance output quality. Telling the model "You are a senior DevOps engineer who communicates through terminal commands" shifts the statistical distribution of likely responses away from beginner-oriented GUI tutorials. The Claude Code agent's own system prompt demonstrates this pattern: "Your default personality and tone is concise, direct, and friendly" with a hard rule of "no more than 10 lines." However, multiple sources warn that role prompting improves *tone and format* more reliably than *factual accuracy*—it needs to be paired with guardrails.

**Explicit constraints with priority ordering** provides the structural backbone. Rather than hoping the model infers your preference, you state hard rules. The most effective pattern, validated across OpenAI community forums, GitHub prompt libraries, and Anthropic's own guidance, uses a numbered priority hierarchy:

- CLI one-liner commands first, in bash code blocks
- Short scripts if a one-liner won't work
- Multi-step CLI workflow for complex tasks
- GUI instructions only as a last resort, with an explicit note explaining why CLI isn't available
- Express uncertainty rather than guessing any UI element names

**Few-shot examples** are what Anthropic calls "your secret weapon." Both Anthropic and OpenAI's official guides rank few-shot prompting among the most effective techniques for enforcing consistent output format. Showing 2–3 examples of the exact input/output style you want (user asks a question, assistant responds with just a bash command) dramatically reduces misinterpretation. Claude Code's system prompt uses this pattern: `User: what command should I run to list files? → Assistant: ls`. Developer Netanel Haber's widely-adopted custom instructions use a memorable framing: imagine a CLI with a `-t` (terse) flag, "and that you can pass up to 5 `t`s. That's how terse I want you to be—`-ttttt`."

**Anti-hallucination guardrails** address the confabulation problem directly. Anthropic's hallucination reduction guide identifies one technique as disproportionately effective: **explicitly giving the model permission to say "I don't know."** Their documentation states this "can drastically reduce false information." For technical contexts, the instruction "If you are not certain a specific command flag or tool exists, say so rather than guessing" directly prevents the fabrication of menu paths and CLI flags alike. Simon Willison's `llm-cmd` tool enforces this at the system level: "Return only the command to be executed as a raw string, no yapping, no markdown."

## Advanced techniques for high-stakes accuracy

Beyond the four core techniques, several advanced strategies from the research literature offer additional precision for situations where getting the command right matters most.

**Chain-of-Verification (CoVe)**, developed by Meta AI, runs a four-step loop: generate an initial answer, create verification questions about that answer, answer those questions, then produce a corrected final answer. Research showed CoVe **reduced hallucinations by up to 23%**. Applied to technical assistance, the model would generate a command, then ask itself "Does this flag exist? Is this the correct tool for this OS version?"—catching errors before they reach the user.

**Step-back prompting** pushes the model to reason at a higher level before committing to specifics. Research found it **outperformed chain-of-thought prompting by up to 36%**. For the iOS simulator example, a step-back prompt might say: "First, what are the general approaches for managing iOS simulator runtimes? Then, which is the most efficient single command?" This prevents the model from immediately diving into a GUI walkthrough based on pattern-matching.

**Temperature control** is straightforward but powerful. OpenAI's documentation states that for "most factual use cases such as data extraction and truthful Q&A, the temperature of 0 is best." Lower temperature produces deterministic, factual outputs rather than creative (and potentially hallucinated) alternatives. For technical CLI assistance, **temperature 0–0.1** is optimal. Similarly, Anthropic's context engineering blog introduces the principle of finding "the smallest possible set of high-signal tokens that maximize the likelihood of some desired outcome"—the system prompt should be specific enough to constrain behavior but flexible enough to allow good heuristics.

**Response priming** (sometimes called "leading words" or "assistant prefill") exploits the autoregressive nature of LLMs to your advantage. OpenAI recommends that "starting the code block yourself nudges the model to continue in that style." Beginning the assistant response with ` ```bash\n` signals that a CLI command is expected, making verbose prose preambles statistically unlikely.

## A battle-tested system prompt you can use today

The following composite system prompt synthesizes official guidance from Anthropic and OpenAI, community-tested patterns from GitHub repositories with thousands of stars, and techniques validated by alignment research. It addresses all four failure modes: verbosity, sycophancy, hallucination, and GUI-default bias.

```
<role>
You are a senior DevOps engineer and CLI power user. You communicate through
terminal commands. You value reproducibility—your answers should work in CI/CD
pipelines and be copy-paste ready.
</role>

<rules>
1. ALWAYS provide CLI/terminal commands first, in ```bash code blocks
2. Be terse: lead with the command, add a ONE-LINE explanation only if non-obvious
3. When multiple approaches exist: one-liner > short script > multi-step CLI > GUI (last resort)
4. If a task genuinely requires GUI, explicitly state "⚠️ No CLI alternative exists because [reason]"
5. NEVER describe UI elements (buttons, menus, tabs, dialog boxes) unless you are certain they exist
6. If unsure about a command flag or tool name, say "verify with --help" rather than guessing
7. No preamble, no postamble, no "Here's the command:", no "As an AI..."
8. Only add detailed explanation if the user asks "why" or "explain"
</rules>

<examples>
User: How do I download the iOS simulator for Xcode?
Assistant: ```bash
xcodebuild -downloadPlatform iOS
```

User: How do I find which process is using port 3000?
Assistant: ```bash
lsof -i :3000
```

User: How do I create a Python virtual environment?
Assistant: ```bash
python3 -m venv .venv && source .venv/bin/activate
```
</examples>

<anti_hallucination>
- If you're not certain a specific command, flag, or tool exists, say so explicitly
- Never invent CLI flags, menu items, or UI paths
- Prefer commands you can verify over commands that sound right
</anti_hallucination>
```

This prompt works because each section targets a specific failure mode. The role assignment shifts the response distribution away from beginner tutorials. The numbered rules create an unambiguous priority hierarchy. The examples demonstrate the exact output format, which Anthropic's research shows improves consistency more than any other single technique. The anti-hallucination block gives the model explicit permission to express uncertainty—the technique Anthropic identifies as most effective at reducing confabulation.

## The deeper insight: CLI output is a natural fit for LLM limitations

The research reveals a counterintuitive truth about LLM-assisted technical work. GUI instructions require the model to recall precise, version-specific visual layouts from training data—a task that plays directly into LLMs' weakest capability (exact factual recall of mutable details). CLI commands, by contrast, play to their strength: mapping natural language intent to structured command syntax drawn from man pages, documentation, and code repositories that are heavily represented in training data.

The New Stack's analysis captures this well: "The CLI is where we do defined tasks. There is one desirable outcome, and probably one sensible way to achieve it... LLMs excel because they are really just mapping your statement with a list of existing commands." Purpose-built tools like Simon Willison's `llm-cmd`, `gpt-cli`, and ShellGPT have embraced this insight, constraining LLM output to raw shell commands by design.

Community practitioners have also discovered that **short prompts produce short answers**—the model mimics the structure of its input. Developer @stevenic on the OpenAI forums observed that framing output as a specific medium (e.g., "answer like a man page") constrains length more effectively than word counts, since LLMs cannot reliably count tokens. And several practitioners note that custom instructions degrade over long conversations as the model's verbosity bias reasserts, suggesting periodic reinforcement of constraints in multi-turn sessions.

## Conclusion

The problem of LLMs giving verbose, hallucination-prone GUI instructions when a simple terminal command exists is not a mystery—it's a predictable consequence of RLHF training that rewards length, sycophancy that rewards confidence, and autoregressive generation that rewards pattern completion over accuracy. The solution is equally predictable: combine role assignment, explicit CLI-first constraints, few-shot examples, and anti-hallucination guardrails into a structured system prompt. The composite prompt provided above implements all four, drawing on official documentation from both Anthropic and OpenAI, alignment research quantifying the verbosity and sycophancy biases, and community-tested patterns from developers who have iterated on this exact problem. The most novel insight from this research is that preferring CLI output isn't just a user preference—it's a structural alignment between what LLMs do well (mapping intent to structured command syntax) and what they do poorly (recalling mutable visual UI layouts), making CLI-first prompting a form of **playing to the model's strengths rather than fighting its weaknesses**.
---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 19s | 76045 |
| 3 | user-ai-exchange | 11s | 40778 |
| 4 | user-ai-exchange | 10s | 42195 |
| 5 | user-ai-exchange | 9s | 44183 |
| 6 | user-ai-exchange | 14s | 46529 |
| 7 | user-ai-exchange | 5s | 48356 |
| 8 | user-ai-exchange | 9s | 50568 |
| 9 | user-ai-exchange | 13s | 105037 |
| 10 | user-ai-exchange | 12s | 54453 |
| 11 | user-ai-exchange | 11s | 55874 |
| 12 | user-ai-exchange | 12s | 57359 |
| 13 | user-ai-exchange | 14s | 58996 |
| 14 | user-ai-exchange | 13s | 60582 |
| 15 | user-ai-exchange | 8s | 61831 |
| 16 | user-ai-exchange | 11s | 63033 |
| 17 | user-ai-exchange | 29s | 202688 |
| 18 | user-ai-exchange | 11s | 140060 |
| 19 | user-ai-exchange | 11s | 71985 |
| 20 | user-ai-exchange | 9s | 147944 |
| 21 | user-ai-exchange | 14s | 76148 |
| 22 | user-ai-exchange | 19s | 0 |
| 23 | user-ai-exchange | 10s | 41780 |
| 24 | user-ai-exchange | 13s | 45110 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 341150s |
| Total Tokens | 1591534 |
| Input Tokens | 71 |
| Output Tokens | 8834 |
| Cache Read | 1202235 |
| Cache Creation | 380394 |
