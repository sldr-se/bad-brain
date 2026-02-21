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

## GDPR Implications

I will preface this section by stating that I --- `sldr` --- am a resident of
Sweden and, as such, a data subject covered by the GDPR (General Data
Protection Regulation, [EU
2016/679](https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:32016R0679)).
Depending on who you are and where you are, you may be subject to other data
protection regulations (for better or worse), but for this analysis, I will be
looking at the GDPR specifically.

As a disclaimer, I will be skating over some of the verbose legal language,
especially definitions of terms. I will, however, cite my sources; e.g. "Art.
2(2)" refers to GDPR Article 2, section 2. By all means, check my work.

### Applicability

A first, obvious argument is that Memvid, Inc. is a Tennessee, USA corporation,
so why would they be subject to EU law? Unfortunately, the GDPR applies as soon
as you process "personal data" (as we will discuss later) of a "data subject"
(read: a "natural person", per Art. 4) who is inside the EU. Specifically, per
Art. 3(2):

> This Regulation applies to the processing of personal data [...] where the
> processing activities are related to:
> (a) the offering of goods or services, irrespective of whether a payment of
> the data subject is required, to such data subjects in the Union; or
> (b) the monitoring of their behaviour as far as their behaviour takes place
> within the Union.

Decoding the legalese, since Memvid, Inc. is processing personal data of an EU
person --- or, monitoring their behavior, as may be more applicable in the case
of telemetry --- **the GDPR applies**.

Further, Memvid's `claude-brain` plugin is distributed globally via GitHub with
no geographic restrictions. It is therefore **inevitable** that EU residents
have or will install and use it, bringing their data processing squarely within
GDPR scope. The same argument also applies to any third-party application
developed using Memvid's SDKs, where the developer is --- most likely
unknowingly --- sending telemetry on all _their_ users back to Memvid.

### Anonymisation

The next argument is that, per what we have seen in the SDK code above, Memvid
is not _directly_ harvesting my hostname, IP, username, file paths, or
contents. The user fingerprint is calculated using SHA256 of an amalgamation of
the hostname, username, and --- interestingly --- home directory, and the file
paths are similarly hashed. SHA256 is --- insofar as modern cryptography is
aware --- irreversible, meaning that my username, hostname, etc. can't be
re-derived from the hash.

The question at hand is: _does this sufficiently anonymise the data?_ Note that
we're ignoring, for the time being, the lack of consent to collection --- which
is necessary even for anonymised data collection --- and the fact that we have
no idea what the binary blob part of the SDK is collecting/doing.

Art. 4(5) defines "**pseudonymisation**" as

> [...] the processing of personal data in such a manner that the personal data
> can no longer be attributed to a specific data subject without the use of
> additional information ...

By my read, this does **not** hold. The host fingerprint is deterministic; for
the same user on the same system --- which is how most of us work --- the
fingerprint will be the same. No, you can't directly link the fingerprint to
me, the human person, but you _can_ see that two different records come from
the same host fingerprint and, thus, conclude that they are from the same
person.

Recital 26 specifically notes (emphasis added)

> The principles of data protection should apply to any information concerning
> an identified or identifiable natural person. Personal data which have
> undergone pseudonymisation, which could be attributed to a natural person by
> the use of additional information should be considered to be information on
> an identifiable natural person. To determine whether a natural person is
> identifiable, account should be taken of **all the means reasonably likely to
> be used, such as singling out**, either by the controller or by another
> person to identify the natural person directly or indirectly. [...]

What this means is that being able to _single out_ a natural person, even if
you can't strictly identify them, is enough to be considered "identifiable"
and, thus, covered under the GDPR. Specifically, Memvid can filter their
records on a specific fingerprint and, thus, isolate --- _single out_ --- a
specific user on a specific machine. Per the above recital, that _explicitly_
means "**the principles of data protection should apply**".

The [Article 29 Working Party Opinion
05/2014](https://ec.europa.eu/justice/article-29/documentation/opinion-recommendation/files/2014/wp216_en.pdf)
further expands on this in the Executive Summary, noting

> [...] [P]seudonymisation is not a method of anonymisation. It merely reduces
> the linkability of a dataset with the original identity of a data subject,
> and is accordingly a useful security measure.

This is correct --- Memvid is saving themselves a security headache by _not_
directly storing my hostname, username, and so on. This does _not_, however,
mean that the data is anonymised, since it is still linkable to me and my
activity.

As a final remark, the anonymisation argument collapses completely for paid
users. Per the SDK code, a paid user's fingerprint is derived from their
`MEMVID_API_KEY` --- a value which _by necessity_ must be both _known_ and
_identifiable_ by Memvid, allowing _direct_ linkage of collected telemetry to a
user/subscriber.

#### In brief

The SDK's method of pseudonymisation of the data is **not** sufficient to
anonymise the data. The host/user fingerprinting allows "singling out" users,
even if they are not directly identifiable, meaning **data protection
applies**. Doubly so for paid users (ironically), where --- due to how their
fingerprint is generated --- their activity is _directly_ linkable to a data
subject or, at the least, a subscriber.

Ergo: **the GDPR applies**.

### Lawful basis and consent

Having --- in my opinion --- established that the GDPR applies, let's next look
at if Memvid are allowed to collect the kind of data they are collecting.

Art. 6(1) defines the _exhaustive_ list of conditions under which "processing"
(which, per Art. 4(2) covers just about every verb you can think of, explicitly
including "collection" and "recording") is lawful. Let's walk through it and
see.

- (a) **Consent**: No. As we've established, the telemetry is never mentioned
  or disclosed, nor is any consent collected, even under the thinnest of "implied
  consent" premises. Providing an _undocumented_ opt-out is not active consent.
- (b) **Performance of a contract**: Not applicable.
- \(c\) **Legal compliance**: No. Memvid, Inc. is under no legal obligation to
  collect this data.
- (d) **Protection of data subject's vital interests**: No. Almost the direct
  opposite.
- (e) **Performance of public interest or official authority**: No.
- (f): **Legitimate interest**: This isn't such a straightforward answer, as
  "legitimate interest" is a pretty broad term, and has seen _plenty_ of abuse.
  However, Recital 39 includes the following:

  > Any processing of personal data should be lawful and fair. It should be
  > transparent to natural persons that personal data concerning them are
  > collected, used, consulted or otherwise processed and to what extent the
  > personal data are or will be processed. [...] Natural persons should be
  > made aware of risks, rules, safeguards and rights in relation to the
  > processing of personal data and how to exercise their rights in relation to
  > such processing. In particular, the specific purposes for which personal
  > data are processed should be explicit and legitimate and determined at the
  > time of the collection of the personal data.

  Memvid's processing very clearly fails this transparency requirement, meaning
  that even if they have (or claim to have) "legitimate interests", that is
  void since the data subject was never made aware of the collection in the
  first place.

Recital 40 covers a general "is this lawful" question:

> In order for processing to be lawful, personal data should be processed on
> the basis of the consent of the data subject concerned or some other
> legitimate basis, laid down by law, either in this Regulation or in other
> Union or Member State law as referred to in this Regulation, including the
> necessity for compliance with the legal obligation to which the controller is
> subject or the necessity for the performance of a contract to which the data
> subject is party or in order to take steps at the request of the data subject
> prior to entering into a contract.

Expanding on the point of "consent", we can look to Art. 7. Art. 7(1) requires
that the controller (Memvid, Inc. in this case, per Art. 4(7) definition of
"controller") be able to demonstrate that the data subject consented to the
processing, which they cannot. Art. 7(4) further notes that consent shall be
_freely given_, and notes that "utmost account shall be taken" if the
processing is necessary for the provision of a service --- the fact that
Memvid's SDK and CLI include the opt-out environment variable and continue
operating when telemetry is disabled clearly shows that the collection is
**not** necessary for the service to function.

To underscore that "implicit consent" is _not_ an argument, we look to Recital
32 (emphasis added):

> Consent should be given by a clear affirmative act establishing a freely
> given, specific, informed and unambiguous indication of the data subject's
> agreement to the processing of personal data relating to him or her [...]
> Silence, pre-ticked boxes or inactivity **should not therefore constitute
> consent**. [...]

#### In brief

It follows from Art. 6(1) and Recitals 39 and 40 that there exists **no purpose**
--- stated, legitimate, or otherwise --- for Memvid's collection of user data.
It follows further from Art. 7(1), 7(4), and Recital 32 that consent to
collection has **not** been given for collection.

It _must_ therefore follow that Memvid's collection of user data via their
telemetry is **not lawful**.

### Rights of the data subject

There are additional angles I could pursue to point out that this processing is
unlawful, but I believe I have made my point. So I will instead turn to what my
rights are as a data subject; rights which I intend to exercise.

Art 13(1) outlines the information that the controller --- Memvid, Inc. --- are
required to provide to me, the data subject. This includes the identity of the
controller, purposes for processing _including_ the legal basis for said
processing and --- explicitly --- where such processing is based on legitimate
interests, any downstream recipients, and intention to transfer personal data,
if applicable. It should not come as a surprise that this information is
_nowhere_ in any of the READMEs.

In order to be as fair as possible, I _will_ note that there is a [Privacy
Policy](https://memvid.com/privacy) on Memvid's website (archived versions
available via the [Internet Archive](https://web.archive.org/)) which _does_
outline some of this information, including contact information for GDPR
inquiries. That said, this privacy policy is only available from the footer of
their webpage and is --- notably --- not mentioned anywhere in `memvid/memvid`,
`claude-brain`, or any SDK README or other documentation. And, even though this
policy outlines collection, it's still unlawful on the basis of no explicit
consent.

Articles 15, 16, and 17 outline the data subject's right to access, correct
("rectify"), and erase (the "right to be forgotten") collected data. I intend
to attempt to exercise these rights and see where it gets me. Per Art. 12(3)
the controller has **no more than** one month to reply to such a request.

## Summary

Above, we have covered how the `@memvid/sdk` includes an extensive analytics
framework, harvesting extensive information about _who_ is using it, _what_
they are doing, and _when_. This telemetry is on-by-default and is only
possible to disable by means of an _entirely_ undocumented environment
variable. Further, since the SDK relies on a precompiled binary component ---
ostensibly licensed under Apache 2.0 but with no source seemingly available ---
there is no telling if there is additional telemetry happening there, and
whether that telemetry honors the environment variable.

Having established the scope and contents of the telemetry, I have walked
through whether this telemetry is permissible under the GDPR. I believe I have
made a solid case for the conclusion that this collection is **not lawful**,
based on the lack of explicit consent, lack of information regarding scope and
purpose of collection, and insufficient anonymisation.

This pattern of undisclosed data collection --- as evidenced across both the
CLI and the SDK --- combined with misleading claims in Memvid's various READMEs
of their software being "100% local" and requiring "no API keys" suggests a
broader issue of transparency and good faith in Memvid's operations. I will be
asserting my rights under the GDPR against Memvid, Inc. and will be very
interested to see how they respond. More information on that will be found
later under [comms](../comms/).
