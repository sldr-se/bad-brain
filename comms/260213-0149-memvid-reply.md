From: contact@memvid.com
To: J. A. Hultén <jonas@sldr.se>
Subject: Re: Inconsistent versioning and other weirdness

---

Hi Jonas,

Thanks for digging into this.

What you’re seeing is actually by design.

We version the npm package (wrapper) and the underlying Rust binary
independently. The npm package version reflects the SDK/bindings surface, while
the Rust CLI binary version reflects the embedded memvid-cli build. They don’t
have to match numerically, and we intentionally allow them to move at slightly
different cadences.

Right now:

- npm wrapper is at 2.0.156
- The Rust CLI binary it embeds is still on 2.0.136
- The standalone Rust release stream is moving forward independently
- We are preparing 2.0.157 which will align the SDKs and CLI in the next wave
  of releases

The CLI tends to trail the SDKs by a few patch versions because:

1.  The SDK layer (Node/Python) can ship quickly when bindings change.
2.  The CLI binary goes through additional packaging + cross-platform artifact
    validation.
3.  We batch CLI updates deliberately to avoid unnecessary churn for end users.

So this isn’t an accidental drift, it’s separation of concerns between:

- SDK surface version
- Core library version
- CLI packaging version

That said, we are consolidating this in 2.0.157, which will bring the SDKs and
CLI forward together and reduce visible skew.

Appreciate you calling it out, it’s a good reminder that we should document
this versioning model more clearly so it doesn’t look surprising from the
outside.

Best,

Saleban
