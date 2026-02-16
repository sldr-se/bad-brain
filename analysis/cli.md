# Analysis of `memvid-cli`

This analysis was performed against `memvid-cli` version 2.0.157, pulled on
2026-02-16 via `npm i memvid-cli`.

## Initial remarks and source code

The [npm page](https://www.npmjs.com/package/memvid-cli) notes this package as
under the Apache 2.0 license and references the
[`memvid/memvid`](https://github.com/memvid/memvid) GitHub repository. Per the
GitHub language stats, that repo is overwhelmingly Rust, however.

I checked out the repository at ref
[`7be69c6`](https://github.com/memvid/memvid/commit/7be69c6a88640e1f94ae1ed6c08a2e01c6a66f02)
to check the contents. Grepping for the line `Personal Note Archive` (the last
heading of the npm README) in the `memvid/memvid` repository returns no hits,
suggesting that this repo does not, in fact, contain the source for the
`memvid-cli` npm package. Searching that repository for `.js` and `.ts` files
returns 2 and 0 results, respectively --- the two JS files being

```txt
docs/i18n/scripts/auto-add-flags.js
docs/i18n/scripts/update-localized-readmes.js
```

### Problems

While the [Apache 2.0 license](https://spdx.org/licenses/Apache-2.0.html)
doesn't explicitly require source code distribution, licensing the `memvid-cli`
package under Apache 2.0 and then _not_ providing the source code (in a
reasonable, accessible form) is meaningless. Without the source code, there is
no way for me to exercise my rights under the license to make derivative works
or analyze the code.

Moreover, linking to the `memvid/memvid` repository is sloppy at best and
deceptive at worst, since that repository does not appear to contain the source
code for the `memvid-cli` package. `memvid/memvid` _is_ under Apache 2.0 as
well, but insofar as the `memvid-cli` package is concerned, that is still
meaningless; it is source code, yes, but not the right source code.
