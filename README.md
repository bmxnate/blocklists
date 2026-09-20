# Curated Blocklists for Technitium Advanced Blocking App

This repository provides clean, format-separated blocklists optimized for Technitium DNS Server's **Advanced Blocking App**.

## Files

| File | Format | Technitium Config Field |
|------|--------|------------------------|
| `adblock.txt` | AdBlock (`||domain^`, `@@||exception^`) | `adblockListUrls` |
| `regex.txt` | .NET Regex (one per line, no delimiters) | `regexBlockListUrls` |
| `hosts.txt` | Plain domains (one per line) | `blockListUrls` |

## Usage in Technitium

Install the **Advanced Blocking App** from the App Store, then configure via the Config button:

```json
{
  "enableBlocking": true,
  "blockingAnswerTtl": 30,
  "blockListUrlUpdateIntervalHours": 24,
  "networkGroupMap": {
    "0.0.0.0/0": "everyone",
    "[::]/0": "everyone"
  },
  "groups": [
    {
      "name": "everyone",
      "enableBlocking": true,
      "allowTxtBlockingReport": true,
      "blockAsNxDomain": true,
      "blockingAddresses": ["0.0.0.0", "::"],
      "adblockListUrls": [
        "https://raw.githubusercontent.com/bmxnate/blocklists/main/adblock.txt"
      ],
      "regexBlockListUrls": [
        "https://raw.githubusercontent.com/bmxnate/blocklists/main/regex.txt"
      ],
      "blockListUrls": [
        "https://raw.githubusercontent.com/bmxnate/blocklists/main/hosts.txt"
      ]
    }
  ]
}
```

## Sources Aggregated

- **Streaming service ads**: Peacock, HBO Max, Disney+, Paramount+, Roku, etc.
- **Tracking/telemetry**: Hagezi, OISD, Blocklist Project, AdGuard
- **Malware/phishing**: Blocklist Project, URLHaus
- **Custom**: Local additions in `custom/` directory

## Update Process

Run the update script to fetch upstream sources and regenerate clean files:

```bash
./update.sh
```

Then commit and push. Technitium will auto-fetch on its `blockListUrlUpdateIntervalHours` schedule.

## Format Notes

- **AdBlock**: Uses `||domain^` syntax. Wildcards (`*`) allowed. Options after `$`.
- **.NET Regex**: Full .NET regex engine. No `/.../` delimiters. Escape backslashes in JSON (`\\.` not `\.`).
- **Hosts**: Plain `domain.com` or `sub.domain.com` — one per line. No `0.0.0.0` prefix needed.