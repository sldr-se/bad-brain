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

1. [2026-02-12 - Initial email](./260212-1325-initial-email.md). My first
   contact with Memvid, reaching out in good faith to seek help regarding some
   strange behavior from their CLI. I was, at the time, attempting to fork and
   debug `claude-brain` and was using the CLI to inspect the `.mv2` files, which
   was consistently failing. It was, when running the CLI with verbose flags that
   I first noticed the phone-home, as documented in the [CLI
   analysis](../analysis/cli.md).
2. [2026-02-13 - Memvid reply](./260213-0149-memvid-reply.md). Memvid's reply,
   answering my questions about the versioning inconsistencies, yet making no
   mention about the telemetry or source code.

## Thread 2: GDPR Data Subject Access Request

1. [2026-02-21 - Request](./260221-1809-dsar.md). Formal Data Subject Access
   Request under GDPR's Article 15.
2. [2026-02-21 - Reply](./260221-1817-dsar-reply.md). Memvid's reply, less than
   ten minutes later. Flat out denial of any personal data processed.
3. [2026-02-21 - Rebuttal](./260221-1839-dsar-refutation.md). My reply,
   re-stating that their CLI does, in fact, phone home and they should probably
   explain that.
4. [2026-02-21 - Reply](./260221-1859-dsar-reply-2.md). Memvid's reply,
   admitting --- at last --- that the CLI does, indeed, phone home and explains
   why; ostensibly to do with license checks.

## Note on redactions

Personal contact information (private email addresses, direct phone numbers,
etc.) will be redacted from these files in order to protect individual privacy
while maintaining corporate accountability. Complete, unredacted copies are
retained separately for legal and regulatory purposes.
