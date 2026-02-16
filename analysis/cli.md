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

## Package structure and the executable

The `memvid-cli` package itself (delivered under
`node_modules/memvid-cli/bin/memvid`) is a thin wrapper that acts as a platform
binary dispatcher. The main executable (approximately 90 lines of Node.js code)
performs the following tasks:

1. Identifies the current operating system and architecture (e.g.,
   `darwin-arm64`, `linux-x64`, `win32-x64`).

2. Maps the detected platform to a corresponding platform-specific npm package:
   - `@memvid/cli-darwin-arm64`
   - `@memvid/cli-darwin-x64`
   - `@memvid/cli-linux-x64`
   - `@memvid/cli-win32-x64`

3. Searches multiple possible paths to locate the actual native binary within
   the platform-specific package (accounting for different npm/pnpm
   installation structures).

4. Sets up dynamic library search paths before spawning the binary:
   - `LD_LIBRARY_PATH` on Linux
   - `DYLD_LIBRARY_PATH` on macOS

   This indicates the binary has dynamic library dependencies that are shipped
   alongside it in the platform-specific packages.

5. Executes the native binary as a child process, passing through all
   command-line arguments and inheriting stdio.

The actual CLI implementation is not JavaScript or TypeScript code, but rather
a compiled native binary (likely Rust, given the `memvid/memvid` repository is
predominantly Rust). The `memvid-cli` package serves only as an installation
and dispatch mechanism.

### Notes

This, in and of itself, isn't a problem --- I am informed using npm to vendor
precompiled binaries in this manner is relatively common. The open question,
however, is if the binary's source is available.

## The actual binary

The wrapper script, as mentioned above, will pull in a platform-specific npm
package --- in my case `@memvid/cli-linux-x64`, version 2.0.157. This is then
available under `node_modules/@memvid/cli-linux-x64`. The contents of that
directory are the following:

```sh
$ ls -Al
total 176948
-rwxr-xr-x 1 sldr users     46568 feb 16 11:53 libawt_headless.so
-rwxr-xr-x 1 sldr users    813552 feb 16 11:53 libawt.so
-rwxr-xr-x 1 sldr users    588696 feb 16 11:53 libawt_xawt.so
-rwxr-xr-x 1 sldr users   1725784 feb 16 11:53 libfontmanager.so
-rwxr-xr-x 1 sldr users    738400 feb 16 11:53 libfreetype.so
-rwxr-xr-x 1 sldr users    239760 feb 16 11:53 libjavajpeg.so
-rwxr-xr-x 1 sldr users     15144 feb 16 11:53 libjava.so
-rwxr-xr-x 1 sldr users     85376 feb 16 11:53 libjsound.so
-rwxr-xr-x 1 sldr users     15144 feb 16 11:53 libjvm.so
-rwxr-xr-x 1 sldr users    602296 feb 16 11:53 liblcms.so
-rwxr-xr-x 1 sldr users    606952 feb 16 11:53 libmlib_image.so
-rwxr-xr-x 1 sldr users 116003256 feb 16 11:53 libtika_native.so
-rwxr-xr-x 1 sldr users  59682592 feb 16 11:53 memvid
-rw-r--r-- 1 sldr users       325 feb 16 11:53 package.json
```

Investigating the `memvid` binary closer shows the following:

```sh
$ file memvid
memvid: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, BuildID[sha1]=2b0599c854076e0a1a7b017b4872b64eeedaed05, stripped
```

So, this is indeed a precompiled binary of unknown provenance. The
[`@memvid/cli-linux-x64`](https://www.npmjs.com/package/@memvid/cli-linux-x64)
npm page, as well as the included `package.json` file, once again notes this
package as under the Apache 2.0 license, yet the repository URL once more
points to `memvid/memvid`. Searching that repository for strings which appear
in `memvid --help`, e.g. "Delete a frame", returns no hits, suggesting this
once again is the wrong repository for this CLI.

Looking further, the `Cargo.toml` in the `memvid/memvid` repository does not
include any dependencies which are likely to be used for creation of a CLI ---
that repository appears (and indeed claims) to be the `memvid-core` library,
not any CLI implementation.

### Phone-home

Before continuing, it is important to note that neither the `memvid/memvid`
README nor the `memvid-cli` README makes any mention of telemetry. Indeed, the
`memvid/memvid` README makes explicit mentions of "works fully offline", being
"offline-first", and being "infrastructure-free". Yet, when invoking the
`memvid` binary...

```sh
$ ./memvid -vvvv open /there/is/no/file/at/this/path.mv2
DEBUG No API key set, using free tier limits
TRACE (ThreadId(1)) park without timeout
TRACE (ThreadId(2)) start runtime::block_on
TRACE wait at most 10s
TRACE (ThreadId(1)) park timeout 9.999999128s
TRACE checkout waiting for idle connection: ("https", memvid.com)
DEBUG starting new connection: https://memvid.com/
TRACE Http::connect; scheme=Some("https"), host=Some("memvid.com"), port=None
DEBUG resolving host="memvid.com"
DEBUG connecting to 216.150.1.193:443
DEBUG connected to 216.150.1.193:443
DEBUG No cached session for DnsName("memvid.com")
DEBUG Not resuming any session
TRACE Sending ClientHello Message {
    version: TLSv1_0,
    payload: Handshake {
        parsed: HandshakeMessagePayload {
            typ: ClientHello,
            payload: ClientHello(
                ClientHelloPayload {
                    client_version: TLSv1_2,
                    random: f577255143fe70040350a723c1868c90faff9e344c867a135a9343679f64b45a,
                    session_id: a5a0440da1e8f4294e614d037db1f70b89b7190b11a48ada684091bf12c7fde8,
                    cipher_suites: [
                        TLS13_AES_256_GCM_SHA384,
                        TLS13_AES_128_GCM_SHA256,
                        TLS13_CHACHA20_POLY1305_SHA256,
                        TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,
                        TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,
                        TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256,
                        TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,
                        TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,
                        TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256,
                        TLS_EMPTY_RENEGOTIATION_INFO_SCSV,
                    ],
                    compression_methods: [
                        Null,
                    ],
                    extensions: [
                        SupportedVersions(
                            [
                                TLSv1_3,
                                TLSv1_2,
                            ],
                        ),
                        ECPointFormats(
                            [
                                Uncompressed,
                            ],
                        ),
                        NamedGroups(
                            [
                                X25519,
                                secp256r1,
                                secp384r1,
                            ],
                        ),
                        SignatureAlgorithms(
                            [
                                ECDSA_NISTP384_SHA384,
                                ECDSA_NISTP256_SHA256,
                                ED25519,
                                RSA_PSS_SHA512,
                                RSA_PSS_SHA384,
                                RSA_PSS_SHA256,
                                RSA_PKCS1_SHA512,
                                RSA_PKCS1_SHA384,
                                RSA_PKCS1_SHA256,
                            ],
                        ),
                        ExtendedMasterSecretRequest,
                        CertificateStatusRequest(
                            OCSP(
                                OCSPCertificateStatusRequest {
                                    responder_ids: [],
                                    extensions: ,
                                },
                            ),
                        ),
                        ServerName(
                            [
                                ServerName {
                                    typ: HostName,
                                    payload: HostName(
                                        DnsName(
                                            "memvid.com",
                                        ),
                                    ),
                                },
                            ],
                        ),
                        SignedCertificateTimestampRequest,
                        KeyShare(
                            [
                                KeyShareEntry {
                                    group: X25519,
                                    payload: ec7e3630be8152ec266e18e700fee0c2851af9f7804f38cfff30e62a6f60f656,
                                },
                            ],
                        ),
                        PresharedKeyModes(
                            [
                                PSK_DHE_KE,
                            ],
                        ),
                        Protocols(
                            [
                                ProtocolName(
                                    6832,
                                ),
                                ProtocolName(
                                    687474702f312e31,
                                ),
                            ],
                        ),
                        SessionTicket(
                            Request,
                        ),
                    ],
                },
            ),
        },
        encoded: 010000fa0303f577255143fe70040350a723c1868c90faff9e344c867a135a9343679f64b45a20a5a0440da1e8f4294e614d037db1f70b89b7190b11a48ada684091bf12c7fde80014130213011303c02cc02bcca9c030c02fcca800ff0100009d002b00050403040303000b00020100000a00080006001d00170018000d00140012050304030807080608050804060105010401001700000005000501000000000000000f000d00000a6d656d7669642e636f6d00120000003300260024001d0020ec7e3630be8152ec266e18e700fee0c2851af9f7804f38cfff30e62a6f60f656002d000201010010000e000c02683208687474702f312e3100230000,
    },
}
TRACE We got ServerHello ServerHelloPayload {
    legacy_version: TLSv1_2,
    random: 570062665e25275bd39aa8ac86876ca9e9f3152258197d94c6f1b6e8525bde17,
    session_id: a5a0440da1e8f4294e614d037db1f70b89b7190b11a48ada684091bf12c7fde8,
    cipher_suite: TLS13_AES_128_GCM_SHA256,
    compression_method: Null,
    extensions: [
        SupportedVersions(
            TLSv1_3,
        ),
        KeyShare(
            KeyShareEntry {
                group: X25519,
                payload: f8c65274461701508e14483af4694c0b0f87e97dca2e0ed27a7d9af88294784a,
            },
        ),
    ],
}
DEBUG Using ciphersuite TLS13_AES_128_GCM_SHA256
DEBUG Not resuming
TRACE EarlyData rejected
TRACE Dropping CCS
DEBUG TLS1.3 encrypted extensions: [Protocols([ProtocolName(6832)]), ServerNameAck]
DEBUG ALPN protocol is Some(b"h2")
TRACE Server cert is [Certificate(b"0\x82\x04\xf80\x82\x03\xe0\xa0\x03\x02\x01\x02\x02\x12\x06l\xe8)\xa3\xb0\x81\x1a\xd9\xc0L5R\x1dn\x04(\xbe0\r\x06\t*\x86H\x86\xf7\r\x01\x01\x0b\x05\0031\x0b0\t\x06\x03U\x04\x06\x13\x02US1\x160\x14\x06\x03U\x04\n\x13\rLet's Encrypt1\x0c0\n\x06\x03U\x04\x03\x13\x03R130\x1e\x17\r251217224435Z\x17\r260317224434Z0\x151\x130\x11\x06\x03U\x04\x03\x13\nmemvid.com0\x82\x01\"0\r\x06\t*\x86H\x86\xf7\r\x01\x01\x01\x05\0\x03\x82\x01\x0f\00\x82\x01\n\x02\x82\x01\x01\0\xd9\xb4[;\xbc9\x83\xb9K\x18+\xeb\x03U\xe7#/X\xceQ#Z\xd1\t\xecL\xa4/d\xc8;,\xadF\x06\xf3>eN\xe1k\xdf:A\x95P\x0eWl=\x13n@\x8fQnU\xc1\0\xf9\xc5\xe9?m\xc0*\x7f\x92j\xd9t\x1bz\xdf\xb39\xf3\x85p\xd0\x93\x95\x9f\x18\xb5\xd25q\xd2\x01\xea\xe5\xe7\xdc\x9a\xc3\xcd\xddY\xe9\x97\x04\x89\xc6Q\x8d\x07\xb6A\x9c\xc7\xea\xaav\xfaI\xad\xda+}T\x18\x19\x19p\xc3\xec:\x8a\xe8\xd5\x01^.\xa4\x03\x17\x86\xf5sF\xb2\xdb\xb2B'\xe8%A\xb2\0L\x7fg\x0e'\x02\xb6\xf84\xfb\x05\xb5k8\xa4q#\xda;\x1d1\xd7\xad\xbfk\xee\x02\xfb\xf5\xbab\x95\x8c\x99F\x1d\x1eI\x0bq\xf7/\xf9\x94\x1c)r\xd3[V5WS\xe2\xf5\x9a\xfe\xa5\xa6\xc1\xd2\x8e\xbc\x93\x15\x84Z<\x084\xb2Y\x8bL\xa6\xf4HF.\x92Q!\xa8_y\xa8y\xa5<\xe9\xd4Y\xf3D\xbd\x13s5\xbf-:w}2\x97\x02\x03\x01\0\x01\xa3\x82\x02\"0\x82\x02\x1e0\x0e\x06\x03U\x1d\x0f\x01\x01\xff\x04\x04\x03\x02\x05\xa00\x1d\x06\x03U\x1d%\x04\x160\x14\x06\x08+\x06\x01\x05\x05\x07\x03\x01\x06\x08+\x06\x01\x05\x05\x07\x03\x020\x0c\x06\x03U\x1d\x13\x01\x01\xff\x04\x020\00\x1d\x06\x03U\x1d\x0e\x04\x16\x04\x14\xf5\xfc\x94e\x0eHX+H\x8e\x9a\xd3D\xd3\x7fP\x04\x0e\x14I0\x1f\x06\x03U\x1d#\x04\x180\x16\x80\x14\xe7\xab\x9f\x0f,3\xa0S\xd3^Ox\xc8\xb2\x84\x0e;\xd6\x92303\x06\x08+\x06\x01\x05\x05\x07\x01\x01\x04'0%0#\x06\x08+\x06\x01\x05\x05\x070\x02\x86\x17http://r13.i.lencr.org/0\x15\x06\x03U\x1d\x11\x04\x0e0\x0c\x82\nmemvid.com0\x13\x06\x03U\x1d \x04\x0c0\n0\x08\x06\x06g\x81\x0c\x01\x02\x010.\x06\x03U\x1d\x1f\x04'0%0#\xa0!\xa0\x1f\x86\x1dhttp://r13.c.lencr.org/63.crl0\x82\x01\x0c\x06\n+\x06\x01\x04\x01\xd6y\x02\x04\x02\x04\x81\xfd\x04\x81\xfa\0\xf8\0v\0I\x9c\x9bi\xde\x1d|\xec\xfc6\xde\xcd\x87d\xa6\xb8[\xaf\n\x87\x80\x19\xd1UR\xfb\xe9\xeb)\xdd\xf8\xc3\0\0\x01\x9b.\xb2'\xd2\0\0\x04\x03\0G0E\x02!\0\xdb3\x1d(\x83(I\xd3H\x98Z\x1e\xeb/kB\xa5\x9f\xcb\xa9\xa5C\xcbn1\x93\x07\xc1\x027\x18\x04\x02 hs\xbfSt9\xe4\x99\x1d\xba\x1cD\xd4l4W\xeb\x8b\xf6\x1as\x06\x03S\xb4uq;\x8c\xff\x8eK\0~\0\xa5\xc9x\x92]WF\x17\x82\x87\r\xd8\x89f\x0b\\Ud\x8b}\0@\xf2\xec\x07hQ\xd1\x88i\x19\xf7\0\0\x01\x9b.\xb2*N\0\x08\0\0\x05\0+\xfa?\"\x04\x03\0G0E\x02!\0\xde\xfcy\xe6\x81\xca\x8f3\xfe\xddw\t\xd7\xe0\xd9&_=\x7f\xe03\xf4\xcf\x10<x[)\xfc\xe6=P\x02 \x03h&\xd57\x0c\x89\xa1\xc4\x18\x87\x91DUx/F\x9ff\xeb\xf2\xc4\x1el\xf8\x1a\xa4\xaf\x0e:\xecE0\r\x06\t*\x86H\x86\xf7\r\x01\x01\x0b\x05\0\x03\x82\x01\x01\0\x7fHIk\xd2\xe5\xc2\xea\x1b\x9c\xdd\x8b\xc9,\x8dF\n:\xf8\x0ct\x01q\x8c\xfa\x90J Mo\xa1\xa5G\xe8\x1am\xed\x19\x0c^\x1b\x18\xf8\xc4\xbdIh\x19\xbc\x85\xe2\xd1]-|K\xbe\x83jP \x1eS\xa6qO\xd4\x94\xda\x8bX\xb5u\xcb\x86\xe9\xe7sC\x1d\xc7\xce\xc0\xe3T\xce\xcb\x0e4\xeaS \xa6\xd8\xff^l\xcb\xb1\x03\xdc\x9d^\x99\xa4\xcc\x90w\n\x99\xadCa>\x91\xefF\xef\x8b\n1&\xbcO\xcd\xc9\x14\xd9\x1a\xdfowc~\xee\x1d\xa5\xbe\xc2\xac\xef?\x0c\xf1\xb6\x83\x8eu\xe4\xa1\xb6|\x8f9q\x85\xde1cz\xdb\xbc\xad\x04)\xba\xb8\x124y\xb3gI\xbdz\x1c &\xbcSz\xb2\x04\x18\xa1\xd3\xecB\xba\x14\xe1\x17=\xf2(\xfc\xdf\n\x9b0][K\xc5\xd6\xaa\x1d\x95\x8a\xb1\xbf\xd3\xc0\xa6\x9b\xd3\xdb\xbf\x0c\xcb\xb9\xd6D\xb8\xb0\x18\xa1\x83\x01\xa6t\xbe\xf6\xa8\x98\xcc{\x1f\xa85!\xd7\x92\xd07\xe8sL\x0f[\x1d^\x07e\x8c\xbc"), Certificate(b"0\x82\x05\x050\x82\x02\xed\xa0\x03\x02\x01\x02\x02\x10Z\0\xf2\x12\xd8\xd4\xb4\x80\xf3\x92AW\xea)\x83\x050\r\x06\t*\x86H\x86\xf7\r\x01\x01\x0b\x05\00O1\x0b0\t\x06\x03U\x04\x06\x13\x02US1)0'\x06\x03U\x04\n\x13 Internet Security Research Group1\x150\x13\x06\x03U\x04\x03\x13\x0cISRG Root X10\x1e\x17\r240313000000Z\x17\r270312235959Z031\x0b0\t\x06\x03U\x04\x06\x13\x02US1\x160\x14\x06\x03U\x04\n\x13\rLet's Encrypt1\x0c0\n\x06\x03U\x04\x03\x13\x03R130\x82\x01\"0\r\x06\t*\x86H\x86\xf7\r\x01\x01\x01\x05\0\x03\x82\x01\x0f\00\x82\x01\n\x02\x82\x01\x01\0\xa5gp\x8d\xd0V\x81d\x15\x17a\xcd\xb9\x06\xd4\xad\x19\x90\x8c&P7\x98\x16c\x92T\xdb\xd9\xcc\x84\x05\x93\xec\xd3\xec\x08\x1b\xa0`QCH}+\xc7H\x96\x9e\xb4-\xda\x9d\xc8';W\xa1\x9f\xab\xf0\xd6\x0e\xd4\x0e0\xcao\x9b\xb1\xd1\xd6\xa4\x9d2>XN5oEXhq\x17\xfc>\xd8]\x82\xa0/\xb2Ql\xb0\x1a]\xb8Y\xce5e\xc8\x8b\xa1\xaf\x107\xff\xe3\x9c]\xc2I\x174\xff\x8c+\x8b\x8d\xf0\xbcq,\x93\x0c\x1d\x05\xc4\xba\xc7\xcd\xaa\xc9^|\xd1\xc9\x01\xf7\x9c\x03\xf6\xfc\n]\xf4\xda{\xe6\xdbvBp\xeb\xf4M\"\xda\0wo\xd6\xc9_\x17\xfd\xdau.\xa5W\x0c\xf6\xea\\\xb6\xe0s\xa5h\xcf\xa1t\xe2u\x82~\x10\x9f\xc1\xf5\xa2\xeb\x01\xe98\xb1\nD\xcc\xd3\xc2\x89\xf5I5\x82\n4\xb3\x1c\xe9\x88\xc2GN\x82\x0e\n6\xf0GO\x8a\xf1)\x04u\xda\xcd\xe1\x9a\\\xff^\x9d\x98\x95\xba\x9aC\xd0J\xa2\x17\x05\x01\x040\xd32\xb3\x8f\x02\x03\x01\0\x01\xa3\x81\xf80\x81\xf50\x0e\x06\x03U\x1d\x0f\x01\x01\xff\x04\x04\x03\x02\x01\x860\x1d\x06\x03U\x1d%\x04\x160\x14\x06\x08+\x06\x01\x05\x05\x07\x03\x02\x06\x08+\x06\x01\x05\x05\x07\x03\x010\x12\x06\x03U\x1d\x13\x01\x01\xff\x04\x080\x06\x01\x01\xff\x02\x01\00\x1d\x06\x03U\x1d\x0e\x04\x16\x04\x14\xe7\xab\x9f\x0f,3\xa0S\xd3^Ox\xc8\xb2\x84\x0e;\xd6\x9230\x1f\x06\x03U\x1d#\x04\x180\x16\x80\x14y\xb4Y\xe6{\xb6\xe5\xe4\x01s\x80\x08\x88\xc8\x1aX\xf6\xe9\x9bn02\x06\x08+\x06\x01\x05\x05\x07\x01\x01\x04&0$0\"\x06\x08+\x06\x01\x05\x05\x070\x02\x86\x16http://x1.i.lencr.org/0\x13\x06\x03U\x1d \x04\x0c0\n0\x08\x06\x06g\x81\x0c\x01\x02\x010'\x06\x03U\x1d\x1f\x04 0\x1e0\x1c\xa0\x1a\xa0\x18\x86\x16http://x1.c.lencr.org/0\r\x06\t*\x86H\x86\xf7\r\x01\x01\x0b\x05\0\x03\x82\x02\x01\0Q7XR\xa1\"\x9b5\xbbM\xba\xce\xca\x92\xea\t\xf2\xfbT\xec\x18\x7f\xf4;\xf4\xe1\xf9pr\xc2e\xe8 }\x08Cr\x89\xe5\x93\xb2\xa0\x87\xc6\xf4\xbe/\xbf^\xe5\xae\xec#|\x9f\xf5\x0fz\ro\xa3q\xbe\xb5\xa5\xe2\xae\xbc\xad\xb6\x14\"\x9c\x01\xc6\xc1\xcf\xd4u\xb3\xb2\x80\x96\xbd\xce\xe0\\W*\xa8\x1fp\x97Mp\xc8\x9d?\xbck\xe77hEL'd\xad\xfa\x94\xa7\xe1\xe7~Z@\xe9\xf2(\xec\x8a;\xc4\xc8\\\x04\xe3\xb8n\x95m\x0b\xb78\xe0\xf5\xf3\x95\xe4\xf9\xab\x83\xfc\xf1Y\xb4n/\xe94\x0c\x10\xc7\x10\x97\xa7\x9c+\0z~\xdc\xdf\x93\xe6\xc7\xb8\xe9\x98\x9f\xc7\xb6\x04ar|\xf4\xca4\x81\xbf\"0\xe8\xbdP\"\xead\n\xfd\x92\x04\xe0\xd3\xff\x10\xc3\xde\x07\xd0C\"\xaf\xea\xba\x15\xe0m\x84\x85\xf12\x02\xc5\xa9\x9a\x88\xf1\x8c%\x02\x1a,\xa0\xf7\xb1o\x0e\xd9\xbf4\xad\x8bI\xcfe\xc9\xb2\xb1\x07\xbd\xc8\xdb\xe3\xf6\x1bp\x9aZ\x9b\xef\xa4\x08\x87\t[\xb7\xd25\xbc\x18,Ju\xf8l^\xd9\xc8\xcbh\xa6\xb2D*U\x9d\xa6\xd0\xf9\xb1\xa1\xb6\xf6\xf1;\x9c\xaf\xbcA+\xb0\xad\xc2\xf3\xebo\xbfh\xb3\xbb\xb6\\\xfd\xce\xe5\xff[\xfc~\xba\x18\xdc\x91\xae\tQ^Z\xd8\x8c\x8dh\x19\x82\xff\x7f\x825\x9f\xf4\xa0\xba\xc7Z\xe9k\xc0\xe8-}\xd2LcS^X\xd7i\x87S\x8f\x81\xc7$}s\x1d\xa1\x84d\xbd|\x08\xccd\xa2l\xb3o*\xc6\xfc\xfa\x03\x1b\xb8\t\xa0\xe6D\xd6i+\xfaP\xadqu\xef%\xc2^I\x84Z\x0b\xd28Fr\xe9\x9fiq\xb2\xc8TA\x9c\x91_\xe2U\xea\xb4\0\xea6\xa6H=\xa7\x84\x11#--+gbDCKH]\x8a\xca\xc1pm\x8e\x81\xdb\xa0Ex[7\xbf[\x18U\x18E[\xd9\xcb\x90\xea\xd0V\x9a+\t-\n\xc9\x99\x9f\xc1P\xfc\xf6\xa4\x93\x96w--\xc6g!\xab\xe3*\xc2\x94\xbbY\xc0\xd6%4\xc9\x83\x1da\xeaJG\xb9Vn|!w\x1d\xde\xc2\x89")]
TRACE ALPN negotiated h2, updating pool
TRACE client handshake Http2
DEBUG binding client connection
DEBUG client connection bound
DEBUG FramedWrite::buffer{frame=Settings { flags: (0x0), enable_push: 0, initial_window_size: 2097152, max_frame_size: 16384 }}: send frame=Settings { flags: (0x0), enable_push: 0, initial_window_size: 2097152, max_frame_size: 16384 }
TRACE FramedWrite::buffer{frame=Settings { flags: (0x0), enable_push: 0, initial_window_size: 2097152, max_frame_size: 16384 }}: encoding SETTINGS; len=18
TRACE FramedWrite::buffer{frame=Settings { flags: (0x0), enable_push: 0, initial_window_size: 2097152, max_frame_size: 16384 }}: encoding setting; val=EnablePush(0)
TRACE FramedWrite::buffer{frame=Settings { flags: (0x0), enable_push: 0, initial_window_size: 2097152, max_frame_size: 16384 }}: encoding setting; val=InitialWindowSize(2097152)
TRACE FramedWrite::buffer{frame=Settings { flags: (0x0), enable_push: 0, initial_window_size: 2097152, max_frame_size: 16384 }}: encoding setting; val=MaxFrameSize(16384)
TRACE FramedWrite::buffer{frame=Settings { flags: (0x0), enable_push: 0, initial_window_size: 2097152, max_frame_size: 16384 }}: encoded settings rem=27
TRACE inc_window; sz=65535; old=0; new=65535
TRACE inc_window; sz=65535; old=0; new=65535
TRACE Prioritize::new; flow=FlowControl { window_size: Window(65535), available: Window(65535) }
TRACE set_target_connection_window; target=5242880; available=65535, reserved=0
TRACE handshake complete, spawning background dispatcher task
TRACE Connection{peer=Client}:poll: connection.state=Open
TRACE Connection{peer=Client}:poll:FramedRead::poll_next: poll
DEBUG Connection{peer=Client}:poll:FramedWrite::buffer{frame=WindowUpdate { stream_id: StreamId(0), size_increment: 5177345 }}: send frame=WindowUpdate { stream_id: StreamId(0), size_increment: 5177345 }
TRACE Connection{peer=Client}:poll:FramedWrite::buffer{frame=WindowUpdate { stream_id: StreamId(0), size_increment: 5177345 }}: encoding WINDOW_UPDATE; id=StreamId(0)
TRACE Connection{peer=Client}:poll:FramedWrite::buffer{frame=WindowUpdate { stream_id: StreamId(0), size_increment: 5177345 }}: encoded window_update rem=40
TRACE Connection{peer=Client}:poll: inc_window; sz=5177345; old=65535; new=5242880
TRACE Connection{peer=Client}:poll: poll_complete
TRACE Connection{peer=Client}:poll: schedule_pending_open
TRACE Connection{peer=Client}:poll:FramedWrite::flush: queued_data_frame=false
TRACE Connection{peer=Client}:poll:FramedWrite::flush: flushing buffer
TRACE put; add idle connection for ("https", memvid.com)
DEBUG pooling idle connection for ("https", memvid.com)
TRACE checkout dropped for ("https", memvid.com)
TRACE inc_window; sz=2097152; old=0; new=2097152
TRACE inc_window; sz=65535; old=0; new=65535
TRACE send_headers; frame=Headers { stream_id: StreamId(1), flags: (0x4: END_HEADERS) }; init_window=65535
TRACE Queue::push_back
TRACE  -> first entry
TRACE reserve_capacity{stream.id=StreamId(1) requested=1 effective=1 curr=0}:try_assign_capacity{stream.id=StreamId(1)}: requested=1 additional=1 buffered=0 window=65535 conn=65535
TRACE reserve_capacity{stream.id=StreamId(1) requested=1 effective=1 curr=0}:try_assign_capacity{stream.id=StreamId(1)}: assigning capacity=1
TRACE reserve_capacity{stream.id=StreamId(1) requested=1 effective=1 curr=0}:try_assign_capacity{stream.id=StreamId(1)}:   assigned capacity to stream; available=1; buffered=0; id=StreamId(1); max_buffer_size=1048576 prev=0
TRACE reserve_capacity{stream.id=StreamId(1) requested=1 effective=1 curr=0}:try_assign_capacity{stream.id=StreamId(1)}:   notifying task
TRACE reserve_capacity{stream.id=StreamId(1) requested=1 effective=1 curr=0}:try_assign_capacity{stream.id=StreamId(1)}: available=1 requested=1 buffered=0 has_unavailable=true
TRACE send body chunk: 237 bytes, eos=true
TRACE send_data{sz=237 requested=1}: buffered=237
TRACE send_data{sz=237 requested=1}: send_close: Open => HalfClosedLocal(AwaitingHeaders)
TRACE send_data{sz=237 requested=1}: available=1 buffered=237
TRACE transition_after; stream=StreamId(1); state=State { inner: HalfClosedLocal(AwaitingHeaders) }; is_closed=false; pending_send_empty=false; buffered_send_data=237; num_recv=0; num_send=0
TRACE drop_stream_ref; stream=Stream { id: StreamId(1), state: State { inner: HalfClosedLocal(AwaitingHeaders) }, is_counted: false, ref_count: 2, next_pending_send: None, is_pending_send: false, send_flow: FlowControl { window_size: Window(65535), available: Window(1) }, requested_send_capacity: 237, buffered_send_data: 237, send_task: Some(Waker { data: 0x7fbe24038700, vtable: 0x56103c371c50 }), pending_send: Deque { indices: Some(Indices { head: 0, tail: 1 }) }, next_pending_send_capacity: None, is_pending_send_capacity: false, send_capacity_inc: true, next_open: None, is_pending_open: true, is_pending_push: false, next_pending_accept: None, is_pending_accept: false, recv_flow: FlowControl { window_size: Window(2097152), available: Window(2097152) }, in_flight_recv_data: 0, next_window_update: None, is_pending_window_update: false, reset_at: None, next_reset_expire: None, pending_recv: Deque { indices: None }, is_recv: true, recv_task: None, pending_push_promises: Queue { indices: None, _p: PhantomData<h2::proto::streams::stream::NextAccept> }, content_length: Omitted }
TRACE transition_after; stream=StreamId(1); state=State { inner: HalfClosedLocal(AwaitingHeaders) }; is_closed=false; pending_send_empty=false; buffered_send_data=237; num_recv=0; num_send=0
TRACE Connection{peer=Client}:poll: connection.state=Open
TRACE Connection{peer=Client}:poll:FramedRead::poll_next: poll
TRACE Connection{peer=Client}:poll: poll_complete
TRACE Connection{peer=Client}:poll: schedule_pending_open
TRACE Connection{peer=Client}:poll: schedule_pending_open; stream=StreamId(1)
TRACE Connection{peer=Client}:poll: Queue::push_front
TRACE Connection{peer=Client}:poll:  -> first entry
TRACE Connection{peer=Client}:poll:try_assign_capacity{stream.id=StreamId(1)}: requested=237 additional=236 buffered=237 window=65535 conn=65534
TRACE Connection{peer=Client}:poll:try_assign_capacity{stream.id=StreamId(1)}: assigning capacity=236
TRACE Connection{peer=Client}:poll:try_assign_capacity{stream.id=StreamId(1)}:   assigned capacity to stream; available=237; buffered=237; id=StreamId(1); max_buffer_size=1048576 prev=0
TRACE Connection{peer=Client}:poll:try_assign_capacity{stream.id=StreamId(1)}: available=237 requested=237 buffered=237 has_unavailable=true
TRACE Connection{peer=Client}:poll:try_assign_capacity{stream.id=StreamId(1)}: Queue::push_back
TRACE Connection{peer=Client}:poll:try_assign_capacity{stream.id=StreamId(1)}:  -> already queued
TRACE Connection{peer=Client}:poll:pop_frame:popped{stream.id=StreamId(1) stream.state=State { inner: HalfClosedLocal(AwaitingHeaders) }}: is_pending_reset=false
TRACE Connection{peer=Client}:poll:pop_frame:popped{stream.id=StreamId(1) stream.state=State { inner: HalfClosedLocal(AwaitingHeaders) }}: pop_frame; frame=Headers { stream_id: StreamId(1), flags: (0x4: END_HEADERS) }
TRACE Connection{peer=Client}:poll:pop_frame:popped{stream.id=StreamId(1) stream.state=State { inner: HalfClosedLocal(AwaitingHeaders) }}: Queue::push_back
TRACE Connection{peer=Client}:poll:pop_frame:popped{stream.id=StreamId(1) stream.state=State { inner: HalfClosedLocal(AwaitingHeaders) }}:  -> first entry
TRACE Connection{peer=Client}:poll:pop_frame:popped{stream.id=StreamId(1) stream.state=State { inner: HalfClosedLocal(AwaitingHeaders) }}: transition_after; stream=StreamId(1); state=State { inner: HalfClosedLocal(AwaitingHeaders) }; is_closed=false; pending_send_empty=false; buffered_send_data=237; num_recv=0; num_send=1
TRACE Connection{peer=Client}:poll: writing frame=Headers { stream_id: StreamId(1), flags: (0x4: END_HEADERS) }
DEBUG Connection{peer=Client}:poll:FramedWrite::buffer{frame=Headers { stream_id: StreamId(1), flags: (0x4: END_HEADERS) }}: send frame=Headers { stream_id: StreamId(1), flags: (0x4: END_HEADERS) }
TRACE Connection{peer=Client}:poll: schedule_pending_open
TRACE Connection{peer=Client}:poll:pop_frame:popped{stream.id=StreamId(1) stream.state=State { inner: HalfClosedLocal(AwaitingHeaders) }}: is_pending_reset=false
TRACE Connection{peer=Client}:poll:pop_frame:popped{stream.id=StreamId(1) stream.state=State { inner: HalfClosedLocal(AwaitingHeaders) }}: data frame sz=237 eos=true window=237 available=237 requested=237 buffered=237
TRACE Connection{peer=Client}:poll:pop_frame:popped{stream.id=StreamId(1) stream.state=State { inner: HalfClosedLocal(AwaitingHeaders) }}: sending data frame len=237
TRACE Connection{peer=Client}:poll:pop_frame:popped{stream.id=StreamId(1) stream.state=State { inner: HalfClosedLocal(AwaitingHeaders) }}:updating stream flow: send_data; sz=237; window=65535; available=237
TRACE Connection{peer=Client}:poll:pop_frame:popped{stream.id=StreamId(1) stream.state=State { inner: HalfClosedLocal(AwaitingHeaders) }}:updating stream flow:   sent stream data; available=0; buffered=0; id=StreamId(1); max_buffer_size=1048576 prev=0
TRACE Connection{peer=Client}:poll:pop_frame:popped{stream.id=StreamId(1) stream.state=State { inner: HalfClosedLocal(AwaitingHeaders) }}:updating connection flow: send_data; sz=237; window=65535; available=65535
TRACE Connection{peer=Client}:poll:pop_frame:popped{stream.id=StreamId(1) stream.state=State { inner: HalfClosedLocal(AwaitingHeaders) }}: pop_frame; frame=Data { stream_id: StreamId(1), flags: (0x1: END_STREAM) }
TRACE Connection{peer=Client}:poll:pop_frame:popped{stream.id=StreamId(1) stream.state=State { inner: HalfClosedLocal(AwaitingHeaders) }}: transition_after; stream=StreamId(1); state=State { inner: HalfClosedLocal(AwaitingHeaders) }; is_closed=false; pending_send_empty=true; buffered_send_data=0; num_recv=0; num_send=1
TRACE Connection{peer=Client}:poll: writing frame=Data { stream_id: StreamId(1), flags: (0x1: END_STREAM) }
DEBUG Connection{peer=Client}:poll:FramedWrite::buffer{frame=Data { stream_id: StreamId(1), flags: (0x1: END_STREAM) }}: send frame=Data { stream_id: StreamId(1), flags: (0x1: END_STREAM) }
TRACE Connection{peer=Client}:poll:try_reclaim_frame: reclaimed frame=Data { stream_id: StreamId(1), flags: (0x1: END_STREAM) } sz=0
TRACE Connection{peer=Client}:poll: schedule_pending_open
TRACE Connection{peer=Client}:poll:FramedWrite::flush: queued_data_frame=false
TRACE Connection{peer=Client}:poll:FramedWrite::flush: flushing buffer
TRACE idle interval checking for expired
TRACE Connection{peer=Client}:poll: connection.state=Open
TRACE Connection{peer=Client}:poll:FramedRead::poll_next: poll
TRACE Connection{peer=Client}:poll:FramedRead::poll_next: read.bytes=39
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=39}: decoding frame from 39B
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=39}: frame.kind=Settings
DEBUG Connection{peer=Client}:poll:FramedRead::poll_next: received frame=Settings { flags: (0x0), header_table_size: 4096, max_concurrent_streams: 250, initial_window_size: 1048576, max_frame_size: 1048576, max_header_list_size: 2097472 }
TRACE Connection{peer=Client}:poll: recv SETTINGS frame=Settings { flags: (0x0), header_table_size: 4096, max_concurrent_streams: 250, initial_window_size: 1048576, max_frame_size: 1048576, max_header_list_size: 2097472 }
DEBUG Connection{peer=Client}:poll:poll_ready:FramedWrite::buffer{frame=Settings { flags: (0x1: ACK) }}: send frame=Settings { flags: (0x1: ACK) }
TRACE Connection{peer=Client}:poll:poll_ready:FramedWrite::buffer{frame=Settings { flags: (0x1: ACK) }}: encoding SETTINGS; len=0
TRACE Connection{peer=Client}:poll:poll_ready:FramedWrite::buffer{frame=Settings { flags: (0x1: ACK) }}: encoded settings rem=9
TRACE Connection{peer=Client}:poll:poll_ready: ACK sent; applying settings
TRACE Connection{peer=Client}:poll:FramedRead::poll_next: poll
TRACE Connection{peer=Client}:poll:FramedRead::poll_next: read.bytes=9
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=9}: decoding frame from 9B
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=9}: frame.kind=Settings
DEBUG Connection{peer=Client}:poll:FramedRead::poll_next: received frame=Settings { flags: (0x1: ACK) }
TRACE Connection{peer=Client}:poll: recv SETTINGS frame=Settings { flags: (0x1: ACK) }
DEBUG Connection{peer=Client}:poll: received settings ACK; applying Settings { flags: (0x0), enable_push: 0, initial_window_size: 2097152, max_frame_size: 16384 }
TRACE Connection{peer=Client}:poll: update_initial_window_size; new=2097152; old=2097152
TRACE Connection{peer=Client}:poll:FramedRead::poll_next: poll
TRACE Connection{peer=Client}:poll:FramedRead::poll_next: read.bytes=13
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=13}: decoding frame from 13B
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=13}: frame.kind=WindowUpdate
DEBUG Connection{peer=Client}:poll:FramedRead::poll_next: received frame=WindowUpdate { stream_id: StreamId(0), size_increment: 983041 }
TRACE Connection{peer=Client}:poll: recv WINDOW_UPDATE frame=WindowUpdate { stream_id: StreamId(0), size_increment: 983041 }
TRACE Connection{peer=Client}:poll: inc_window; sz=983041; old=65298; new=1048339
TRACE Connection{peer=Client}:poll:FramedRead::poll_next: poll
TRACE Connection{peer=Client}:poll: poll_complete
TRACE Connection{peer=Client}:poll: schedule_pending_open
TRACE Connection{peer=Client}:poll:FramedWrite::flush: queued_data_frame=false
TRACE Connection{peer=Client}:poll:FramedWrite::flush: flushing buffer
TRACE Connection{peer=Client}:poll: connection.state=Open
TRACE Connection{peer=Client}:poll:FramedRead::poll_next: poll
TRACE Connection{peer=Client}:poll:FramedRead::poll_next: read.bytes=456
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}: decoding frame from 456B
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}: frame.kind=Headers
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}: loading headers; flags=(0x4: END_HEADERS)
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}:hpack::decode: decode
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}:hpack::decode: rem=447 kind=Indexed
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}:hpack::decode: rem=446 kind=LiteralWithIndexing
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}:hpack::decode: rem=419 kind=LiteralWithIndexing
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}:hpack::decode: rem=382 kind=LiteralWithIndexing
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}:hpack::decode: rem=369 kind=LiteralWithIndexing
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}:hpack::decode: rem=345 kind=LiteralWithIndexing
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}:hpack::decode: rem=265 kind=LiteralWithIndexing
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}:hpack::decode: rem=229 kind=LiteralWithIndexing
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}:hpack::decode: rem=222 kind=LiteralWithIndexing
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}:hpack::decode: rem=188 kind=LiteralWithIndexing
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}:hpack::decode: rem=130 kind=LiteralWithIndexing
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}:hpack::decode: rem=106 kind=LiteralWithIndexing
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}:hpack::decode: rem=88 kind=LiteralWithIndexing
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}:hpack::decode: rem=60 kind=LiteralWithIndexing
TRACE Connection{peer=Client}:poll:FramedRead::poll_next:FramedRead::decode_frame{offset=456}:hpack::decode: rem=43 kind=LiteralWithIndexing
DEBUG Connection{peer=Client}:poll:FramedRead::poll_next: received frame=Headers { stream_id: StreamId(1), flags: (0x4: END_HEADERS) }
TRACE Connection{peer=Client}:poll: recv HEADERS frame=Headers { stream_id: StreamId(1), flags: (0x4: END_HEADERS) }
TRACE Connection{peer=Client}:poll: recv_headers; stream=StreamId(1); state=State { inner: HalfClosedLocal(AwaitingHeaders) }
TRACE Connection{peer=Client}:poll: opening stream; init_window=2097152
TRACE Connection{peer=Client}:poll: transition_after; stream=StreamId(1); state=State { inner: HalfClosedLocal(Streaming) }; is_closed=false; pending_send_empty=true; buffered_send_data=0; num_recv=0; num_send=1
TRACE Connection{peer=Client}:poll:FramedRead::poll_next: poll
TRACE Connection{peer=Client}:poll: poll_complete
TRACE Connection{peer=Client}:poll: schedule_pending_open
TRACE Connection{peer=Client}:poll:FramedWrite::flush: flushing buffer
TRACE drop_stream_ref; stream=Stream { id: StreamId(1), state: State { inner: HalfClosedLocal(Streaming) }, is_counted: true, ref_count: 2, next_pending_send: None, is_pending_send: false, send_flow: FlowControl { window_size: Window(65298), available: Window(0) }, requested_send_capacity: 0, buffered_send_data: 0, send_task: None, pending_send: Deque { indices: None }, next_pending_send_capacity: None, is_pending_send_capacity: false, send_capacity_inc: true, next_open: None, is_pending_open: false, is_pending_push: false, next_pending_accept: None, is_pending_accept: false, recv_flow: FlowControl { window_size: Window(2097152), available: Window(2097152) }, in_flight_recv_data: 0, next_window_update: None, is_pending_window_update: false, reset_at: None, next_reset_expire: None, pending_recv: Deque { indices: None }, is_recv: true, recv_task: None, pending_push_promises: Queue { indices: None, _p: PhantomData<h2::proto::streams::stream::NextAccept> }, content_length: Omitted }
TRACE transition_after; stream=StreamId(1); state=State { inner: HalfClosedLocal(Streaming) }; is_closed=false; pending_send_empty=true; buffered_send_data=0; num_recv=0; num_send=1
TRACE drop_stream_ref; stream=Stream { id: StreamId(1), state: State { inner: HalfClosedLocal(Streaming) }, is_counted: true, ref_count: 1, next_pending_send: None, is_pending_send: false, send_flow: FlowControl { window_size: Window(65298), available: Window(0) }, requested_send_capacity: 0, buffered_send_data: 0, send_task: None, pending_send: Deque { indices: None }, next_pending_send_capacity: None, is_pending_send_capacity: false, send_capacity_inc: true, next_open: None, is_pending_open: false, is_pending_push: false, next_pending_accept: None, is_pending_accept: false, recv_flow: FlowControl { window_size: Window(2097152), available: Window(2097152) }, in_flight_recv_data: 0, next_window_update: None, is_pending_window_update: false, reset_at: None, next_reset_expire: None, pending_recv: Deque { indices: None }, is_recv: false, recv_task: None, pending_push_promises: Queue { indices: None, _p: PhantomData<h2::proto::streams::stream::NextAccept> }, content_length: Omitted }
TRACE schedule_send stream.id=StreamId(1)
TRACE Queue::push_back
TRACE  -> first entry
TRACE enqueue_reset_expiration; StreamId(1)
TRACE Queue::push_back
TRACE  -> first entry
TRACE transition_after; stream=StreamId(1); state=State { inner: Closed(ScheduledLibraryReset(CANCEL)) }; is_closed=true; pending_send_empty=true; buffered_send_data=0; num_recv=0; num_send=1
TRACE dec_num_streams; stream=StreamId(1)
TRACE Connection{peer=Client}:poll: connection.state=Open
TRACE Connection{peer=Client}:poll:FramedRead::poll_next: poll
TRACE Connection{peer=Client}:poll: poll_complete
TRACE Connection{peer=Client}:poll: schedule_pending_open
TRACE Connection{peer=Client}:poll:pop_frame:popped{stream.id=StreamId(1) stream.state=State { inner: Closed(ScheduledLibraryReset(CANCEL)) }}: is_pending_reset=true
TRACE Connection{peer=Client}:poll:pop_frame:popped{stream.id=StreamId(1) stream.state=State { inner: Closed(ScheduledLibraryReset(CANCEL)) }}: pop_frame; frame=Reset { stream_id: StreamId(1), error_code: CANCEL }
TRACE Connection{peer=Client}:poll:pop_frame:popped{stream.id=StreamId(1) stream.state=State { inner: Closed(ScheduledLibraryReset(CANCEL)) }}: transition_after; stream=StreamId(1); state=State { inner: Closed(Error(Reset(StreamId(1), CANCEL, Library))) }; is_closed=true; pending_send_empty=true; buffered_send_data=0; num_recv=0; num_send=0
TRACE Connection{peer=Client}:poll: writing frame=Reset { stream_id: StreamId(1), error_code: CANCEL }
DEBUG Connection{peer=Client}:poll:FramedWrite::buffer{frame=Reset { stream_id: StreamId(1), error_code: CANCEL }}: send frame=Reset { stream_id: StreamId(1), error_code: CANCEL }
TRACE Connection{peer=Client}:poll:FramedWrite::buffer{frame=Reset { stream_id: StreamId(1), error_code: CANCEL }}: encoding RESET; id=StreamId(1) code=CANCEL
TRACE Connection{peer=Client}:poll:FramedWrite::buffer{frame=Reset { stream_id: StreamId(1), error_code: CANCEL }}: encoded reset rem=13
TRACE Connection{peer=Client}:poll: schedule_pending_open
TRACE Connection{peer=Client}:poll:FramedWrite::flush: queued_data_frame=false
TRACE Connection{peer=Client}:poll:FramedWrite::flush: flushing buffer
TRACE closing runtime thread (ThreadId(2))
TRACE signaled close for runtime thread (ThreadId(2))
TRACE (ThreadId(2)) Receiver is shutdown
TRACE (ThreadId(2)) end runtime::block_on
TRACE Streams::recv_eof
TRACE transition_after; stream=StreamId(1); state=State { inner: Closed(Error(Reset(StreamId(1), CANCEL, Library))) }; is_closed=true; pending_send_empty=true; buffered_send_data=0; num_recv=0; num_send=0
TRACE transition_after; stream=StreamId(1); state=State { inner: Closed(Error(Reset(StreamId(1), CANCEL, Library))) }; is_closed=true; pending_send_empty=true; buffered_send_data=0; num_recv=0; num_send=0
TRACE (ThreadId(2)) finished
TRACE closed runtime thread (ThreadId(2))
I/O error: No such file or directory (os error 2)
```

There is _very_ clear phone-home. There is no command-line option to disable
this, nor mention of it in the help;

```sh
$ ./memvid --help
Memvid single-file memory CLI

Usage: memvid [OPTIONS] [COMMAND]

Commands:
  create              Create a new `.mv2` memory file
  open                Inspect metadata and manifests for an existing memory
  put                 Append a frame to the memory, optionally with metadata
  correct             Store a correction with retrieval priority boost
  put-many            Batch ingest multiple documents with pre-computed embeddings
  api-fetch           Fetch remote content and ingest it as frames
  view                View a single frame
  update              Update an existing frame
  delete              Delete a frame from the memory
  timeline            View the timeline of frames
  ask                 Ask questions with retrieval + synthesis
  audit               Generate an audit report with full source provenance
  find                Perform lexical search over the memory
  vec-search          Perform vector similarity search
  debug-segment       Dump raw vector segment bytes for debugging
  when                Resolve temporal phrases and list matching frames
  stats               Display statistics about the memory
  verify              Run integrity verification checks
  doctor              Run doctor workflows to repair or optimise the memory
  process-queue       Process the enrichment queue (re-extract skim frames, update indexes)
  verify-single-file  Ensure no auxiliary files exist alongside the memory
  tables              Extract, list, export, and view tables from documents
  tickets             Manage access tickets via the API
  plan                View and manage your plan/subscription
  binding             Show memory binding information
  config              Manage persistent CLI configuration (API keys, settings)
  status              Show configuration and system status
  who                 Show the active writer holding the lock
  nudge               Request the active writer flush and release when safe
  enrich              Run enrichment engines to extract memory cards from frames
  memories            View extracted memory cards
  state               Query current entity state (O(1) lookup)
  facts               Audit fact changes with provenance and filtering
  export              Export facts to N-Triples, JSON, or CSV format
  schema              Infer and manage predicate schemas
  models              Manage LLM models for enrichment
  follow              Traverse the Logic-Mesh entity graph
  sketch              Build and manage sketch track for fast candidate generation
  session             Manage time-travel replay sessions
  lock                Encrypt a memory file into an encrypted capsule (.mv2e)
  unlock              Decrypt an encrypted capsule (.mv2e) back to a `.mv2` file
  version             Print version information for debugging scripts
  help                Print this message or the help of the given subcommand(s)

Options:
  -v, --verbose...                   Increase logging verbosity (use multiple times for more detail)
  -m, --embedding-model <MODEL>      Default embedding model (used by `put --embedding` and by semantic queries when needed): bge-small (fast, default), bge-base, nomic (high accuracy), gte-large, openai (requires OPENAI_API_KEY), openai-small, openai-ada, nvidia (requires NVIDIA_API_KEY)
      --parallel-segments            Enable the parallel segment builder globally (requires --features parallel_segments)
      --global-no-parallel-segments  Force the legacy ingestion path globally
  -h, --help                         Print help
  -V, --version                      Print version
```

The _only_ reference to telemetry I have been able to find is this single
mention in the [CLI
Documentation](https://docs.memvid.com/cli/index#environment-variables), which
mentions that there is a `MEMVID_TELEMETRY` environment variable which, when
set to 0, disables telemetry.

```sh
$ MEMVID_TELEMETRY=0 ./memvid -vvvv open /there/is/no/file/at/this/path.mv2
DEBUG No API key set, using free tier limits
I/O error: No such file or directory (os error 2)
```

I can at least report that that seems to work. That's faint praise, however, as
_I was never informed up-front about this telemetry_.
