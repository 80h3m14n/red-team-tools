# AES-encrypted passwords are stored in the logins table of the SQLite database in the Chrome profile directory
# pip install pycryptodome
'''
To debug this script, you can check the Local State file for the encryption key.
cat ~/.config/BraveSoftware/Brave-Browser/Local\\ State

Look for a section like:
"os_crypt": {
    "encrypted_key": "..."
}

'''

import os
from Crypto.Cipher import AES
import platform
import sys
import shutil
import sqlite3
import base64
import json

# check for browser availability on system


def is_browser_installed():
    system = platform.system()
    if system == "Windows":
        chrome_path = os.path.join(os.environ.get(
            "ProgramFiles(x86)", "C:/Program Files (x86)"), "Google/Chrome/Application/chrome.exe")
        brave_path = os.path.join(os.environ.get(
            "ProgramFiles(x86)", "C:/Program Files (x86)"), "BraveSoftware/Brave-Browser/Application/brave.exe")
        return os.path.exists(chrome_path) or os.path.exists(brave_path)
    elif system == "Linux":
        chrome_config = os.path.expanduser("~/.config/google-chrome")
        chromium_config = os.path.expanduser("~/.config/chromium")
        brave_config = os.path.expanduser(
            "~/.config/BraveSoftware/Brave-Browser")
        return os.path.exists(chrome_config) or os.path.exists(chromium_config) or os.path.exists(brave_config)
    else:
        return False


# For windows systems
try:
    import win32crypt
except ImportError:
    win32crypt = None

# Get the encrypted_key value used to encrypt and decrypt sensitive data such as saved passwords within Chrome


def get_encryption_key(username=None, browser="chrome"):
    system = platform.system()
    if system == "Windows":
        if browser == "chrome":
            local_state_path = f"C:/Users/{username}/AppData/Local/Google/Chrome/User Data/Local State"
        elif browser == "brave":
            local_state_path = f"C:/Users/{username}/AppData/Local/BraveSoftware/Brave-Browser/User Data/Local State"
        else:
            raise NotImplementedError(f"Unsupported browser: {browser}")
        with open(local_state_path, "r", encoding="utf-8") as f:
            local_state = f.read()
            local_state = json.loads(local_state)
        if "os_crypt" not in local_state or "encrypted_key" not in local_state["os_crypt"]:
            print(
                f"Error: The Local State file at {local_state_path} does not contain an 'encrypted_key'. This may mean the browser has never saved a password or the profile is new.")
            sys.exit(1)
        key = base64.b64decode(local_state["os_crypt"]["encrypted_key"])
        key = key[5:]
        if win32crypt is None:
            raise ImportError(
                "win32crypt is required on Windows to decrypt Chrome/Brave passwords.")
        return win32crypt.CryptUnprotectData(key, None, None, None, 0)[1]
    elif system == "Linux":
        if browser == "chrome":
            local_state_path = os.path.expanduser(
                "~/.config/google-chrome/Local State")
        elif browser == "brave":
            local_state_path = os.path.expanduser(
                "~/.config/BraveSoftware/Brave-Browser/Local State")
        else:
            raise NotImplementedError(f"Unsupported browser: {browser}")
        with open(local_state_path, "r", encoding="utf-8") as f:
            local_state = f.read()
            local_state = json.loads(local_state)
        if "os_crypt" not in local_state or "encrypted_key" not in local_state["os_crypt"]:
            print(
                f"Error: The Local State file at {local_state_path} does not contain an 'encrypted_key'.\n This may mean the browser has never saved a password \n The browser uses a different encryption method or structure \n or the profile is new.")
            sys.exit(1)
        key = base64.b64decode(local_state["os_crypt"]["encrypted_key"])
        key = key[5:]
        # On Linux, Chrome/Brave uses the system's keyring. This is a placeholder for actual decryption logic.
        return key
    else:
        raise NotImplementedError(f"Unsupported OS: {system}")


def decrypt_password(password, key):
    iv = password[3:15]
    password = password[15:]
    cipher = AES.new(key, AES.MODE_GCM, iv)
    return cipher.decrypt(password)[:-16].decode()


def main():

    system = platform.system()
    if not is_browser_installed():
        print("Error: Google Chrome or Brave is not installed or its profile data was not found on this system.")
        sys.exit(1)

    # Ask user which browser to use if both are present, otherwise auto-detect
    browser = None
    if system == "Windows":
        username = os.getlogin()
        chrome_path = f"C:/Users/{username}/AppData/Local/Google/Chrome/User Data/Default/Login Data"
        brave_path = f"C:/Users/{username}/AppData/Local/BraveSoftware/Brave-Browser/User Data/Default/Login Data"
        if os.path.exists(chrome_path) and os.path.exists(brave_path):
            print(
                "Both Chrome and Brave profiles found. Type 'chrome' or 'brave' to select:")
            browser = input().strip().lower()
            if browser not in ["chrome", "brave"]:
                print("Invalid browser selection.")
                sys.exit(1)
        elif os.path.exists(brave_path):
            browser = "brave"
        else:
            browser = "chrome"
        key = get_encryption_key(username, browser)
        db_path = chrome_path if browser == "chrome" else brave_path
    elif system == "Linux":
        chrome_path = os.path.expanduser(
            "~/.config/google-chrome/Default/Login Data")
        brave_base = os.path.expanduser(
            "~/.config/BraveSoftware/Brave-Browser")
        brave_profiles = []
        # Find all Brave profiles (Default, Profile 1, Profile 2, ...)
        if os.path.exists(brave_base):
            for entry in os.listdir(brave_base):
                profile_path = os.path.join(brave_base, entry, "Login Data")
                if os.path.isfile(profile_path):
                    brave_profiles.append((entry, profile_path))
        # Always check Chrome Default profile as well
        profiles_to_scan = []
        if os.path.exists(chrome_path):
            profiles_to_scan.append(("chrome-Default", chrome_path))
        for profile_name, profile_path in brave_profiles:
            profiles_to_scan.append((f"brave-{profile_name}", profile_path))

        if not profiles_to_scan:
            print("No Chrome or Brave profiles with saved passwords found.")
            sys.exit(1)

        # Use the same Local State for all Brave profiles
        for profile_name, db_path in profiles_to_scan:
            if profile_name.startswith("chrome-"):
                key = get_encryption_key(browser="chrome")
            else:
                key = get_encryption_key(browser="brave")
            print(f"\n===== Passwords for {profile_name} =====")
            filename = f"ChromeData_{profile_name}.db"
            shutil.copyfile(db_path, filename)
            db = sqlite3.connect(filename)
            cursor = db.cursor()
            cursor.execute(
                "select origin_url, username_value, password_value from logins")
            for row in cursor.fetchall():
                origin_url = row[0]
                username_val = row[1]
                try:
                    password = decrypt_password(row[2], key)
                except Exception as e:
                    password = f"[Decryption failed: {e}]"
                if username_val or password:
                    print(f"Origin URL: {origin_url}")
                    print(f"Username: {username_val}")
                    print(f"Password: {password}")
                    print("*********************************************************")
            cursor.close()
            db.close()
            os.remove(filename)
        return
    else:
        raise NotImplementedError(f"Unsupported OS: {system}")

    filename = "ChromeData.db"
    shutil.copyfile(db_path, filename)
    db = sqlite3.connect(filename)
    cursor = db.cursor()
    cursor.execute(
        "select origin_url, username_value, password_value from logins")
    for row in cursor.fetchall():
        origin_url = row[0]
        username_val = row[1]
        try:
            password = decrypt_password(row[2], key)
        except Exception as e:
            password = f"[Decryption failed: {e}]"
        if username_val or password:
            print(f"Origin URL: {origin_url}")
            print(f"Username: {username_val}")
            print(f"Password: {password}")
            print("*********************************************************")
        else:
            continue

    cursor.close()
    db.close()
    os.remove(filename)


if __name__ == "__main__":
    main()
