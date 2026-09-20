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

# Fetch darthvader666uk gist (AdGuard streaming list)
echo "Fetching darthvader666uk gist..."
curl -sL "https://gist.githubusercontent.com/darthvader666uk/ccfdab18b9d59830876c373db8b4210d/raw/filterlist.txt" \
  -o "$TMPDIR/darthvader.txt" 2>/dev/null || echo "  (gist file not directly accessible, using known domains)"

# Fetch Peacock filterlist from thepeacockproject
echo "Fetching Peacock filterlist..."
curl -sL "https://raw.githubusercontent.com/thepeacockproject/Peacock/main/filterlist.txt" \
  -o "$TMPDIR/peacock.txt" 2>/dev/null || echo "  (Peacock filterlist not at expected path)"

# Fetch Hagezi Multi PRO (base for darthvader666uk)
echo "Fetching Hagezi Multi PRO..."
curl -sL "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/pro.txt" \
  -o "$TMPDIR/hagezi-pro.txt" 2>/dev/null || echo "  (Hagezi fetch failed)"

# Fetch OISD basic
echo "Fetching OISD basic..."
curl -sL "https://raw.githubusercontent.com/sjhgvr/oisd/main/domains_basic.txt" \
  -o "$TMPDIR/oisd.txt" 2>/dev/null || echo "  (OISD fetch failed)"

# Build adblock.txt - AdBlock format
echo "Building adblock.txt..."
{
  echo "# Generated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# AdBlock format for Technitium adblockListUrls"
  echo ""
  
  # Peacock/streaming specific (from known sources)
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
EOF

  # Extract ||domain^ lines from downloaded sources
  if [[ -f "$TMPDIR/hagezi-pro.txt" ]]; then
    grep -E '^\|\|[^|]+\^' "$TMPDIR/hagezi-pro.txt" | head -500 || true
  fi
  if [[ -f "$TMPDIR/oisd.txt" ]]; then
    grep -E '^\|\|[^|]+\^' "$TMPDIR/oisd.txt" | head -500 || true
  fi
} | sort -u > adblock.txt.new && mv adblock.txt.new adblock.txt

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
} | sort -u > regex.txt.new && mv regex.txt.new regex.txt

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

  # Extract plain domains from Hagezi/OISD (strip 0.0.0.0 prefix if present)
  if [[ -f "$TMPDIR/hagezi-pro.txt" ]]; then
    grep -E '^0\.0\.0\.0\s+' "$TMPDIR/hagezi-pro.txt" | awk '{print $2}' | head -1000 || true
    grep -E '^\|\|[^|]+\^' "$TMPDIR/hagezi-pro.txt" | sed -E 's/\|\|([^|]+)\^/\1/' | head -1000 || true
  fi
  if [[ -f "$TMPDIR/oisd.txt" ]]; then
    grep -v '^#' "$TMPDIR/oisd.txt" | head -2000 || true
  fi
} | sort -u > hosts.txt.new && mv hosts.txt.new hosts.txt

echo "=== Done ==="
echo "Files updated:"
wc -l adblock.txt regex.txt hosts.txt