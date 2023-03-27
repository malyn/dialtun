# dialtun

**Dynamic routing of public HTTPS endpoints to internal ports on your
Tailscale-connected development machines.**

`dialtun` maps server names in the form `SERVICE-MACHINE.example.com` (where
`example.com` is any domain you control) to internal machines on your Tailnet.
`MACHINE` is the exact name of a machine in the Tailscale network. `SERVICE` is
mapped to a port number by referencing the labels on a (US-based) telephone
dialpad:

<pre style="font-family: Menlo; line-height: 1.2em;">
┌─────────────────────────┐
│ ┌─────┐ ┌─────┐ ┌─────┐ │
│ │     │ │ ABC │ │ DEF │ │
│ │  1  │ │  2  │ │  3  │ │
│ └─────┘ └─────┘ └─────┘ │
│ ┌─────┐ ┌─────┐ ┌─────┐ │
│ │ GHI │ │ JKL │ │ MNO │ │
│ │  4  │ │  5  │ │  6  │ │
│ └─────┘ └─────┘ └─────┘ │
│ ┌─────┐ ┌─────┐ ┌─────┐ │
│ │PQRS │ │ TUV │ │WXYZ │ │
│ │  7  │ │  8  │ │  9  │ │
│ └─────┘ └─────┘ └─────┘ │
│         ┌─────┐         │
│         │     │         │
│         │  0  │         │
│         └─────┘         │
└─────────────────────────┘
</pre>

A base port number -- 64000, by default -- is added to the first three numbers
of the service name. The final result is that a domain name like
"agendas-devbox1.dev.example.com" would map to port 64243 (64000 + 243) on the
"devbox1" machine on your Tailnet.

## Important Security Warning

`dialtun` does _not_ authenticate incoming connections. Any port in the
configured range (64000-64999, by default) is accessible on the public Internet.
Tailscale ACLs are still consulted, but if you open port 64000 on your machine,
then you should expect that random machines on the Internet _will_ connect to
that port.

In other words, goal of `dialtun` is not to create a _secure_ way to talk to
your internal services -- use normal Tailscale sharing and ACLs for that -- the
goal is agility and flexibility. The _assumption_ is that whatever you are
exposing has its own auth model, or is a simple website that is not secret.

## Setup Instructions

### Create Tailscale ACL Tag

Add an ACL tag to your
[Tailscale Access Controls](https://login.tailscale.com/admin/acls):

1. Add a new tag to the `tagOwners` list, something like this:

    ```json
    // ACL tags.
    "tagOwners": {
        "tag:dialtun": [],
    },
    ```

2. Add a section for `dialtun` to the `acls` block (assuming you keep the
   default port range of 64000-64999):

    ```json
    "acls": [
        // ...

        // dialtun can access dev server ports on all machines.
        {
            "action": "accept",
            "src":    ["tag:dialtun"],
            "dst":    ["autogroup:members:64000-64999"],
        },

        // ...
    ],
    ```

3. (Optionally) Add an ACL test to verify that `dialtun` can access the dev
   server ports, but not any other ports (such as SSH) on the dev machines (this
   assumes a dev machine of "devbox1"):

    ```json
     "acls": [
        // ...

        // dialtun can access the dev ports on all machines (but not SSH).
        {
            "src":    "tag:dialtun",
            "accept": ["devbox1:64243", "devbox1:64999"],
            "deny":   ["devbox1:22"],
        },

        // ...
     ],
    ```

### Create Tailscale Auth Key

Create a Tailscale auth key. The key should be Reusable, Ephemeral, and include
the `dialtun` tag that you defined earlier.

### Create `dialtun` App in Fly.io

_Create_ (but do not yet deploy, since we need to add secrets) the `dialtun` app
on Fly.io:

```shell
$ flyctl launch --build-only --image ghcr.io/malyn/dialtun:latest
```

You can choose an app name, or go with the auto-generated default. The app name
will not be used, assuming that you create the `CNAME` mapping in the next step.

### Create Wildcard TLS Certificate

Add an IP address to your app, then create a _wildcard_ TLS certificate; both
will require adding DNS entries to your DNS server. This is documented on the
Fly.io
[Custom Domains and SSL Certificates page](https://fly.io/docs/app-guides/custom-domains-with-fly/).

### Add Tailscale Auth Key to Fly.io App

Add the Tailscale auth key secret to the app:

```shell
$ flyctl secrets import
TS_AUTHKEY=tskey-auth-...
<Ctrl-D>
```

Using `flyctl secrets import` means that your secrets will not show up in your
shell's command history. Press `Control-D` on a blank line to complete the
input. `flyctl` will respond with "Secrets are staged for the first deployment"

### Deploy the Fly.io App

Deploy the app:

```shell
$ flyctl deploy
```

That's it! You can then access internal machines using `dialtun` URLs.
