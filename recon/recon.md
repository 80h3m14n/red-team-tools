# Reconnaissance

Reconnaissance in red teaming is the foundational phase where ethical hackers gather intelligence about a target organization to identify vulnerabilities and plan realistic attack simulations.


## Packet capture (Pcap) analysis

Extract printable strings from the pcap and grep for likely secrets

```bash
strings capture.pcap \
  | egrep -i 'password|passwd|username|user|authorization|bearer|token|session|cookie|api[_-]?key|secret|key|auth' \
  | sed -n '1,200p'
```

Follow TCP streams and search each stream for cleartext creds

```bash
# list stream ids for TCP
tshark -r capture.pcap -q -z conv,tcp | sed -n '4,$p' \
  | awk '{print $1":"$2":"$3}' | sed '/^$/d' \

# Then for a specific stream (e.g. 10):
tshark -r capture.pcap -q -z "follow,tcp,ascii,10" >/tmp/stream10.txt
grep -Ei 'password|pass|user|login|authorization|bearer|token|cookie|api_key|secret' /tmp/stream10.txt -n
```


---

"Happy hacking"



