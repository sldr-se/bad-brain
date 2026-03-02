# Investigation overview

This document aims to provide a general overview of the what and the why of the
entire `bad-brain` investigation. This is not a formal part of the
investigation; more a pseudo-blog-post so I can describe the current status in
prose.

## Why, or Where it all started

I stumbled across `memvid/claude-brain` in my search for a Claude Code plugin
that would let it retain cross-session memory in a nice, portable way. The
marketing was promising: a single file, kept in your `.claude` directory,
cataloging "Session context, decisions, bugs, solutions" (per their README).

Having used it for a while, it was starting to grate how inefficient it was. It
had reasonably soon become clear that the plugin was actually just capturing
raw tool output from Claude and storing it. Notably, it was _not_ storing tool
calls related to the Todo list functionality, which I relied on heavily. Being
a friend of Open Source in general, I forked the `claude-brain` repository and
figured I could weed through it to add the missing Todo-related tools, and also
strip out the noisy (and rather useless) Stop hook.

It was in this process that I also downloaded the `memvid-cli` --- mentioned in
their README as the tool one should use if you want to prod at the `.mv2` file
without Claude's involvement --- to try to inspect the memory files. It was,
unfortunately, failing to open all of my `.mv2` files with various
deserialization errors. Poking around a bit, I found a version mismatch,
thinking that might be the problem, but couldn't find a fix --- the
`memvid-cli` package marked as version 2.0.153 was using an internal binary of
version 2.0.134, while the `@memvid/sdk` bundled with `claude-brain` was
version 2.0.146.

Hoping to glean more information before reaching out to Memvid --- their email
helpfully provided in the `claude-brain` README --- I ran the CLI with
increased verbosity. This revealed a _very_ long trace log showing a phone-home
to `memvid.com` (for more on this, see the [CLI analysis](./analysis/cli.md)).
I double-checked the CLI and `claude-brain` READMEs, and there was no
indication anywhere of there being any telemetry. Searching the online CLI
documentation, the only mention of telemetry I could find was a single
reference to a `MEMVID_TELEMETRY` environment variable which, when set to `0`,
silenced the phone-home.

It was at this point I sent my initial email to Memvid (see [Initial
Email](./comms/260212-1325-initial-email.md)), asking both about the version
discrepancies and the undisclosed telemetry, as well as where I might find the
source code for the SDK --- it's marked as being under Apache 2.0, but I can't
find its source anywhere. I also had Claude weed through the `claude-brain`
node_modules directory, looking for other hints of telemetry. It found a
full-fledged telemetry suite (see the [SDK analysis](./analysis/sdk.md)), which
led me to decide to start this investigation, only reinforced by [Memvid's
reply](./comms/260213-0149-memvid-reply.md) conveniently not responding to my
question about the telemetry or the source code.

## Outside the code

There is another angle in this investigation, namely (ALLEGED) metrics
manipulation.

In looking into Memvid and their GitHub repositories, I noted that while
`claude-brain` had a reasonably modest couple of hundred stars, their main
repository --- `memvid/memvid` --- had over 11.000 stars.

> Note: this observation is from before I started this repository, thus the
> 11.000 number is not recorded in the [GitHub
> metrics](./analysis/metrics/github.csv). I therefore can't _prove_ the
> number, though I am claiming that was the star count at the start of all
> this. Indeed, when checking a few days later, the star count had suddenly
> jumped to over 13.000, which is where it has been at since I started
> harvesting metrics.

This didn't smell right, so I had a look at the star graph for this repository
(see the [screenshot](./screenshots/260215-star-history.png) from 2026-02-15).
I am no expert at these things, but the sudden sharp jumps with relatively flat
plateaus in between did not look like organic growth. I cannot definitively
prove that these stars are purchased and/or bot-farmed, but it is my primary
suspicion.

This is further underscored by looking at the other metrics. The NPM download
numbers were in the high hundreds or low thousands per week, which doesn't
match what I'd expect to see for such an active project. Similarly, the
`memvid/memvid` repository had single-digit issue numbers, and less than a
hundred lifetime issues, which is _way_ lower than I'd expect for a project
with ostensibly tens of thousands of fans.

### Okay, but why?

Here, we again turn to conjecture. I wasn't sure _why_ anyone would want to
artificially inflate GitHub repository hype --- indeed, I wasn't even aware
that was a thing people did. My only guess would be money.

I had a quick search and, indeed, "Memvid, Inc." has a Crunchbase profile ---
if you're not in the know, a site popular among startups (I guess, particularly
tech startups) hoping to raise venture capital. Adding to my suspicion was the
"Heat" graph on their Crunchbase page, which had a shape rather similar to the
star history graph (see [screenshot](./screenshots/260215-crunchbase.png) from
2026-02-15), i.e. a couple sharp jumps with relatively flat plateaus in
between.

So, the going suspicion is that the stars are inflated in order to manufacture
hype and traction for their company, in order to attract investors.

## GDPR question and responses

Undisclosed telemetry of any kind is not legal under the GDPR. At the very
barest minimum, a data controller (Memvid, in this case) must make the data
subject (that's me, in this case) aware _that_ they are collecting data, _what_
they are collecting, _why_ they are collecting it, and under which _lawful
basis_ they are collecting it, or otherwise get consent from the data subject.
Memvid, as noted above, only does the collection, none of the rest.

Having finished the [SDK analysis](./analysis/sdk.md) and its long section on
how this interacts with the GDPR, I reached out to Memvid on 2026-02-21 with a
formal Art. 15 Data Subject Access Request (DSAR). They replied within 8
minutes very flatly stating that they do not collect anything so there was
nothing to provide to me. I pressed them, stating that I have observed a
phone-home using their CLI --- which I already mentioned in my email on
2026-02-12 --- so, if they're not collecting anything, what's that? They again
replied within 20 minutes, stating that those network calls were for license
verification, since they have paid tiers of their services and they need to
check if I'm allowed to use those. A day later I replied again asking, among
other things, why they're checking a license when I'm not supplying an API key
(or other identifier), and why the "license check" goes quiet when I set the
`MEMVID_TELEMETRY` envvar.

It has, at the time of writing, been 8 days since that email and I have yet to
receive a reply. They are bound by the GDPR to reply, at the very latest, on
2026-03-21, but having already denied any collection despite me having ample
evidence that they do, in fact, collect, I doubt they'll respond.

## Corporate status

While waiting around for their reply, I decided to look a little further at the
company itself, Memvid, Inc. Per their website and Crunchbase profile, they are
a registered corporation in Tennessee.

Well, I checked the Tennessee Secretary of State's [Business Entity
Search](./screenshots/260223-tnsos.png) for their company and found... nothing.
For good measure, I also checked [California](./screenshots/260223-casos.png),
[Delaware](./screenshots/260223-dedos.png), and
[Nevada](./screenshots/260223-nvbs.png). Again, nothing.

In addition to being a whole other can of worms regarding the GDPR --- the
alleged data controller doesn't even exist --- it also suggests that they're
attempting to raise venture capital for a company that isn't a company. Or, if
they are, it's not in any way clear _where_ they are incorporated; again, their
page says Tennessee, where I'm at least not finding anything.

## Where this leaves us

Not in a very good spot. For the time being, I'll wait to see if they intend to
respond to my DSAR, but I am exploring my other options.
