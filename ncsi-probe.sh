#!/usr/bin/env bash
# ncsi-probe.sh - ask the same question Windows asks before it shows "No internet".
#
# Microsoft documents the Network Connectivity Status Indicator (NCSI) active probe:
# an HTTP GET to http://www.msftconnecttest.com/connecttest.txt, answered by a body
# containing "Microsoft Connect Test". Windows sends an IPv4 and an IPv6 probe in
# parallel; if either succeeds, it reports internet connectivity.
#
# This script sends both probes with curl and says, for each one, how it failed:
# no reply at all, or a reply that was not the expected one (a redirect from a
# captive portal, a 403 from a proxy, a login page with a 200).
#
# Usage: ./ncsi-probe.sh        Needs: bash, curl.
# Source: https://aitoolsprimer.com/software-connected-without-internet.html

set -u
URL="http://www.msftconnecttest.com/connecttest.txt"
EXPECT="Microsoft Connect Test"

probe() {
  local fam="$1" tmp meta code redirect
  tmp=$(mktemp)
  if ! meta=$(curl "-$fam" --silent --max-time 5 --output "$tmp" \
                   --write-out '%{http_code} %{redirect_url}' "$URL" 2>/dev/null); then
    echo "IPv$fam: no reply (no route, DNS failure or timeout)"
    rm -f "$tmp"; return 1
  fi
  code=${meta%% *}; redirect=${meta#* }
  if grep -q "$EXPECT" "$tmp"; then
    echo "IPv$fam: OK, HTTP $code and the expected body"
    rm -f "$tmp"; return 0
  fi
  if [ -n "$redirect" ]; then
    echo "IPv$fam: redirected (HTTP $code) to $redirect - looks like a sign-in page"
  elif [ "$code" = "403" ]; then
    echo "IPv$fam: refused (HTTP 403) - a proxy or filter blocked the probe"
  else
    echo "IPv$fam: wrong reply (HTTP $code, body does not contain \"$EXPECT\")"
  fi
  rm -f "$tmp"; return 1
}

ok=0
probe 4 && ok=1
probe 6 && ok=1

if [ "$ok" -eq 1 ]; then
  echo "Verdict: internet (at least one probe got the expected reply)"
else
  echo "Verdict: local only (both probes failed, as Windows would report it)"
  exit 1
fi
