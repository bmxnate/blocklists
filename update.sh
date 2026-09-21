#!/bin/bash
# Update script for blocklists
# Fetches upstream sources and regenerates clean format-separated files

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

echo "=== Updating blocklists ==="

# Temp directory for raw downloads
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Fetch Hagezi Multi PRO Plus (AdBlock format)
echo "Fetching Hagezi Pro Plus..."
curl -sL "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.plus.txt" \
  -o "$TMPDIR/hagezi-pro.txt" 2>/dev/null || echo "  (Hagezi fetch failed)"

# Fetch OISD small (domains with wildcards)
echo "Fetching OISD small..."
curl -sL "https://raw.githubusercontent.com/sjhgvr/oisd/main/domainswild2_small.txt" \
  -o "$TMPDIR/oisd.txt" 2>/dev/null || echo "  (OISD fetch failed)"

# Fetch darthvader666uk streaming ads (from gist)
echo "Fetching darthvader666uk streaming ads..."
curl -sL "https://gist.githubusercontent.com/darthvader666uk/ccfdab18b9d59830876c373db8b4210d/raw/filterlist.txt" \
  -o "$TMPDIR/darthvader.txt" 2>/dev/null || echo "  (darthvader666uk fetch failed)"

# Fetch Peacock filterlist
echo "Fetching Peacock filterlist..."
curl -sL "https://raw.githubusercontent.com/thepeacockproject/Peacock/main/filterlist.txt" \
  -o "$TMPDIR/peacock.txt" 2>/dev/null || echo "  (Peacock fetch failed)"

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
  if [[ -f "$TMPDIR/hagezi-pro.txt" ]]; then
    grep -E '^\|\|[^|]+\^' "$TMPDIR/hagezi-pro.txt" | head -50000 || true
  fi
  
  # darthvader666uk streaming ads - extract ||domain^ lines
  if [[ -f "$TMPDIR/darthvader.txt" ]]; then
    grep -E '^\|\|[^|]+\^' "$TMPDIR/darthvader.txt" | head -5000 || true
  fi
  
  # Convert OISD wildcards to AdBlock format
  if [[ -f "$TMPDIR/oisd.txt" ]]; then
    grep -E '^\*\.' "$TMPDIR/oisd.txt" | sed 's/^\*\.//; s/$/\^/' | sed 's/^/||/' | head -20000 || true
    # Also plain domains in OISD
    grep -v '^#' "$TMPDIR/oisd.txt" | grep -v '^\*' | sed 's/^/||/; s/$/\^/' | head -20000 || true
  fi
} | sort -u > lists/adblock.txt.new && mv lists/adblock.txt.new lists/adblock.txt

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
  if [[ -f "$TMPDIR/peacock.txt" ]]; then
    grep -E '^/.*/$' "$TMPDIR/peacock.txt" | sed 's|^/||; s|/$||' || true
  fi
} | sort -u > lists/regex.txt.new && mv lists/regex.txt.new lists/regex.txt

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
  if [[ -f "$TMPDIR/hagezi-pro.txt" ]]; then
    grep -E '^\|\|[^|]+\^' "$TMPDIR/hagezi-pro.txt" | sed -E 's/\|\|([^|]+)\^/\1/' | head -50000 || true
  fi
  
  # darthvader666uk streaming ads - extract domains from ||domain^ format
  if [[ -f "$TMPDIR/darthvader.txt" ]]; then
    grep -E '^\|\|[^|]+\^' "$TMPDIR/darthvader.txt" | sed -E 's/\|\|([^|]+)\^/\1/' | head -5000 || true
  fi
  
  # OISD domains (strip wildcards and comments)
  if [[ -f "$TMPDIR/oisd.txt" ]]; then
    grep -E '^\*\.' "$TMPDIR/oisd.txt" | sed 's/^\*\.//' | head -50000 || true
    grep -v '^#' "$TMPDIR/oisd.txt" | grep -v '^\*' | head -50000 || true
  fi
} | sort -u > lists/hosts.txt.new && mv lists/hosts.txt.new lists/hosts.txt

echo "=== Done ==="
echo "Files updated:"
wc -l lists/adblock.txt lists/regex.txt lists/hosts.txt