# doh-list

Aggregated lists of public DNS-over-HTTPS (DoH) servers, suitable for use in ad-blocking filters (e.g., AdBlock Plus, uBlock Origin) or firewall rules.

## update.sh

[`update.sh`](update.sh) fetches and compiles DoH server data from two sources:

- **curl's wiki** – The [DNS-over-HTTPS](https://github.com/curl/curl/wiki/DNS-over-HTTPS) markdown page maintained by the curl project.
- **AdGuard DNS** – The [DNS providers](https://adguard-dns.io/kb/general/dns-providers/) table from AdGuard's knowledge base.

It then extracts full URLs, domain names, and resolves each domain to its IPv4 and IPv6 addresses (using `dig`), and writes four output files.

### Output Files

| File | Contents |
|---|---|
| [`doh-list.txt`](doh-list.txt) | Full HTTPS URLs of all discovered DoH endpoints |
| [`doh-servers.list`](doh-servers.list) | Domain names only (no protocol/path) |
| [`doh-ipv4.list`](doh-ipv4.list) | Resolved IPv4 addresses of the DoH domains |
| [`doh-ipv6.list`](doh-ipv6.list) | Resolved IPv6 addresses of the DoH domains |

All files use a `!`-prefixed header format (compatible with AdBlock-style filter lists) and are sorted with duplicates removed. The script is meant to be run periodically to keep the lists current.

### Requirements

- `bash`
- `curl`
- `dig` (from `dnsutils` / `bind-utils`) – optional; IP resolution is skipped if `dig` is not available.
