# Analysis of `@memvid/sdk`

This analysis was performed against `@memvid/sdk` version 2.0.157, pulled on
2026-02-20 via `npm install` inside a clone of the `claude-brain` repository
(see its [separate analysis](./brain.md)).

## Initial remarks and source code

The [npm page for `@memvid/sdk`](https://www.npmjs.com/package/@memvid/sdk)
notes this package as under the Apache 2.0 license and references the
[`memvid/memvid`](https://github.com/memvid/memvid) GitHub repository --- the
same repository referenced by [`memvid-cli`](./cli.md).

As documented in the CLI analysis, the `memvid/memvid` repository is
overwhelmingly Rust code for the `memvid-core` library and does not contain
source code for the Node.js SDK wrapper or the CLI implementation.

The `@memvid/sdk` package contains only compiled JavaScript files in its
`dist/` directory (with accompanying `.d.ts` TypeScript declaration files for
type information). The JavaScript appears to be compiled from TypeScript
sources, but no TypeScript source files are included in the package.

The actual implementation lives in platform-specific native binaries:

```
@memvid/sdk-darwin-arm64
@memvid/sdk-darwin-x64
@memvid/sdk-linux-x64-gnu
@memvid/sdk-linux-arm64-gnu
@memvid/sdk-win32-x64-msvc
```

Each of these packages contains a native Node.js addon (`.node` file) built
from Rust via N-API (per the `@memvid/sdk` package's own README). On my system,
`@memvid/sdk-linux-x64-gnu` version 2.0.157 contains a single 26MB binary:
`memvid_sdk.node`.

### Problems

As with the CLI analysis, we have the same Apache 2.0 license nullity issue:

All packages (`@memvid/sdk` and its platform-specific dependencies) claim
Apache 2.0 licensing and reference `memvid/memvid` as their source repository.
However, that repository does not contain:

- The TypeScript source code for the JavaScript wrapper (only compiled `.js`
  and `.d.ts` files are shipped in `dist/`)
- The N-API binding layer source code
- Any build infrastructure for producing the `.node` native addons

While the `memvid/memvid` repository does contain the `memvid-core` Rust
library under Apache 2.0, this is not the complete source for the SDK packages.
Without access to the wrapper code, N-API bindings, and build configuration,
the Apache 2.0 license is effectively meaningless — users cannot exercise their
rights to create derivative works, audit the full implementation, or build the
SDK from source.

## Undisclosed Telemetry Implementation

The SDK contains a comprehensive analytics framework in `dist/analytics.js`
that tracks usage and transmits it to `https://memvid.com/api/analytics/ingest`.
This telemetry system is:

- **Not mentioned in the README** (which claims "No database. No cloud. No API keys.")
- **Not mentioned in the npm package description**
- **Not disclosed in API documentation**
- **Enabled by default** with opt-out only via `MEMVID_TELEMETRY=0` environment
  variable; this is the same behavior as the CLI, but whereas the CLI at least
  has online documentation that mentions this environment variable, you need to
  search the SDK source code --- which, again, is only available by trawling
  `node_modules` --- to discover this.

### Data Collection

The analytics module collects and transmits the following data on every SDK operation:

#### Machine Fingerprinting

The `getMachineId()` function creates a "stable machine identifier" by hashing:

```javascript
function getMachineId() {
  const hash = crypto.createHash("sha256");
  hash.update(os.hostname()); // Your computer's hostname
  hash.update(os.userInfo().username); // Your username
  hash.update(os.homedir()); // Your home directory path
  hash.update("memvid_telemetry_node_v1");
  return hash.digest("hex").slice(0, 16);
}
```

This creates a persistent identifier tied to your specific machine and user account.

#### User Identification

The `generateAnonId()` function creates tracking IDs:

- **Free users**: `anon_<hash>` derived from machine ID + optional file path
- **Paid users**: `paid_<hash>` derived from first 8 characters of `MEMVID_API_KEY`

This allows correlation of:

- All operations from the same machine (via machine ID)
- All operations on the same file (via file path hash)
- Free vs paid tier users
- Individual API key holders (paid users)

#### File Path Tracking

Every operation includes a `file_hash` derived from the absolute file path:

```javascript
function generateFileHash(filePath) {
  const normalized = require("path").resolve(filePath);
  hash.update(normalized);
  hash.update("memvid_file_v1");
  return hash.digest("hex").slice(0, 16);
}
```

While the actual path is hashed, the hash is deterministic — the same file
always produces the same hash, allowing tracking of operations on specific
files over time.

#### Event Data

Each telemetry event sent to Memvid includes:

```typescript
{
    anon_id: string,        // Machine/user/API key identifier
    file_hash: string,      // Deterministic hash of file path
    client: "node",         // Always "node" for SDK
    command: string,        // Operation: "put", "find", "create", "stats", etc.
    success: boolean,       // Whether operation succeeded
    timestamp: string,      // ISO timestamp
    file_created?: boolean, // Whether this created a new file
    file_opened?: boolean   // Whether this opened an existing file
}
```

### Tracked Operations

The following SDK operations trigger telemetry (from `index.js`):

| Operation       | Command       | Notes                                             |
| --------------- | ------------- | ------------------------------------------------- |
| `create()`      | "create"      | File creation                                     |
| `open()`        | "open"        | File open                                         |
| `put()`         | "put"         | Adding documents                                  |
| `remove()`      | "remove"      | Deleting documents                                |
| `find()`        | "find"        | All search operations (lexical, semantic, hybrid) |
| `correct()`     | "correct"     | Corrections                                       |
| `correctMany()` | "correctMany" | Batch corrections                                 |
| `stats()`       | "stats"       | Getting statistics                                |
| `putFile()`     | "putFile"     | File ingestion                                    |
| `putFiles()`    | "putFiles"    | Batch file ingestion                              |

**Every single SDK operation** generates telemetry unless explicitly disabled
--- again, only possible via completely undocumented environment variable.

### Transmission Mechanism

Events are batched and transmitted:

- **Batching**: Up to 100 events queued in memory
- **Flush interval**: Every 5 seconds (debounced)
- **Endpoint**: `https://memvid.com/api/analytics/ingest` (or
  `MEMVID_ANALYTICS_URL` if set)
- **Fire-and-forget**: Uses `setTimeout().unref()` to avoid blocking process
  exit
- **Retry**: Failed events are re-queued (up to batch size limit)

The telemetry is described in code comments as "zero latency impact" and
acceptable for "events may be lost on quick CLI exits."

### Privacy Implications

While the `claude-brain` README claims "100% local. Nothing leaves your
machine. Ever.", the SDK:

1. **Fingerprints your machine** using hostname, username, and home directory
2. **Tracks every operation** you perform with the SDK
3. **Tracks which files** you operate on (via deterministic hashing)
4. **Identifies paid users** via their API keys --- API keys you, by the way,
   shouldn't ever need, again per the `claude-brain` README
5. **Correlates activity** across time via persistent identifiers
6. **Transmits to Memvid servers** on every operation

The hashing provides only minimal privacy protection:

- Same machine → same machine ID (persistent tracking)
- Same file → same file hash (activity correlation)
- Same API key → same paid user ID (user identification)

### Opt-Out Mechanism

Telemetry can only be disabled by setting the environment variable:

```bash
export MEMVID_TELEMETRY=0
```

This opt-out mechanism is:

- **Not mentioned in the README**
- **Not mentioned in the "Environment Variables" section** of the README
- Only documented in the [online CLI
  documentation](https://docs.memvid.com/cli/index#environment-variables) ---
  again, it's worth noting that this is the CLI documentation; the [SDK
  documentation](https://docs.memvid.com/node-sdk/overview#environment-variables)
  **does not mention** this variable. Discovering its use and function here
  required source code analysis of the provided JavaScript.
- Required to be set **before** importing the SDK

The SDK also exports functions to check telemetry status:

```javascript
import { isTelemetryEnabled, flushAnalytics } from "@memvid/sdk";
```

However, these are not documented in the README or API documentation.
