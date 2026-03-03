From: Memvid Company <contact@memvid.com>

To: J. A. Hultén <jonas@sldr.se>

Subject: Re: GDPR Data Subject Access Request

Timestamp: 2026-03-02T22:15:22Z

---

Dear Mr. Hultén,

Thank you for your follow-up and for the detailed technical observations.

We acknowledge your concerns, and we appreciate you taking the time to test and
document the CLI behavior. We also acknowledge that our earlier responses did
not clearly distinguish between:

1. optional pseudonymous telemetry in local tools, and
2. account-based subscription / quota enforcement calls (when an API key is configured).

This message is intended to correct and supplement our prior responses, without
changing our core position that Memvid does not transmit `.mv2` file contents,
frame data, transcripts, embeddings, or local document contents during ordinary
CLI usage.

## Summary (Memvid CLI / memvid-core code path)

Based on the current `memvid-cli` and `memvid-core` codebase review:

- The CLI includes an **optional telemetry path** (opt-out via
  `MEMVID_TELEMETRY=0`) that can send **pseudonymous event records** to
  `memvid.com`.
- The CLI also includes **query quota / plan ticket calls** for subscription
  enforcement, but these are **API-key gated** and **skip when no API key is
  configured**.
- No `.mv2` content, transcript text, frame payloads, embeddings, file
  contents, or local prompts/questions are sent by the CLI telemetry path.
- The network behavior you observed on local-only commands (including failed
  commands / non-existent file paths) is consistent with the telemetry event +
  flush-on-exit mechanism, not with file-content upload.

## Direct Response to Your Questions

### 1) What data is transmitted during the network calls you observed in the Memvid CLI?

For the CLI telemetry path (when enabled), the event payload includes a limited
pseudonymous record of command execution, including:

- `anon_id` (pseudonymous identifier, hashed)
- `file_hash` (hashed file path; not the raw path)
- `client` (e.g., `cli`)
- `command` (e.g., `find`, `ask`, `put`, `stats`, `open`)
- `success` (boolean)
- `timestamp`
- `file_created` / `file_opened` (booleans)
- `user_tier` (e.g., `free`, or plan name when available)

For paid/API-key usage, separate quota enforcement calls may occur for query
counting and plan ticket refresh. Those calls are for subscription enforcement
and capacity/quota validation and do not include `.mv2` contents.

### 2) Why do network calls occur even before any file operation is attempted (including non-existent files)?

The CLI records command execution metadata (including failed commands) and
attempts to flush queued telemetry before process exit. This means a network
request can occur even when:

- the command fails early,
- the file does not exist, or
- no `.mv2` file is successfully opened.

In that case, the telemetry event reflects command invocation/outcome metadata
(for example, command name + hashed path + success/failure), not file
contents.

Separately, for `find` / `ask` on an API-key-configured installation, the query
quota counter is intentionally recorded before the memory file is opened. That
is a distinct quota-enforcement code path, not the telemetry path.

### 3) Why would “license verification” occur if no license key / API key is supplied?

If no API key is configured, the CLI code path for query quota tracking and
plan ticket sync **short-circuits** and does not perform those account-based
calls. In other words:

- **no API key configured** -> no query quota usage tracking call
- **no API key configured** -> no plan ticket fetch required for free-tier
  fallback

Accordingly, if you observed Memvid-domain network traffic while using the CLI
as a free-tier user with no API key configured, that behavior is consistent
with the CLI’s telemetry path (when enabled), rather than account/license
verification.

### 4) Why do those calls stop when `MEMVID_TELEMETRY=0` is set?

Because the CLI telemetry path is explicitly gated by `MEMVID_TELEMETRY`, and
setting `MEMVID_TELEMETRY=0` disables telemetry event generation / flushing in
the CLI.

This is separate from subscription quota/ticket calls, which are API-key gated
and serve a different purpose.

## GDPR Article 15 / 13 Information (Memvid CLI and related local-tool telemetry)

To avoid ambiguity, we are treating the pseudonymous telemetry described above
conservatively as data that may be relevant to your Article 15 request if it
can reasonably be linked to you.

### Categories of data (CLI/local-tool telemetry and quota enforcement)

Potentially relevant categories include:

- Pseudonymous telemetry event data (command metadata)
- Pseudonymous identifiers (`anon_*` / `paid_*`) and hashed file identifiers
- Account-based quota usage records (count-based query usage, where API key is
  configured)
- Plan / ticket synchronization metadata (where API key is configured)
- Support correspondence and email communications (including this thread)

### Purposes of processing

- Product telemetry / operational analytics for local tools (optional telemetry path)
- Subscription enforcement, quota management, and capacity validation (API-key gated)
- Security / abuse prevention / service integrity (where applicable)
- Customer support and compliance response handling (this correspondence)

### Lawful basis (summary)

Our present classification is:

- **Article 6(1)(f)** (legitimate interests) for limited pseudonymous telemetry
  used for product/operational analytics, with CLI opt-out control
  (`MEMVID_TELEMETRY=0`)
- **Article 6(1)(b)** (performance of a contract) and/or **Article 6(1)(f)**
  for subscription quota and plan ticket enforcement where paid/account features
  are used
- **Article 6(1)(c)** and/or **6(1)(f)** for responding to and administering
  data protection requests and related compliance matters

### Retention (what we can confirm from the CLI code path)

From the CLI codebase itself, we can confirm:

- The CLI keeps a **local JSONL telemetry queue** on the user’s machine and
  clears it after successful flush.
- This local queue is stored under the OS local application data directory
  (e.g., `.../memvid/analytics/queue.jsonl` on supported platforms).

For **server-side retention periods** (Memvid-hosted analytics/quota records),
the exact retention values are configured in the <memvid.com> service layer
rather than the CLI/core repositories you referenced. We will include the
applicable retention periods in the machine-readable response for any
identified records.

### Recipients / third-party access

The CLI telemetry and quota-tracking code posts directly to Memvid-controlled
endpoints (e.g., <memvid.com>). The CLI code path reviewed does not embed
third-party analytics SDKs in the Rust CLI itself.

Any hosting/infrastructure subprocessors used to operate Memvid-controlled
endpoints (if applicable) are governed by our service deployment and vendor
arrangements. We will identify any relevant recipients/processors in the formal
data export/response where records are found.

## What We Can Provide Now / Next Step to Fulfill Your Request

We can proceed in two tracks:

- **Account-linked records search (immediate)**

  We will search Memvid-controlled systems for records associated with your
  email address (`Jonas A. Hultén`, sender address in this thread), including
  support/compliance correspondence and any account-linked data (if present).

- **Pseudonymous CLI telemetry records (requires corroboration to identify records)**

  Because CLI telemetry is designed to avoid transmitting raw username,
  hostname, or file path, CLI telemetry records are stored under pseudonymous
  identifiers and hashed file references. To reliably identify records that
  may correspond to your local CLI usage, please provide any of the following
  (whatever you are comfortable sharing):
  - the email/account (if any) used with other Memvid tools (including the
    `claude-brain` plugin)
  - approximate timestamps/time zone for observed CLI invocations
  - verbose CLI logs showing the relevant requests
  - if available, the local CLI telemetry queue entries from your machine
    (`queue.jsonl`) or the visible `anon_*` identifier from your logs

If you used a different email/account identifier for the `claude-brain` plugin
or any other Memvid tool, please provide that as well so we can scope the
search correctly.

Once we have the above, we will provide any identified records in a structured,
commonly used, machine-readable format (e.g., JSON and/or CSV) and include:

- categories of data
- purposes
- lawful basis
- recipients (where applicable)
- retention period information (where available)

We note your Article 12(3) timing point and confirm that we are treating your
request as received on **21 February 2026**, with the one-month deadline
therefore falling on **21 March 2026**.

## Technical Appendix (for transparency)

Below are short code excerpts from the current `memvid-cli` codebase showing
the relevant behavior you raised.

### A. CLI telemetry opt-out (`MEMVID_TELEMETRY=0`)

File: `memvid-projects/crates/memvid-cli/src/analytics/mod.rs`
(`init_analytics()`, around lines 31-37)

```rs
if let Ok(val) = std::env::var("MEMVID_TELEMETRY") {

    if val == "0" || val.to_lowercase() == "false" {
        TELEMETRY_ENABLED.store(false, Ordering::Relaxed);
        return;
    }

}
```

### B. Telemetry event fields (CLI)

File: `memvid-projects/crates/memvid-cli/src/analytics/queue.rs`
(`AnalyticsEvent`, around lines 14-28)

```rs
pub struct AnalyticsEvent {
    pub anon_id: String,
    pub file_hash: String,
    pub client: String,
    pub command: String,
    pub success: bool,
    pub timestamp: String,
    pub file_created: bool,
    pub file_opened: bool,
    pub user_tier: String,
}
```

### C. CLI flushes analytics before exit (including failed commands)

File: `memvid-projects/crates/memvid-cli/src/main.rs` (around lines 183-184 and
198-199)

```rs
// Initialize anonymous telemetry (opt-out: MEMVID_TELEMETRY=0)
init_analytics();

// ...

// Flush analytics before exit (fire-and-forget, errors ignored)
let \_ = force_flush_sync();
```

### D. Query quota tracking is skipped when no API key is configured

File: `memvid-projects/crates/memvid-cli/src/api.rs` (`track_query_usage()`,
around lines 454-460)

```rs
let api_key = match require_api_key(config) {
    Ok(key) =&gt; key,
    Err(_) =&gt; {
        // No API key configured - skip tracking
        return Ok(());
    }
};
```

### E. Free-tier fallback (no API key) for optional plan ticket lookup

File: `memvid-projects/crates/memvid-cli/src/org_ticket_cache.rs`
(`get_optional()`, around lines 204-209)

```rs
if config.api_key.is_none() {
    log::debug!(&quot;No API key set, using free tier limits&quot;);
    return None;
}
```

### F. For `find` / `ask`, query quota tracking is called before opening the `.mv2` file (API-key path)

Files:

- `memvid-projects/crates/memvid-cli/src/commands/search.rs` (ask path, around
  lines 922-928)
- `memvid-projects/crates/memvid-cli/src/commands/search.rs` (find path, around
  lines 1430-1437)

```rs
// Track query usage against plan quota
crate::api::track_query_usage(config, 1)?;

let mut mem = open_read_only_mem(&amp;args.file)?;
```

### G. `anon_*` and file hash generation are derived from hashed local values (not raw values)

File: `memvid-projects/crates/memvid-cli/src/analytics/id.rs`
(`generate_anon_id()` / `generate_file_hash()`, around lines 43-85)

```rs
// Free user - use machine ID
let machine_id = get_machine_id();
// ...
format!(&quot;anon_{:x}&quot;, result)[..21].to_string()

// Used to track file activity without revealing the actual path
format!(&quot;{:x}&quot;, result)[..16].to_string()
```

We hope this clarifies the behavior you observed and the scope of data
involved. We remain available to continue the SAR process and provide a
machine-readable export for any records we can identify as yours.

Best regards,

The Memvid Team

**Memvid**

The Memory Engine for AI

🌐 <memvid.com>

📧 <contact@memvid.com>
