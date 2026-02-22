From: J. A. Hultén <jonas@sldr.se>

To: Memvid Company <contact@memvid.com>

Subject: Re: GDPR Data Subject Access Request

---

Dear Memvid Team,

Once again, thank you for your reply. However, I remain unsatisfied with your
response.

First, so that you can correctly process my request: I am referencing the CLI
as an example of likely data collection; it is not the entirety of my request.
I was, for instance, a user of your `claude-brain` plugin, if that helps
correctly scope the request. Again, I reiterate: my request is for _any and
all_ personal data you have about me, collected from _any_ of your
software(s)/tools/etc.

You claim in your latest email that there are, in fact, network calls made for
license verification purposes. In your initial email and, indeed, quoted within
your last message, you state that network calls are limited to specific
commands. These two statements cannot both be true at the same time, and the
observed behavior is more in line with your latter statement.

This raises another question. I am a free-tier user, and have never claimed to
be anything else. What purpose is there in performing a network license
verification call when I am not supplying a license key/API key/other
identifier to suggest that I would like to use paid-tier functionality?

Furthermore, if the network traffic is indeed necessary for license
verification, why does network traffic cease when I run the CLI with
`MEMVID_TELEMETRY=0` set in my environment? Telemetry, by definition, is
optional usage tracking; core functionality such as license verification would
not be controlled by a telemetry opt-out variable. If the network calls are
indeed necessary for the software to function, then disabling them would cause
the software to cease to function. Per my tests, this isn't the case, and the
software continues to operate normally even when the telemetry opt-out is set,
strongly suggesting that the calls are not necessary but are, rather,
telemetry.

You have now - repeatedly - stated that you do not collect behavioral tracking
identifiers or device fingerprints, file contents, transcripts, and so on. I
just wish to reiterate that I am not requesting specific classes or types of
data; I am requesting _any and all_ data you have about me.

Thus, I ask the following: either

- provide the requested data in the format laid out in my initial request, or;
- formally and categorically confirm that you **do not** process **any**
  personal data about users of your free tier software.

If you choose to confirm that you process no data, then I would ask that you
explain:

- What data is transmitted during the network calls I observed in the Memvid
  CLI
- Why those calls occur before any file operation is attempted, as evidenced by
  them occurring when trying to operate on a non-existent file
- Why are license verification calls being made when no license/key is being
  supplied to verify
- Why these network calls - which you allege are necessary license verification
  calls - are disabled by a "telemetry" environment variable

My subject access request remains unchanged. Your deadline for compliance, as
stated in my initial email and as required by Article 12(3) of the GDPR, is one
month from the receipt of my initial request (2026-02-21). That deadline
remains in force.

Best regards,

Jonas A. Hultén
