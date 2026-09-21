# Curated Blocklists for Technitium Advanced Blocking App

This repository provides clean, format-separated blocklists optimized for **Technitium DNS Server**'s **Advanced Blocking App**.

## Lists

| File | Format | Technitium Config Field | Lines |
|------|--------|------------------------|-------|
| `lists/adblock.txt` | AdBlock (`\|\|domain^`, `@@\|\|exception^`) | `adblockListUrls` | ~37k |
| `lists/regex.txt` | .NET Regex (one per line, no delimiters) | `regexBlockListUrls` | ~30 |
| `lists/hosts.txt` | Plain domains (one per line) | `blockListUrls` | ~91k |

## Quick Start

### 1. Install Advanced Blocking App
In Technitium Web UI → **Apps** → **App Store** → search "Advanced Blocking" → **Install**

### 2. Configure
Click the app's **Config** button and paste:

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
        "https://raw.githubusercontent.com/bmxnate/blocklists/main/lists/adblock.txt"
      ],
      "regexBlockListUrls": [
        "https://raw.githubusercontent.com/bmxnate/blocklists/main/lists/regex.txt"
      ],
      "blockListUrls": [
        "https://raw.githubusercontent.com/bmxnate/blocklists/main/lists/hosts.txt"
      ]
    }
  ]
}
```

Adjust `networkGroupMap` to assign different client subnets to different groups if desired.

## Sources Aggregated

| Source | Description |
|--------|-------------|
| **Hagezi Multi PRO** | Ads, tracking, malware, phishing, telemetry (~100k wildcards) |
| **OISD Small** | Curated ads/tracking/malware (~56k wildcards + domains) |
| **Peacock Project** | Streaming service ad domains (Peacock, HBO, Disney+, etc.) |
| **Custom seeds** | Native device trackers, DoH bypass domains, major ad networks |

All sources are merged, converted to three formats, and deduplicated.

## Automated Updates

A GitHub Actions workflow runs **every Saturday 01:00 UTC**:
1. Fetches latest upstream sources
2. Regenerates all three list files
3. Commits & pushes if changed

Technitium auto-fetches on its `blockListUrlUpdateIntervalHours` schedule (default 24h).

### Manual Update
```bash
./update.sh
git add -A && git commit -m "Update blocklists" && git push
```

## Format Reference

| Format | Syntax | Example |
|--------|--------|---------|
| **AdBlock** | `\|\|domain^`, `@@\|\|exception^` | `\|\|googleadservices.com^` |
| **.NET Regex** | Raw regex, one per line | `^ads\d*\.\` |
| **Hosts** | Plain domain, one per line | `doubleclick.net` |

**Notes:**
- Regex uses **.NET engine** — no `/.../` delimiters, escape backslashes in JSON (`\\\\.`)
- AdBlock wildcards (`*`) allowed; options after `$`
- Hosts: bare domains only, no `0.0.0.0` prefix

## Repository Structure

```
blocklists/
├── .github/workflows/update-blocklists.yml  # Weekly automation
├── lists/
│   ├── adblock.txt      # AdBlock format
│   ├── regex.txt        # .NET regex format
│   └── hosts.txt        # Plain domains
├── update.sh            # Local update script
└── README.md
```

## License

Upstream sources retain their original licenses (MIT, GPL-3.0, etc.). This repo's automation code is MIT.