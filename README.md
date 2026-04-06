# Fluffy Paws Vulnerable Lab

A vulnerable web application demonstrating a full attack chain:

File Upload → Webshell → RCE → Credential Exposure → Privilege Escalation

---

## Overview

This lab simulates a real-world vulnerable web application running on Ubuntu.

The application allows file uploads which leads to remote code execution and full system compromise.

---

## Project Structure

```
fluffy-paws-vuln-lab/
│
├── app/
│   ├── index.php
│   ├── config.php
│   ├── css/
│   ├── images/
│   └── uploads/
│
├── docs/
│   └── commands_list.md
│
├── setup.sh
├── README.md
└── .gitattributes
```

---

## Setup

Clone the repository and run:

```
sudo bash setup.sh
```

After setup, the lab will be available at:

```
http://lab.local
```

---

## Attack Flow

1. Upload malicious PHP file
2. Execute commands via webshell
3. Get reverse shell
4. Read config file
5. Switch user (dev)
6. Escalate privileges to root

---

## Important Path

```
/var/www/html/file-upload-rce-lab/
```

Config file:

```
/var/www/html/file-upload-rce-lab/config.php
```

---

## Credentials

```
dev / SuperSecret123
```

---

## Notes

* Upload directory is writable
* PHP execution is enabled
* Sudo is misconfigured

---

## Disclaimer

This lab is created for educational purposes only.

Do not use these techniques without permission.

