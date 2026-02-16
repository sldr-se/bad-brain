# bad-brain

This repository documents issues with the `memvid/claude-brain` plugin and the
`memvid` project in general, including potential GDPR violations, Apache 2.0
license non-compliance, and deceptive marketing practices.

## What This Is

A public evidence repository for:

- Undisclosed telemetry in software marketed as "100% local"
- Failure to provide source code despite Apache 2.0 licensing
- Potential GDPR violations (data processing without consent/disclosure)
- Suspicious GitHub metrics patterns

This list is neither exhaustive nor complete. It will be updated as the
investigation proceeds.

## Repository Structure

- **[analysis/](./analysis/)** - Technical analysis, GDPR assessment, code
  examination
  - **[metrics/](./analysis/metrics/)** - Harvested metrics of GitHub
    repository stats, npm, PyPi, and crates.io download stats.
- **[screenshots/](./screenshots/)** - npm download stats, GitHub star graphs,
  evidence captures, as and where applicable
- **[comms/](./comms/)** - Email correspondence, formal requests, responses

## Start Here

Read **[analysis/summary.md](./analysis/summary.md)** for a high-level overview
of the issues.

## Timestamping

Key files are timestamped using [OpenTimestamps](https://opentimestamps.org/)
to establish verifiable proof of existence. Files with `.ots` extensions are
timestamp proofs that can be independently verified.

### Verifying a timestamp

Any `.ots` file can be verified via

```sh
ots verify path/to/file.ext.ots
```

Note that this requires running a local Bitcoin node, since the attestations
are pinned against the Bitcoin blockchain. If you, like me, aren't running a
local BTC node, you can

```sh
ots --no-bitcoin verify path/to/file.ext.ots
```

And then lookup the block information returned to verify the information.

For your (and my) convenience, there is a `verify-ots.sh` script in the root of
this repository which automates this checking process by getting the block
information from `blockstream.info`. You can run this script either by giving
it the path to an `.ots` file, which will be checked or, if called without a
path, it will check all `.ots` files in the repository. Note that this process
can take a while.

## Status

This is an active investigation. Evidence is being collected, timestamped, and
documented as it becomes available. Structure may evolve/change as further
discoveries are made.

## Automation

Certain parts of this investigation are automated via GitHub Actions
(reviewable in the `.github/workflows` directory). Specifically:

- Once a day, around 03:00 UTC, `archive.sh web` is called, sending all targets
  in `targets.json` to the Internet Archive.
- Twice a day, around 00:00 and 12:00 UTC, `archive.sh metrics` is called,
  harvesting API metrics and updating the CSV and timestamp files under
  `analysis/metrics`.
- Twice a day, around 06:00 and 18:00 UTC, `upgrade-ots.sh` is called,
  upgrading all OTS timestamps (i.e. noting in the `.ots` file if they have been
  pinned against a BTC block).

## License

This work is licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

This means you are free to:

- Share, copy, and redistribute the material in any medium or format for any
  purpose, even commercially.
- Adapt, remix, transform, and build upon the material for any purpose, even
  commercially.

As long as you:

- You must give [appropriate
  credit](https://creativecommons.org/licenses/by-sa/4.0/#ref-appropriate-credit),
  provide a link to the license, and indicate if changes were made. You may do
  so in any reasonable manner, but not in any way that suggests that I (the
  licensor) endorse you or your use.

- If you remix, transform, or build upon the material, you must distribute your
  contributions under the same license as the original.

---

Copyright (c) 2026 Jonas A. Hultén / `sldr-se` / `sldr`
