# Analysis of `claude-brain`

Claude Brain is a plugin for [Claude
Code](https://claude.com/product/claude-code). This analysis was performed
against `claude-brain` at revision
[`5df71f7`](https://github.com/memvid/claude-brain/commit/5df71f77aafa4ec50e7fd4672997b6da7e2c3198)
which was the tip of the `main` branch at the time of writing, 2026-02-20.

## Source code

There is, admittedly, not much to say regarding this plugin. It is available at
`memvid/claude-brain` on [GitHub](https://github.com/memvid/claude-brain),
complete with instructions for how to add the repository itself as a
"Marketplace" to allow installing the plugin into Claude Code. The source code
appears complete and is licensed under
[MIT](https://spdx.org/licenses/MIT.html).

Unlike the [CLI analysis](./cli.md), there is no license nullity issue here ---
the plugin is properly open-source with full source code available.

## Dependencies

The plugin depends, via `package.json` on `@memvid/sdk` which, in turn, depends
on a platform-specific vendored binary distribution --- on my machine, that is
`@memvid/sdk-linux-x64-gnu`, specifically version `2.0.157`.

The SDK will get it's [own analysis](./sdk.md), so I will only mention that the
JS SDK is a hard requirement for using the `claude-brain` plugin.

## Technical Implementation

### Search and Memory Retrieval

Despite marketing claims of "photographic memory" and intelligent semantic
search, the actual implementation in `mind.ts` uses purely lexical (keyword)
matching:

```typescript
// Line 233 in mind.ts
async search(query: string, limit = 10): Promise<MemorySearchResult[]> {
  return this.withLock(async () => {
    return this.searchUnlocked(query, limit);
  });
}

private async searchUnlocked(query: string, limit: number): Promise<MemorySearchResult[]> {
  const results = await this.memvid.find(query, { k: limit, mode: "lex" });
  // ...
}

// Line 251 in mind.ts
async ask(question: string): Promise<string> {
  return this.withLock(async () => {
    const result = await this.memvid.ask(question, { k: 5, mode: "lex" });
    return result.answer || "No relevant memories found.";
  });
}
```

Both `search()` and `ask()` explicitly use `mode: "lex"` (lexical search),
which is keyword matching rather than semantic/vector search. The plugin itself
contains zero embedding generation or vector search logic.

### "Intelligent" Compression

The plugin's "ENDLESS MODE" compression (`compression.ts`) is described as
allowing "20x more tool uses before hitting context limits." The actual
implementation uses regex pattern extraction:

- **File reads**: Extracts imports, exports, function signatures, class names
  via regex patterns like
  `/import\s+(?:{\s*([^}]+)\s*}|(\w+))\s+from\s+['"]([^'"]+)['"]/g`
- **Bash output**: Filters for lines containing "error", "failed", "success",
  "passed"
- **Grep/Glob**: Summarizes match counts and file lists
- **Generic fallback**: First 15 + last 10 lines

The compression is reasonable engineering for its purpose, but the framing as
"ENDLESS MODE" and "intelligent extraction" oversells what is straightforward
text truncation and pattern matching.

### Observation Classification

The "intelligent" classification of observations (`classifyObservationType()`
in `helpers.ts`) uses simple keyword matching on tool outputs:

- Contains "error" or "failed" → `"problem"`
- Contains "fix" → `"bugfix"`
- Contains "add" or "create" → `"feature"`
- Tool is "Edit" or "Write" → `"refactor"`
- Everything else → `"observation"`

### Memory Capture Limitations

The `PostToolUse` hook (`post-tool-use.ts`) captures tool outputs from a
hardcoded set:

```typescript
const OBSERVED_TOOLS = new Set([
  "Read",
  "Edit",
  "Write",
  "Update",
  "Bash",
  "Grep",
  "Glob",
  "WebFetch",
  "WebSearch",
  "Task",
  "NotebookEdit",
]);
```

For my purposes, I'll note the _glaring_ omission of all Todo-related tools; in
my humble opinion, one of the most critical tools to record across sessions.

Additionally, the code includes a workaround comment acknowledging a Claude
Code bug:

```typescript
/**
 * WORKAROUND: Since PostToolUse doesn't fire for Edit operations (Claude Code bug),
 * we capture git diff at session end to record all file modifications.
 */
```

This means:

- File edits are not captured in real-time during the session
- Edit context is only available via `git diff` scraping at session end
- If Claude Code crashes or exits unexpectedly, all edit context is lost
- The "photographic memory" becomes "end-of-session recollection"

### File Discovery Fallback

When not in a git repository, the `stop.ts` hook falls back to searching for
recently modified files using this command:

```bash
find . -maxdepth 4 -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" \
  -o -name "*.jsx" -o -name "*.md" -o -name "*.json" -o -name "*.py" \
  -o -name "*.rs" \) -mmin -30 ! -path "*/node_modules/*" ! -path "*/.git/*" \
  ! -path "*/dist/*" ! -path "*/build/*" ! -path "*/.next/*" \
  ! -path "*/target/*" 2>/dev/null | head -30
```

This means that if you're working outside a git repository and editing files in
any other language (Bash, Nix, Dhall, Haskell, HTML, CSS, to name some of my
favorites), those changes won't be captured in your "memory" at all.

## Claims

Again, nothing strictly against any rules, but I want to highlight some claims
in light of what the SDK analysis will reveal.

Specifically, toward the end of the README, in the FAQ section, is the note

> **Is it private?**
>
> 100% local. Nothing leaves your machine. Ever.

Now, we can already point to the [CLI analysis](./cli.md) --- a CLI which is
mentioned and referenced in this README, I should add --- where we have
undisclosed telemetry. So for a pretty reasonable read of what _"nothing"_
means, that isn't true.

Similarly, the README notes

> No database. No cloud. No API keys.

Here, we have two angles. First, again, the CLI, which whines about not having
any API keys on every invocation, and some mentions in the CLI documentation of
how to provide API keys. Secondly, Memvid's [own
website](https://memvid.com/pricing) outlines pricing tiers and storage levels.
Specifically, "On-premise deployment options" and "SLA guarantee" mentioned
under the "Pro" tier explicitly hint at there indeed being a cloud. In case
this is changed, see the [screenshot](../screenshots/260220-pricing.png).

Maybe that's not applicable to `claude-brain` specifically? I am not sure.

## Summary

`claude-brain` is not the problem. It is the entrypoint to the problem and,
indeed, how I decided to do this investigation in the first place. The plugin
claims to solve a real problem and at least tries to deliver on that claim.

The problem is everything else it delivers but doesn't tell you about.
