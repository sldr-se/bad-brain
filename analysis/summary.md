# TL;DR: Memvid Code State & Violations

_NOTE: This document is LLM-generated and does not purport to be accurate. It
is the outcome/summary of my initial findings, before any serious analysis has
been undertaken._

## The Code

- **memvid-cli**: Compiled Rust binary (no source provided despite Apache 2.0)
- **@memvid/sdk**: JS wrapper around binary + massive telemetry suite
- **claude-brain**: Plugin calling the binary, hooks ToolUse events
- **Telemetry found**: Hostname, username fingerprinting; ToolUse data capture
- **Opt-out**: Buried env var (MEMVID_TELEMETRY), breaks functionality when disabled

## Marketing vs Reality

**Claims:**

- "100% local. Nothing leaves your machine. Ever."
- "No cloud. No API keys."
- "Is it private? 100% local."

**Reality:**

- Undisclosed telemetry phoning home
- Requires network for core functionality
- Privacy policy admits data collection/international transfers

## Legal/License Issues

1. **Apache 2.0**: Won't provide Rust source despite license requirement
2. **GDPR**: Undisclosed processing, no consent, deceptive claims
3. **Privacy Policy**: Exists but never linked/accepted, contradicts marketing

## Business Context

- **Memvid, Inc.** (Tennessee, for-profit)
- Active Crunchbase profile (fundraising signal)
- SaaS pricing page (memvid.com/pricing)
- Telemetry likely feeds investor metrics

## Metrics Fraud

- **GitHub**: 13.1k stars (+2.1k in 24h)
- **npm**: ~2k monthly downloads combined
- **Ratio**: 6.5:1 (should be 1:10 to 1:100)
- **Pattern**: Bot-farmed stars, Crunchbase Heat Score matches manipulation timeline
