#!/bin/bash
# Update script for blocklists
# Fetches upstream sources and regenerates clean format-separated files
#
# Usage: ./update.sh [OPTIONS]
#   --hagezi            Enable Hagezi Pro Plus (default: on)
#   --no-hagezi         Disable Hagezi Pro Plus
#   --oisd              Enable OISD Small (default: on)
#   --no-oisd           Disable OISD Small
#   --darthvader        Enable darthvader666uk streaming ads (default: on)
#   --no-darthvader     Disable darthvader666uk streaming ads
#   --lit-bg            Enable lit-bg/Peacock (default: on)
#   --no-lit-bg         Disable lit-bg/Peacock
#   --ajstrick81        Enable ajstrick81/Peacock-Ads (default: on)
#   --no-ajstrick81     Disable ajstrick81/Peacock-Ads
#   --peacock-only      Generate peacock-only lists (lit-bg + seeds) to lists/peacock-*.txt
#   --help              Show this help
#
# Sources can also be configured via environment variables:
#   ENABLE_HAGEZI=1, ENABLE_OISD=1, ENABLE_DARTHVADER=1, ENABLE_LIT_BG=1, ENABLE_AJSTRICK81=1
#   Set to 0 to disable

set -euo pipefail

# Default source toggles (can be overridden by env vars or CLI args)
ENABLE_HAGEZI="${ENABLE_HAGEZI:-1}"
ENABLE_OISD="${ENABLE_OISD:-1}"
ENABLE_DARTHVADER="${ENABLE_DARTHVADER:-1}"
ENABLE_LIT_BG="${ENABLE_LIT_BG:-1}"
ENABLE_AJSTRICK81="${ENABLE_AJSTRICK81:-1}"
PEACOCK_ONLY="${PEACOCK_ONLY:-0}"

# Parse CLI args
for arg in "$@"; do
  case "$arg" in
    --hagezi) ENABLE_HAGEZI=1 ;;
    --no-hagezi) ENABLE_HAGEZI=0 ;;
    --oisd) ENABLE_OISD=1 ;;
    --no-oisd) ENABLE_OISD=0 ;;
    --darthvader) ENABLE_DARTHVADER=1 ;;
    --no-darthvader) ENABLE_DARTHVADER=0 ;;
    --lit-bg) ENABLE_LIT_BG=1 ;;
    --no-lit-bg) ENABLE_LIT_BG=0 ;;
    --ajstrick81) ENABLE_AJSTRICK81=1 ;;
    --no-ajstrick81) ENABLE_AJSTRICK81=0 ;;
    --peacock-only) PEACOCK_ONLY=1 ;;
    --help)
      grep '^#' "$0" | head -20 | cut -c4-
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

# Peacock-only mode: disable all other sources, enable only lit-bg, output to peacock-* files
if [ "$PEACOCK_ONLY" = 1 ]; then
  ENABLE_HAGEZI=0
  ENABLE_OISD=0
  ENABLE_DARTHVADER=0
  ENABLE_LIT_BG=1
  ENABLE_AJSTRICK81=0
  OUTPUT_PREFIX="peacock-"
  echo "=== Peacock-only mode (lit-bg + seeds) ==="
else
  OUTPUT_PREFIX=""
fi

echo "=== Updating blocklists ==="
echo "Sources enabled: $([ "$ENABLE_HAGEZI" = 1 ] && echo -n "hagezi ")$([ "$ENABLE_OISD" = 1 ] && echo -n "oisd ")$([ "$ENABLE_DARTHVADER" = 1 ] && echo -n "darthvader ")$([ "$ENABLE_LIT_BG" = 1 ] && echo -n "lit-bg ")$([ "$ENABLE_AJSTRICK81" = 1 ] && echo -n "ajstrick81 ")"

# Temp directory for raw downloads
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Fetch sources
if [ "$ENABLE_HAGEZI" = 1 ]; then
  echo "Fetching Hagezi Pro Plus..."
  curl -sL "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.plus.txt" \
    -o "$TMPDIR/hagezi-pro.txt" 2>/dev/null || echo "  (Hagezi fetch failed)"
fi

if [ "$ENABLE_OISD" = 1 ]; then
  echo "Fetching OISD small..."
  curl -sL "https://raw.githubusercontent.com/sjhgvr/oisd/main/domainswild2_small.txt" \
    -o "$TMPDIR/oisd.txt" 2>/dev/null || echo "  (OISD fetch failed)"
fi

if [ "$ENABLE_DARTHVADER" = 1 ]; then
  echo "Fetching darthvader666uk streaming ads..."
  curl -sL "https://gist.githubusercontent.com/darthvader666uk/ccfdab18b9d59830876c373db8b4210d/raw/filterlist.txt" \
    -o "$TMPDIR/darthvader.txt" 2>/dev/null || echo "  (darthvader666uk fetch failed)"
fi

if [ "$ENABLE_LIT_BG" = 1 ]; then
  echo "Fetching lit-bg/Peacock filterlist..."
  curl -sL "https://raw.githubusercontent.com/lit-bg/Peacock/main/filterlist.txt" \
    -o "$TMPDIR/peacock.txt" 2>/dev/null || echo "  (lit-bg/Peacock fetch failed)"
fi

if [ "$ENABLE_AJSTRICK81" = 1 ]; then
  echo "Fetching ajstrick81/Peacock-Ads..."
  curl -sL "https://raw.githubusercontent.com/ajstrick81/Peacock-Ads/main/peacock-adguard-user-rules.txt" \
    -o "$TMPDIR/ajstrick81.txt" 2>/dev/null || echo "  (ajstrick81/Peacock-Ads fetch failed)"
fi

# Build adblock.txt - AdBlock format (||domain^)
echo "Building adblock.txt..."
{
  echo "# Generated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# AdBlock format for Technitium adblockListUrls"
  echo ""
  
  # Seed streaming ad rules
  cat <<'EOF'
# Peacock streaming ads
||g*-sle-us-cmaf-prd-fy.cdn.peacocktv.com^$important
||mparticle.com^$important
||fwmrm.net^$important
||scorecardresearch.com^$important
||omtrdc.net^$important
||ingest.webcol.sdp.peacocktv.com^$important
||telemetry.nbcuott.com^$important
||ssai.peacocktv.com^$important

# HBO Max / Max
||hbo.com^$important
||hbomax.com^$important
||max.com^$important

# Disney+
||disneyplus.com^$important
||dssott.com^$important
||bamgrid.com^$important

# Paramount+
||paramountplus.com^$important
||cbs.com^$important
||cbsinteractive.com^$important

# Roku
||roku.com^$important
||rovicorp.com^$important
||ravm.tv^$important

# Apple TV+
||apple.com^$important
||appletv.com^$important
||skadnetwork.com^$important

# Generic streaming trackers
||segment.io^$important
||mixpanel.com^$important
||amplitude.com^$important
||heap.io^$important
EOF

  # Hagezi Pro Plus is already in AdBlock format - extract ||domain^ lines
  if [ "$ENABLE_HAGEZI" = 1 ] && [[ -f "$TMPDIR/hagezi-pro.txt" ]]; then
    grep -E '^\|\|[^|]+\^' "$TMPDIR/hagezi-pro.txt" | head -50000 || true
  fi
  
  # lit-bg/Peacock - extract ||domain^ lines (AdBlock format)
  if [ "$ENABLE_LIT_BG" = 1 ] && [[ -f "$TMPDIR/peacock.txt" ]]; then
    grep -E '^\|\|[^|]+\^' "$TMPDIR/peacock.txt" | head -5000 || true
  fi
  
  # darthvader666uk streaming ads - extract ||domain^ lines
  if [ "$ENABLE_DARTHVADER" = 1 ] && [[ -f "$TMPDIR/darthvader.txt" ]]; then
    grep -E '^\|\|[^|]+\^' "$TMPDIR/darthvader.txt" | head -5000 || true
  fi
  
  # ajstrick81 Peacock-Ads - extract ||domain^ lines
  if [ "$ENABLE_AJSTRICK81" = 1 ] && [[ -f "$TMPDIR/ajstrick81.txt" ]]; then
    grep -E '^\|\|[^|]+\^' "$TMPDIR/ajstrick81.txt" | head -5000 || true
  fi
  
  # Convert OISD wildcards to AdBlock format
  if [ "$ENABLE_OISD" = 1 ] && [[ -f "$TMPDIR/oisd.txt" ]]; then
    grep -E '^\*\.' "$TMPDIR/oisd.txt" | sed 's/^\*\.//; s/$/\^/' | sed 's/^/||/' | head -20000 || true
    # Also plain domains in OISD
    grep -v '^#' "$TMPDIR/oisd.txt" | grep -v '^\*' | sed 's/^/||/; s/$/\^/' | head -20000 || true
  fi
} | sort -u > "lists/${OUTPUT_PREFIX}adblock.txt.new" && mv "lists/${OUTPUT_PREFIX}adblock.txt.new" "lists/${OUTPUT_PREFIX}adblock.txt"

# Build regex.txt - .NET regex format
echo "Building regex.txt..."
{
  echo "# Generated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# .NET Regex format for Technitium regexBlockListUrls"
  echo "# One pattern per line, NO / delimiters"
  echo ""
  
  # Peacock converted regex
  cat <<'EOF'
# Peacock streaming ads - converted from /.../ JS regex
^(g\d{3})-(vod|sf|sle)-us-cmaf-prd-(ak.*|cf|cc)\.cdn\.peacocktv\.com$
^(g\d{3})-(vod|sle)-us-cmaf-prd-ns\.prd\.pck\.netskrt\.net$

# Generic ad subdomain patterns
^ads\d*\.
^adserver\d*\.
^adserving\d*\.
^adcache\d*\.
^adext\d*\.
^adspace\d*\.

# Telemetry/analytics subdomains
^telemetry\.
^analytics\.
^metrics\.
^tracking\.
^events\.
^collect\.
^beacon\.
^pixel\.

# Native device trackers
^native\.amazon\.
^native\.roku\.
^native\.samsung\.
^native\.apple\.
^native\.lgwebos\.
^native\.tiktok\.
EOF

  # Extract /.../ regex from Peacock source if available
  if [ "$ENABLE_LIT_BG" = 1 ] && [[ -f "$TMPDIR/peacock.txt" ]]; then
    grep -E '^/.*/$' "$TMPDIR/peacock.txt" | sed 's|^/||; s|/$||' || true
  fi
} | sort -u > "lists/${OUTPUT_PREFIX}regex.txt.new" && mv "lists/${OUTPUT_PREFIX}regex.txt.new" "lists/${OUTPUT_PREFIX}regex.txt"

# Build hosts.txt - plain domains
echo "Building hosts.txt..."
{
  echo "# Generated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# Plain domains for Technitium blockListUrls"
  echo ""
  
  cat <<'EOF'
# Major ad/tracking networks
doubleclick.net
googleadservices.com
googlesyndication.com
googletagmanager.com
google-analytics.com
facebook.net
fbcdn.net
connect.facebook.net
twitter.com
t.co
analytics.twitter.com
ads.twitter.com
linkedin.com
ads.linkedin.com
pinterest.com
ads.pinterest.com
snapchat.com
ads.snapchat.com
tiktok.com
ads.tiktok.com
ads.tiktokv.com
adjust.com
appsflyer.com
branch.io
kochava.com
tenjin.io
singular.net

# Streaming service ad domains
ingest.webcol.sdp.peacocktv.com
telemetry.nbcuott.com
ssai.peacocktv.com
mparticle.com
fwmrm.net
scorecardresearch.com
omtrdc.net
segment.io
mixpanel.com
amplitude.com
heap.io

# Native device trackers
native.amazon
native.roku
native.samsung
native.apple
native.lgwebos
native.tiktok

# DoH bypass domains
doh.cleanbrowsing.org
doh.dns.sb
doh.libredns.gr
doh.dnsforge.de
dns.cloudflare.com
dns.google
dns.quad9.net
dns.adguard.com
dns.nextdns.io
EOF

  # Hagezi Pro Plus - extract domains from ||domain^ format
  if [ "$ENABLE_HAGEZI" = 1 ] && [[ -f "$TMPDIR/hagezi-pro.txt" ]]; then
    grep -E '^\|\|[^|]+\^' "$TMPDIR/hagezi-pro.txt" | sed -E 's/\|\|([^|]+)\^/\1/' | head -50000 || true
  fi
  
  # lit-bg/Peacock - extract domains from ||domain^ format
  if [ "$ENABLE_LIT_BG" = 1 ] && [[ -f "$TMPDIR/peacock.txt" ]]; then
    grep -E '^\|\|[^|]+\^' "$TMPDIR/peacock.txt" | sed -E 's/\|\|([^|]+)\^/\1/' | head -5000 || true
  fi
  
  # darthvader666uk streaming ads - extract domains from ||domain^ format
  if [ "$ENABLE_DARTHVADER" = 1 ] && [[ -f "$TMPDIR/darthvader.txt" ]]; then
    grep -E '^\|\|[^|]+\^' "$TMPDIR/darthvader.txt" | sed -E 's/\|\|([^|]+)\^/\1/' | head -5000 || true
  fi
  
  # ajstrick81 Peacock-Ads - extract domains from ||domain^ format
  if [ "$ENABLE_AJSTRICK81" = 1 ] && [[ -f "$TMPDIR/ajstrick81.txt" ]]; then
    grep -E '^\|\|[^|]+\^' "$TMPDIR/ajstrick81.txt" | sed -E 's/\|\|([^|]+)\^/\1/' | head -5000 || true
  fi
  
  # OISD domains (strip wildcards and comments)
  if [ "$ENABLE_OISD" = 1 ] && [[ -f "$TMPDIR/oisd.txt" ]]; then
    grep -E '^\*\.' "$TMPDIR/oisd.txt" | sed 's/^\*\.//' | head -50000 || true
    grep -v '^#' "$TMPDIR/oisd.txt" | grep -v '^\*' | head -50000 || true
  fi
} | sort -u > "lists/${OUTPUT_PREFIX}hosts.txt.new" && mv "lists/${OUTPUT_PREFIX}hosts.txt.new" "lists/${OUTPUT_PREFIX}hosts.txt"

echo "=== Done ==="
echo "Files updated:"
wc -l "lists/${OUTPUT_PREFIX}adblock.txt" "lists/${OUTPUT_PREFIX}regex.txt" "lists/${OUTPUT_PREFIX}hosts.txt"