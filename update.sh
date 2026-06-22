#!/usr/bin/env bash

# Define the file path for the DNS-over-HTTPS markdown file
FILE="https://raw.githubusercontent.com/wiki/curl/curl/DNS-over-HTTPS.md"

# Initialize FULL_URLS_FILE as an empty string
FULL_URLS_FILE=""

# Check if the file exists and is readable
if [ -r "$FILE" ]; then
	# Extract full URLs from the "Base URL" column of the table in the markdown file
	FULL_URLS_FILE=$(awk '
		BEGIN { capture = 0; }
		/^# Publicly available servers/ { capture = 1; }
		/^# Private DNS Server with DoH setup examples/ { capture = 0; exit; }
		capture && /^\|/ {
			split($0, columns, "|");
			print columns[3];
		}
	' "$FILE" | grep -oP 'https://[a-zA-Z0-9./?=_%:-]+')
else
	echo "Warning: File $FILE not found or not readable. Proceeding with AdGuard data only."
fi

# Get the current date for the "Last modified" entry
CURRENT_DATE=$(date +"%Y-%m-%d %H:%M:%S")

# Fetch AdGuard DNS providers page content
ADGUARD_PAGE_CONTENT=$(curl -s "https://adguard-dns.io/kb/general/dns-providers/")

# Extract DNS-over-HTTPS URLs from the AdGuard page if content is available
FULL_URLS_ADGUARD=""
if [ -n "$ADGUARD_PAGE_CONTENT" ]; then
	FULL_URLS_ADGUARD=$(echo "$ADGUARD_PAGE_CONTENT" |
		awk 'BEGIN { RS = "<tr>"; FS = "<td>"; OFS = "" }
			 /DNS-over-HTTPS/ {
				 for (i = 1; i <= NF; i++) {
					 if ($i ~ /https:\/\/[a-zA-Z0-9./?=_%:-]+/) {
						 match($i, /https:\/\/[a-zA-Z0-9./?=_%:-]+/, arr)
						 print arr[0]
					 }
				 }
			 }' | sort -u)
else
	echo "Warning: Unable to fetch content from AdGuard's DNS providers page. Proceeding with markdown data only."
fi

# Combine URLs from both sources and remove duplicates
FULL_URLS=$(echo -e "$FULL_URLS_FILE\n$FULL_URLS_ADGUARD" | sort -u)

# Ensure FULL_URLS contains only valid HTTPS URLs
FULL_URLS=$(echo "$FULL_URLS" | grep -E '^https://')

# Extract only domains from the URLs and remove duplicates
DOMAINS=$(echo "$FULL_URLS" | awk -F/ '{print $3}' | grep -E '^[a-zA-Z0-9.-]+$' | sort -u)

# Resolve domains to IP addresses
IPV4_LIST=""
IPV6_LIST=""

if command -v dig &>/dev/null && [ -n "$DOMAINS" ]; then
	echo "Resolving IP addresses for $(echo "$DOMAINS" | wc -l) domains..."
	while IFS= read -r domain; do
		[ -z "$domain" ] && continue
		IPV4_RESULT=$(dig A "$domain" +short +timeout=5 +tries=1 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || true)
		[ -n "$IPV4_RESULT" ] && IPV4_LIST=$(printf '%s\n%s' "$IPV4_LIST" "$IPV4_RESULT")

		IPV6_RESULT=$(dig AAAA "$domain" +short +timeout=5 +tries=1 2>/dev/null | grep -E '^[0-9a-fA-F:]+$' || true)
		[ -n "$IPV6_RESULT" ] && IPV6_LIST=$(printf '%s\n%s' "$IPV6_LIST" "$IPV6_RESULT")
	done <<< "$DOMAINS"
elif ! command -v dig &>/dev/null; then
	echo "Warning: dig not found. Skipping IP resolution."
fi

IPV4_LIST=$(echo "$IPV4_LIST" | grep -v '^$' | sort -u)
IPV6_LIST=$(echo "$IPV6_LIST" | grep -v '^$' | sort -u)

# Check if any URLs were extracted
if [ -z "$FULL_URLS" ]; then
	echo "Error: No URLs could be extracted from either source. Exiting without creating lists."
	exit 1
fi

# Generate the doh-list.txt file with the header and full URLs
echo "$FULL_URLS" > doh-list.txt

# Generate the doh-servers.list file with the header and only the domains
echo "$DOMAINS" > doh-servers.txt

# Generate the doh-ipv4.list file with IPv4 addresses
echo "$IPV4_LIST" > doh-ipv4.txt

# Generate the doh-ipv6.list file with IPv6 addresses
echo "$IPV6_LIST" > doh-ipv6.txt
