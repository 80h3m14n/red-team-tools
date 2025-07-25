import requests
import threading
import time
import dns.resolver
import json
import os
from datetime import datetime
from plyer import notification
from urllib.parse import urlparse

os.makedirs("logs", exist_ok=True)
LOG_FILE = os.path.join(os.getcwd(), "logs", "takeover_alerts.log")

VULNERABLE_SERVICES = {
    "github.io": "There isn't a GitHub Pages site here.",
    "herokuapp.com": "No such app",
    "cloudfront.net": "ERROR: The request could not be satisfied",
    "bitbucket.io": "Repository not found",
    "wordpress.com": "Do you want to register",
    "shopify.com": "Sorry, this shop is currently unavailable",
    "readthedocs.io": "Unknown Domain",
    "fastly.net": "Fastly error: unknown domain",
    "pantheon.io": "404 error unknown site",
    "helpjuice.com": "We could not find what you're looking for",
    "zendesk.com": "Help Center Closed",
    "statuspage.io": "There is no status page setup",
    "surge.sh": "project not found",
    "intercom.io": "Uh oh. That page doesn't exist",
    "surge.sh": "project not found",
    "zendesk.com": "Help Center Closed",
    "readthedocs.io": "Page not found",
    "unbouncepages.com": "The requested URL was not found on this server",
    "cargo.site": "404 Not Found",
    "launchrock.com": "It looks like you may have taken a wrong turn",
    "azurewebsites.net": "404 Web Site not found",
    "aws.amazon.com/s3": "NoSuchBucket",
    "s3.amazonaws.com": "NoSuchBucket",
    "domains.tumblr.com": "There's nothing here.",
    "desk.com": "Please check your desk.com subdomain",
    "ghost.io": "The thing you were looking for is no longer here",
    "cargocollective.com": "Non-Existent Domain",
    "simplebooklet.com": "We couldn't find this booklet",
    "user.github.io": "There isn't a GitHub Pages site here.",
    "flywheel.net": "404 error unknown site",
    "helpjuice.com": "We could not find what you're looking for",
    "teamwork.com": "Oops - (404)",
    "wordpress.com": "Do you want to register",
    "readme.io": "Project doesnt exist... yet!",
    "readthedocs.org": "Unknown Domain",
    "readthedocs.com": "Unknown Domain",
    "smugmug.com": "Page Not Found",
    "statuspage.io": "There is no status page setup",
    "surge.sh": "project not found",
    "uservoice.com": "This UserVoice subdomain is currently available!",
    "wishpond.com": "404 Not Found",
    "worksites.net": "This site is not published",
    "zendesk.com": "Help Center Closed",
    "pantheonsite.io": "404 error unknown site",
    "fastly.net": "Fastly error: unknown domain",
    "bitbucket.io": "Repository not found",
    "campaignmonitor.com": "Trying to access your account?",
    "instapage.com": "The requested URL was not found on this server",
    "unbouncepages.com": "The requested URL was not found on this server",
    "webflow.io": "The page you are looking for doesn't exist",
    "wistia.com": "Unknown domain",
    "intercom.io": "Uh oh. That page doesn't exist",
    "helpjuice.com": "We could not find what you're looking for",
    "launchrock.com": "It looks like you may have taken a wrong turn",
    "cargocollective.com": "Non-Existent Domain",
    "simplebooklet.com": "We couldn't find this booklet",

}


def log_alert(message):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"[{timestamp}] {message}\n"

    with open(LOG_FILE, "a") as f:
        f.write(log_entry)

    print(log_entry)

    try:
        if hasattr(notification, "notify") and callable(notification.notify):
            notification.notify(
                title="Subdomain Takeover Alert",
                message=message,
                timeout=10
            )
        else:
            print("Notification backend not available.")
    except Exception as e:
        print(f"Notification error: {e}")


# Multiple subdomain sources(crt.sh + HackerTarget).

def get_subdomains(domain):
    subdomains = set()

    # crt.sh
    try:
        url = f"https://crt.sh/?q=%25.{domain}&output=json"
        headers = {"User-Agent": "Mozilla/5.0"}
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code == 200:
            try:
                entries = json.loads(response.text)
            except json.JSONDecodeError as e:
                log_alert(f"crt.sh JSON decode error: {e}")
                entries = []
            for entry in entries:
                name_value = entry.get("name_value", "")
                for sub in name_value.split("\n"):
                    sub = sub.strip().lower()
                    # Only add valid subdomains
                    if domain in sub and sub and "." in sub:
                        subdomains.add(sub)
            # Optional: log count
            log_alert(f"crt.sh: Found {len(subdomains)} subdomains so far.")
    except Exception as e:
        log_alert(f"crt.sh error: {e}")

    # hackertarget
    try:
        url = f"https://api.hackertarget.com/hostsearch/?q={domain}"
        r = requests.get(url, timeout=10)
        if r.status_code == 200 and "error" not in r.text:
            for line in r.text.strip().split("\n"):
                sub = line.split(",")[0]
                if domain in sub:
                    subdomains.add(sub.strip())
    except Exception as e:
        log_alert(f"HackerTarget error: {e}")

    return list(subdomains)


def get_cname(subdomain):
    try:
        answers = dns.resolver.resolve(subdomain, 'CNAME')
        for rdata in answers:
            return str(rdata).rstrip('.')
    except Exception:
        return None


def is_vulnerable_service(cname):
    if cname:
        for service, fingerprint in VULNERABLE_SERVICES.items():
            if service in cname:
                return True
    return False


def is_unclaimed(subdomain, expected_fingerprint):
    try:
        response = requests.get(f"http://{subdomain}", timeout=5)
        if expected_fingerprint in response.text:
            return True
    except Exception:
        pass
    return False


def scan_domain(domain):
    subdomains = get_subdomains(domain)
    log_alert(f"Scanning {len(subdomains)} subdomains for {domain}...")

    for sub in subdomains:
        cname = get_cname(sub)
        if not is_vulnerable_service(cname):
            continue

        for service, fingerprint in VULNERABLE_SERVICES.items():
            if cname and service in cname and is_unclaimed(sub, fingerprint):
                log_alert(
                    f"[!] Possible subdomain takeover on: {sub} → {cname}")
                break


def monitor_loop(domain, interval=3600):
    while True:
        scan_domain(domain)
        time.sleep(interval)


def print_banner():
    banner = r"""
   ____        _     _           _                        _                             
  / ___| _   _| |__ | | ___  ___| |_ _ __ ___   ___ _ __ | |_ ___ _ __                  
  \___ \| | | | '_ \| |/ _ \/ __| __| '_ ` _ \ / _ \ '_ \| __/ _ \ '__|                 
   ___) | |_| | |_) | |  __/ (__| |_| | | | | |  __/ | | | ||  __/ |                    
  |____/ \__,_|_.__/|_|\___|\___|\__|_| |_| |_|\___|_| |_|\__\___|_|                    
                                                                                        
    Subdomain Takeover Scanner
    - Finds subdomains and checks for takeover vulnerabilities.
    - Subdomain sources crt.sh + HackerTarget
    """
    print(banner)

# domain parsing from full URLs.


if __name__ == '__main__':
    print_banner()
    raw_input = input("Enter domain URL (e.g., https://example.com): ").strip()
    parsed_url = urlparse(raw_input)
    target_domain = parsed_url.netloc or parsed_url.path
    if target_domain.startswith("www."):
        target_domain = target_domain[4:]

    thread = threading.Thread(
        target=monitor_loop, args=(target_domain,), daemon=True)
    thread.start()

    try:
        while True:
            time.sleep(10)
    except KeyboardInterrupt:
        log_alert("Scan terminated by user.")
