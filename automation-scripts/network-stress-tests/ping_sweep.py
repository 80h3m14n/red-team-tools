# pip install ipaddress ping3
# python ping_sweep.py

import ipaddress
import subprocess

def ping_sweep(subnet):
    network = ipaddress.ip_network(subnet)
    print(f"Scanning {subnet}...")
    for ip in network.hosts():
        if subprocess.call(['ping', '-c', '1', str(ip)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0:
            print(f"{ip} is up")

# Example
ping_sweep("192.168.1.0/24")