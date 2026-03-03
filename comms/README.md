# Communications

This directory contains markdown transcripts of emails (and other
correspondence, as applicable) I've had related to this investigation. Each
email will be represented as a single markdown file, with relevant email header
information at the top of the file. Each file is individually timestamped using
OTS (see [top level README](../README.md)).

Threading and additional context is provided in this document, allowing the
individual message files to fully and solely represent a message.

The emails may have been modified from their raw copy-paste state in order to
preserve formatting and introduce proper line wrapping. The content is
materially unchanged, except concerning redactions, as mentioned below.

## Thread 1: Initial questions (Feb 12, 2026)

1. [2026-02-12 - Initial email](./260212-1325-initial-email-corrected.md). My
   first contact with Memvid, reaching out in good faith to seek help regarding
   some strange behavior from their CLI. I was, at the time, attempting to fork
   and debug `claude-brain` and was using the CLI to inspect the `.mv2` files,
   which was consistently failing. It was, when running the CLI with verbose flags
   that I first noticed the phone-home, as documented in the [CLI
   analysis](../analysis/cli.md).
2. [2026-02-13 - Memvid reply](./260213-0049-memvid-reply-corrected.md).
   Memvid's reply, answering my questions about the versioning inconsistencies,
   yet making no mention about the telemetry or source code.

## Thread 2: GDPR Data Subject Access Request

1. [2026-02-21 - Request](./260221-1709-dsar-corrected.md). Formal Data Subject
   Access Request under GDPR's Article 15.
2. [2026-02-21 - Reply](./260221-1717-dsar-reply-corrected.md). Memvid's reply,
   less than ten minutes later. Flat out denial of any personal data processed.
3. [2026-02-21 - Rebuttal](./260221-1739-dsar-refutation-corrected.md). My
   reply, re-stating that their CLI does, in fact, phone home and they should
   probably explain that.
4. [2026-02-21 - Reply](./260221-1759-dsar-reply-2-corrected.md). Memvid's
   reply, admitting --- at last --- that the CLI does, indeed, phone home and
   explains why; ostensibly to do with license checks.
5. [2026-02-22 - Reiteration](./260222-1447-dsar-reiteration-corrected.md). My
   reply, asking them to explain the contradiction between their two responses
   --- do you or do you not send network traffic --- and asking why supposed
   "license verification" is disabled when a telemetry opt-out is used. Reiterates
   that the DSAR is alive and the clock is ticking.
6. [2026-03-02 - Longform](./260302-2215-dsar-longform-reply.md). Memvid
   replied with great gusto. They now admit to having a sweeping analytics
   framework but claim legitimate interest for processing. They also provide
   source code excerpts from a `memvid-projects` repository that doesn't seem to
   be publicly available --- despite the Apache 2.0 licensing and despite
   previously claiming such code was "proprietary implementation details" that
   could not be disclosed. The reply notably still doesn't contain the data I
   requested, only backpedaling regarding whether any such data may or may not
   exist.

## Note on redactions

Personal contact information (private email addresses, direct phone numbers,
etc.) will be redacted from these files in order to protect individual privacy
while maintaining corporate accountability. Complete, unredacted copies are
retained separately for legal and regulatory purposes.

## Note on corrections

Some (or most) of the emails have been corrected after the fact. This is mostly
to do with me messing up the Markdown syntax, leading to bad rendering, and
because I thought it'd be a good idea to include the full timestamp in each
file. The originals are preserved in this directory, just without the
`-corrected` suffix, along with their timestamps, in order to prove their age.
