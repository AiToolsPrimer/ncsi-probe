# ncsi-probe

Send the same connectivity probe Windows uses before it shows "No internet", from any machine with bash and curl, and see **how** it fails.

Microsoft documents the Network Connectivity Status Indicator (NCSI) active probe: an HTTP GET to

```
http://www.msftconnecttest.com/connecttest.txt
```

answered by a body containing `Microsoft Connect Test`. Windows sends an IPv4 and an IPv6 probe in parallel; if either succeeds, it reports internet connectivity. Anything else (a timeout, a redirect from a captive portal, a 403 from a proxy, a login page served with a 200) and the icon changes to "No internet".

`ncsi-probe.sh` sends both probes and reports, for each one:

- **OK**: HTTP status and the expected body
- **redirected**: a captive portal (hotel, café, airport, train Wi-Fi) answered instead
- **refused (403)**: a proxy or filter blocked the probe
- **wrong reply**: something answered, but not with the expected body
- **no reply**: no route, DNS failure or timeout

## Usage

```bash
curl -O https://raw.githubusercontent.com/AiToolsPrimer/ncsi-probe/main/ncsi-probe.sh
chmod +x ncsi-probe.sh
./ncsi-probe.sh
```

Example on a network without IPv6:

```
IPv4: OK, HTTP 200 and the expected body
IPv6: no reply (no route, DNS failure or timeout)
Verdict: internet (at least one probe got the expected reply)
```

Exit code is 0 when at least one probe passes, 1 when both fail (as Windows would report "local only").

## What it does not do

- It does not reproduce NCSI's **passive** probe, which watches incoming traffic and counts network hops (Microsoft's default threshold is 8, checked every 15 seconds).
- It does not change any system setting. Microsoft advises against disabling the active probe as a workaround, because passive polling alone cannot detect every kind of failure.

## Sources

- Microsoft: NCSI overview and NCSI frequently asked questions (Windows Server documentation)
- Microsoft Support: Fix Wi-Fi connection issues in Windows
- Explained in plain English: [Connected without internet, and the test behind the words](https://aitoolsprimer.com/software-connected-without-internet.html) (AI Tools Primer)

## License

MIT
