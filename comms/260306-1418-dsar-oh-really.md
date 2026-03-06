From: J. A. Hultén <jonas@sldr.se>

To: Memvid Company <contact@memvid.com>

Subject: Re: GDPR Article 15 Request – Clarification and Supplementary Response
(Memvid CLI / Local Tools)

Timestamp: 2026-03-06T14:18:19Z

---

Dear Memvid,

Thank you for your latest reply. It may not surprise you to learn that I am
deeply troubled by its contents.

To recap, in your original reply on 2026-02-21, you wrote "Memvid does not
collect, transmit, store, or process personal data from users of the memvid-cli
or memvid-core software." More to the point, you wrote: "Because we do not hold
or process personal data concerning you, there is no personal data to provide
in response to your access request under Article 15."

As described **at great length** in your latest reply (on 2026-03-02), these
statements are **false**. You do, in fact, "collect, transmit, store," and
"process" personal data from users. Lest you try to claim that the data isn't
actually personal since it is pseudonymised, I should note that, under the GDPR
(Recital 26), pseudonymised data is still personal data, since you are able to
single out individual persons and, were I to provide the `anon_` identifier you
request, the data you have already collected would be directly attributable to
me.

Speaking of that identifier, nowhere in your latest reply do you describe how
it is actually computed. It is a hash, but a hash of _what_? I do not have any
residual `queue.jsonl` or other log files which may contain the identifier; the
directory I just discovered under `~/.local/share/memvid/analytics` is empty.
Consequently, in order to provide that identifier, you will need to inform me
how it is computed, or what its constituent parts are so that I can provide
those.

Your other angle, using email-based authentication is moot - I do not have an
account on memvid.com, nor have I ever provided my email to any Memvid tool;
`claude-brain`, `memvid-cli`, or otherwise.

While I thank you for the code snippets you provided "for transparency" in your
latest email, I will note the curious shift from your second reply on
2026-02-21 wherein you noted you "are not able to disclose proprietary
implementation details or closed-source intellectual property". The fact that
you are now providing "implementation details" goes against your earlier
statement. Moreover, I will note that _all_ publicly available Memvid projects,
such as the `memvid-cli` package on NPM, are noted as being under the Apache
2.0 license, yet **you do not make the source code available**; all those
packages reference the `memvid/memvid` GitHub repository which, if I am
understanding things correctly, is the Rust Memvid Core library. I would be
able to review your code myself, were it actually available, but as things
stand, it is not, and I have no reason to trust that the snippets you provided
are factually accurate since I am unable to verify them.

The most egregious claims made in your latest reply are concerning your "Lawful
basis" to collect under the GDPR.

Within your very first point, you claim "legitimate interests" per Art.
6(1)(f). You are correct, insofar as that being the article that defines the
permissiveness of legitimate interest processing. However, _the very fact_ that
the collection can be disabled via an environment variable opt-out signifies
that you do not, in fact, have such legitimate interest. Moreover, you simply
state that you have legitimate interest to collect telemetry without specifying
why that interest is legitimate, sufficient to override the user's rights of
privacy. Per Recital 47, you are **required** to carefully assess whether your
claimed legitimate interests are appropriate, and whether, on balance, they
override the data subject's fundamental rights and, per Art. 6(1)(d), disclose
what these legitimate interests are _prior_ to any collection taking place -
i.e. your emails do not bring you into compliance.

In your second point, you reference users which have willingly created
accounts, supposedly agreeing to terms of service with you. As a user of your
`memvid-cli` and `claude-brain`, I have never been presented with such a
question, nor agreed to any such terms, so that point is moot.

Thirdly, and most bizarrely, you claim that you have legitimate interest and a
contractual need to collect so that you can respond to requests about data
protection. Not only does this **flagrantly** go against your original claim
that you perform no collection or processing so there is nothing to disclose,
but it is also circular; you cannot reference your obligations under the GDPR
as justification for collection in order to fulfill those obligations.

Regardless of any of the above, you are in violation of the transparency
requirement of Art. 5(1)(a). The data subject is not made aware of this
collection and/or processing, nor of its scope or purposes, per Art. 5(1)(b).
Recital 32 very explicitly states that "Silence, pre-ticked boxes or inactivity
should not therefore constitute consent" - not that it necessarily matters,
since you do not allege consent - but it does underscore that the existence of
the `MEMVID_TELEMETRY` variable, buried deep in your CLI documentation, is
**not sufficient** to allege consent. To quote Recital 39: "It should be
transparent to natural persons that personal data concerning them are
collected, [...] and to what extent the personal data are or will be
processed." You do not do this.

Continuing, one may look at Art. 13(1)(a), which requires the disclosure of the
identity and contact details of the controller. Looking to your online Privacy
Policy - which, I shall note, **does not apply** since you make no reference of
it anywhere in the `memvid-cli`, `claude-brain`, etc. README files - you direct
this to "Memvid, Tennessee". At the head of the same, you refer to yourselves
as "Memvid, Inc.". The Tennessee Secretary of State has no records of a company
in Tennessee with the name "Memvid". This raises two very important questions:

1. Who is the legal controller of the personal data you collect, per Art. 6(1)?
2. If applicable, who is your representative within the EU, per Art. 27(1)?

Within the same article, 13(2)(a), you are required to provide "the period for
which the personal data will be stored, or if that is not possible, the
criteria used to determine that period". Within your latest email, you simply
state that retention periods exist, but not what they are or how they are
determined. Simply stating that you will "include the applicable retention
periods" in the final data response is **not sufficient**.

To conclude, your responses have laid out a pattern of deny-then-backpedal. If
your original response was true - i.e. claiming there is no collection - then
you would be lying in your latest response, wherein you outline all the
disparate forms of data you collect. If the latest response was true, then your
original response was a lie. This, to me, indicates blatant bad faith, and I
have as such referred this matter to the Swedish Data Protection Authority.

Regardless of this referral, my Art. 15 request is still live, with the
originally stated deadline of 2026-03-21 - which you kindly confirmed in your
latest email. Thus, as outlined above, please inform me of what data you need
in order to reconstruct the `anon_` identifier, so that you may locate my
records.

Best regards,

Jonas A. Hultén
