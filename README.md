# BlackBar

Native macOS menu bar app for Blacksmith CI status and active vCPU usage.

What it shows:

- Blacksmith public status from `https://status.blacksmith.sh/summary.json`
- Active vCPU and job totals from Blacksmith's core-usage dashboard API
- Live platform buckets for amd64, arm64, and macOS usage
- Tiny menu bar history graph

Auth:

- Login uses Blacksmith's GitHub OAuth flow in a native WebKit window.
- The resulting Blacksmith session cookie is stored in Keychain.

Build/run:

```sh
make run
```

Defaults:

- org: `openclaw`
- repo filter: empty means scan all org jobs returned by Blacksmith
- interval: 60s
