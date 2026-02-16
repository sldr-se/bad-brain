# Analysis documentation

The below is a roughly sorted list of analysis along with brief synopses.

- [summary.md](./summary.md): Rough starting point for this analysis
- [cli.md](./cli.md): Analysis of `memvid-cli` npm package

## Metrics

The [metrics](./metrics/) subdirectory contains CSV files documenting:

- GitHub repository statistics across a number of `memvid` repositories
- npm download statistics across most of `memvid`'s packages
- PyPi download statistics for the `memvid` Python SDK
- Crates.io download statistics for the `memvid-core` crate

  Note that the crates.io API call has been misbehaving and returning `N/A`
  for the download statistics. This only seems to happen from the GitHub
  runner, so the cause is unknown.

The metrics are auto-harvested twice a day via the `metrics` workflow, which
calls the `archive.sh` file in the repository root, and uses the `targets.json`
file in the root to enumerate targets.
