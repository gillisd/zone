### All numerical inputs that gnu date accepts should be processable by zone

#### these are not picked up

```bash
date -d '20251121'
```


```bash
cat <<EOF | zone
id created_at expires_at valid
645164de584e8b007b325d9c6f1ed04b 2025-11-15 03:54:41 PM EST 2025-04-01 04:08:00 PM EST true
d46885c3239f0ff66e2ba57a30ae659b 2025-11-15 03:54:43 PM EST 2025-04-01 04:10:23 PM EST true
26eec6fddc5648b56118586f86414f82 2025-11-15 03:54:43 PM EST 2025-04-03 04:30:41 PM EST true
cbf9d4f6af642b89a6f3b8f82d5a0ab6 2025-11-15 03:54:43 PM EST 2025-04-05 06:04:22 PM EST true
EOF
#########

id created_at expires_at valid
646164de584e8b007b325d9c6f1ed04b Nov 15, 2025 -  3:54 AM EST PM EST Apr 01, 2025 -  4:08 AM EDT PM EST true
d46885c3439f0ff66e2ba57a30ae659b Nov 15, 2025 -  3:54 AM EST PM EST Apr 01, 2025 -  4:10 AM EDT PM EST true
26eec6fddc5648b56118586f86414f82 Nov 15, 2025 -  3:54 AM EST PM EST Apr 03, 2025 -  4:30 AM EDT PM EST true
cbf9d4f6af642b88a6f3b8f82d5a0ab6 Nov 15, 2025 -  3:54 AM EST PM EST Apr 05, 2025 -  6:04 AM EDT PM EST true

```

Null and ascii separators not working

```bash
❯ {
  openssl rand -base64 16
  date -d '2 hours ago'
} | tr '\n' '\0' | zslurp
print ${REPLY} | zone -d '\0' --field 2
print ${REPLY} | zone -d "\0" --field 2
print ${REPLY} | zone -d $'\x00' --field 2

####
FH7LGIEYnayOWNdCcD7Utg==Sat Nov 22 20:35:00 EST 2025
⚠ Field '2' not found or out of bounds in line: FH7LGIEYnayOWNdCcD7Utg==Sat Nov 22 20:35:00 EST 2025
FH7LGIEYnayOWNdCcD7Utg==Sat Nov 22 20:35:00 EST 2025
⚠ Field '2' not found or out of bounds in line: FH7LGIEYnayOWNdCcD7Utg==Sat Nov 22 20:35:00 EST 2025
Error: --field requires --delimiter
Example: zone --field 2 --delimiter ','
```

