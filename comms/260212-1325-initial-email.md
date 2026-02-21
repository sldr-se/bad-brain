From: J. A. Hultén <jonas@sldr.se>
To: contact@memvid.com
Subject: Inconsistent versioning and other weirdness

---

Hello Memvid,

I'm writing asking for help and/or understanding.

The context is I'm trying to fiddle with some of `claude-brain`'s mv2
files via your CLI, and I can't. In all cases I've tried, I'm getting
deserialization errors, e.g.

```sh
$ memvid stats zmrdxvwbe0ryddzx85car5f5tpr9fcse/mind.mv2
Deserialization error: OtherString("sequence length 4294967296 exceeds bound 1000000")
```

My best guess is some version discrepancy in the format. Weeding through
Claude's innards shows I have the 1.0.8 version of claude-brain, which uses
version 2.0.146 of your SDK. The CLI, meanwhile, is the latest - version
2.0.153. However, running `memvid --version` returns 2.0.134. I dug through the
node_modules to verify that yes, I do have version 2.0.153 of the CLI, and it
is pulling the precompiled binaries of version 2.0.153... except those binaries
are, themselves, reporting version 2.0.134.

My best guess here is something has been missed in publishing to NPM as of
late, leading to republishing stale binaries. That, or I'm fundamentally
misunderstanding something. For context, I am running this on x86_64 linux.

On a more concerning note: why is your CLI phoning home on invocation? That
seems like something the user should be made aware of, up front, and allowed to
disable.

Also, where can I find the source code for the CLI - both the underlying Rust
binaries and the npm wrapper?

Hoping you can shed some light on this.

Thank you for your time!

Bästa hälsningar / with kind regards,

Jonas A. Hultén
