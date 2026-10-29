---
name: prose-cleanup
description: Rewrite technical prose (docs, code comments, READMEs) to remove clanker writing patterns.
disable-model-invocation: true
---

# Prose cleanup

Rewrite the target so it reads like a competent engineer wrote it for other engineers. The target is whatever the command names (files, a diff, pasted text); without one, use the prose you most recently wrote in this session. Edit files in place. If the user asks for a review only, list findings with locations instead of editing.

## Ground rules

- Keep the meaning, technical facts, code, identifiers, commands, links and the file's existing conventions (heading style, line wrapping, comment syntax).
- Never add claims. When a statement looks wrong or unverified and you can check it against the code, check it. Otherwise flag it.
- Cut before rewording. Most AI prose fails on content, not vocabulary: a sentence that says nothing should go, not get a better synonym. Replace a word only when the sentence carries information.
- One occurrence of a pattern is rarely the problem. Repetition and clusters are. Exception: remove every em dash and every semicolon in prose.

## Two passes

1. **Content.** Does each sentence, section, bullet and comment earn its place for this reader? Delete restatements, summaries of what was just said, sections without content and explanations of the obvious. Replace vague claims with the specific number, case, command or behavior, or delete them.
2. **Patterns.** Fix what remains against the catalog below.

## Catalog

**Filler and signposting**: "Here's how/why/what", "Let's", "In this section", "This document describes", "Overview" sections that restate the title, "In summary", "To sum up", "It's worth noting", "Note that", "Importantly", "Notably", "Interestingly", "At its core", "When it comes to", "The truth is", "The real X is", "It turns out".

**Inflated vocabulary**: powerful, seamless, robust, comprehensive, cutting-edge, game-changing, elegant, crucial, essential, delve, leverage, utilize, harness, facilitate, streamline, empower, enhance, landscape, ecosystem, paradigm. "Serves as", "stands as", "represents" where "is" works.

**Empty adverbs**: simply, just, easily, really, truly, actually, fundamentally, seamlessly, quietly, effortlessly. Keep adverbs with technical meaning (atomically, lazily, recursively, asynchronously).

**Hedges and inflation**: "may potentially", "can help to", "aims to"; claims of significance without evidence ("significantly improves", "greatly simplifies"); vague attributions ("best practice says", "it is widely recommended"); sweeping "always", "never", "every", "all" unless literally true.

**Rhetorical structures**:

- "Not X, but Y", "X isn't the problem, Y is", "not just X but also Y": state Y.
- "Not X. Not Y. Z.": state Z.
- "The result? It works.": make the statement.
- Trailing participle that adds fake analysis: "..., ensuring consistency across the codebase", "..., making it easy to extend". Keep it only if it states a real effect.
- "From X to Y" where X and Y are not on a scale.
- "Think of it as...", invented labels ("the config drift problem") used as if established.
- Repeated sentence openings, back-to-back lists of three, "The first... The second..." prose that is really a list.

**Rhythm**: sentences of uniform length, paragraphs that all end on a punchy one-liner, stacked short fragments for emphasis ("Fast. Simple. Reliable."). Vary length and use complete sentences.

**Formatting tells**: bold lead-in on every bullet, emoji in headings, bullets, logs or commit text, decorative unicode (→, ✓, curly quotes) where ASCII is expected, any em dash or semicolon in prose (use a comma, colon, parentheses or a new sentence), headings over every short paragraph, nested bullets for flat content, bold for emphasis on every other phrase.

## By target

**Code comments**: explain why, invariants, constraints and non-obvious behavior. Delete comments that restate the code, narrate history ("now uses", "previously", "refactored to", "added"), refer to the task or conversation ("as requested", "fix for the bug"), or act as section banners. Doc comments describe the contract; drop `@param name The name` lines that repeat the signature. Start with the content, not "This function".

**Docs**: second person, present tense ("returns", not "will return"), imperative steps. One term per concept. A concrete example beats an abstract description. Prerequisites only when non-obvious.

**README**: open with what it is in one or two sentences and the shortest path to using it. Copy-pasteable commands in code blocks. No adjective feature lists, badge walls, "Why X?" pitches, table of contents for short files, or "Contributing" and "License" sections without real content.

## Do not over-correct

- Passive voice is fine when the actor is irrelevant ("the hook is called before each commit").
- Inanimate subjects are normal in technical writing ("the parser rejects trailing commas").
- Keep a list of three when there are three things, and a short sentence when it is the clearest form.
- Keep established domain terms, even long ones.

## Examples

The specifics in each "After" come from the code, never from invention.

Comment:

> Before: `// Initialize the cache to ensure optimal performance and seamless data access`
> After: `// Warm the cache here: the first request otherwise blocks for ~2s on the index load`

README:

> Before: "🚀 **Blazing fast**: dotsync is a powerful tool that empowers you to seamlessly manage your dotfiles across machines."
> After: "dotsync links the files in this repository into `$HOME` and backs up any file it replaces."

## Finish

Reread the result once against the catalog. Report in a few lines what changed and any flagged claims.
