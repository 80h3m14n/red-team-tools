#!/usr/bin/env bash
# Run as root for best results.
set -e

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'
ok(){ printf "${GREEN}✅ %s${NC}\n" "$1"; }
warn(){ printf "${YELLOW}⚠️ %s${NC}\n" "$1"; }
bad(){ printf "${RED}❌ %s${NC}\n" "$1"; }

echo "=== VM & Honeypot Detection (bash) ==="

# 1) DMI / BIOS / product strings
if command -v dmidecode >/dev/null 2>&1; then
  echo -e "\n[+] DMI / system info:"
  sudo dmidecode -t system 2>/dev/null | egrep "Manufacturer|Product Name" || true
  if sudo dmidecode -t system 2>/dev/null | egrep -qi "VMware|VirtualBox|KVM|QEMU|Xen|Microsoft"; then
    warn "DMI strings indicate virtualization vendor."
  else
    ok "No obvious virtualization vendor strings in DMI."
  fi
else
  warn "dmidecode not available (install for deeper checks)."
fi

# 2) Loaded modules / processes
echo -e "\n[+] Kernel modules / processes:"
if lsmod | egrep -i 'vbox|vmw|kvm|vmmouse|vboxguest|hv_vmbus' >/dev/null 2>&1; then
  warn "Virtualization kernel modules present."
else
  ok "No obvious VM kernel modules found."
fi

susp_proc_regex="procmon|procmon64|sysmon|wireshark|dumpcap|cuckoo|sandbox|malware"
for p in $(ps -e -o comm=); do
  if echo "$p" | egrep -qi "$susp_proc_regex"; then
    warn "Suspicious process running: $p"
  fi
done

# 3) MAC OUI checks
echo -e "\n[+] MAC OUI checks:"
if command -v ip >/dev/null 2>&1; then
  ip link | egrep -o '([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}' | while read mac; do
    prefix=$(echo $mac | cut -d: -f1-3)
    case "$prefix" in
      00:05:69|00:0C:29|00:50:56|08:00:27|52:54:00|00:1C:42)
        warn "Suspicious MAC OUI: $mac";;
      *)
        : ;;
    esac
  done
else
  warn "ip command not found for MAC check."
fi

# 4) Network outbound / DNS test
echo -e "\n[+] Network outbound / DNS tests:"
curl_opts="--max-time 3 --silent --head"
if curl $curl_opts https://example.com >/dev/null 2>&1; then
  ok "Outbound HTTPS to example.com works."
else
  warn "Outbound HTTPS blocked or intercepted."
fi

# DNS check: resolve known domain and compare
if command -v dig >/dev/null 2>&1; then
  ips=$(dig +short example.com A | tr '\n' ' ')
  if [ -z "$ips" ]; then
    warn "DNS resolution for example.com failed or is intercepted."
  else
    ok "DNS example.com -> $ips"
  fi
else
  warn "dig not installed; skipping advanced DNS checks."
fi

# 5) Filesystem / user realism
echo -e "\n[+] User & filesystem realism checks:"
users=$(ls /home 2>/dev/null || true)
if [ -z "$users" ]; then
  warn "No regular user dirs in /home or they're empty."
else
  for u in $users; do
    cnt=$(find /home/"$u"/Downloads -maxdepth 2 2>/dev/null | wc -l || true)
    if [ "$cnt" -le 1 ]; then
      warn "User $u has empty-ish Downloads ($cnt entries)."
    else
      ok "User $u Downloads items: $cnt"
    fi
  done
fi

# Look for 'analysis' folders near root (fast)
trap_dirs=$(find / -maxdepth 3 -type d -regextype posix-extended -regex '.*(sample|malware|analysis|sandbox|quarantine).*' 2>/dev/null | head -n 5 || true)
if [ -n "$trap_dirs" ]; then
  warn "Potential analysis dirs found: $trap_dirs"
else
  ok "No obvious analysis-labeled directories (fast scan)."
fi

# 6) Timing / mouse/keyboard / human activity heuristics
echo -e "\n[+] Timing & activity checks:"
if [ -r /proc/uptime ]; then
  upsecs=$(awk '{print int($1)}' /proc/uptime)
  uphrs=$((upsecs/3600))
  echo "Uptime (hours): $uphrs"
  if [ "$uphrs" -lt 1 ]; then
    warn "System booted less than 1 hour ago."
  else
    ok "System uptime > 1h."
  fi
fi

# Check X11/wayland idle if possible (fast heuristic)
if command -v xprintidle >/dev/null 2>&1; then
  idle_ms=$(xprintidle)
  idle_min=$((idle_ms/60000))
  echo "Idle minutes (X): $idle_min"
  if [ "$idle_min" -gt 120 ]; then
    warn "No GUI interaction for >2h."
  else
    ok "Recent GUI interaction detected."
  fi
else
  warn "xprintidle not found; skipping GUI idle check."
fi

# 7) Security tooling / logging agents
echo -e "\n[+] Monitoring / logging checks (quick)..."
for tool in sysmon osquery wireshark tcpdump falcon cbcloud ossec carbonblack; do
  if pgrep -x "$tool" >/dev/null 2>&1; then
    warn "Monitoring process detected: $tool"
  fi
done

# 8) Heuristic score
echo -e "\n=== Quick verdict ==="
# Simple scoring: count WARN lines from this run (cheap heuristic)
warncount=$(printf "%s\n" "$(history 2>/dev/null)" | wc -l) # placeholder; can't easily parse previous messages
# Instead, give human readable summary
echo "This script ran a collection of heuristics: DMI strings, modules, MAC OUIs, outbound connectivity, DNS, user folders, uptime, idle, and monitoring processes."
echo -e "${YELLOW}Interpret results: multiple WARNs => increased chance of honeypot/sandbox. No WARNs != safe.${NC}"

echo " "
echo -e "\e[31mThese are heuristics, not proof.\e[0m"
warn "Honeypots intentionally hide or fake everything, and advanced sandboxes will spoof user files, drivers, network, and even synthetic mouse/typing patterns."


echo -e "\nScan complete."
