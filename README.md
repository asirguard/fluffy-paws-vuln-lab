# Fluffy Paws — Vulnerable Lab v1.1.0

> WARNING: This project is intentionally vulnerable. For educational purposes only.
> Never deploy to a public server. Practice only in a controlled local environment.

A full-stack pentesting lab simulating a real-world cat photo sharing platform.
Combines a vulnerable REST API (Node.js) and a vulnerable PHP web application running on the same Ubuntu Server target.

---

## Watch the Lesson / Follow

This lab is the hands-on environment for the AsirGuard API pentesting series.

- Video lesson on this lab (English): https://www.youtube.com/@ASIRGUARD-lab
- Video lesson on this lab (Russian): https://www.youtube.com/@ASIRGUARD
- Patreon (Russian): https://www.patreon.com/c/ASIRGUARD
- Telegram (Russian): https://t.me/AsirGuard

---

## Project Structure

```
fluffy-paws-vuln-lab/
|
|- api/                        <- Vulnerable REST API (Node.js + Express + FerretDB)
|   |- app.js                  <- Entry point, DB connect, routes
|   |- package.json
|   +- src/
|       |- controllers/
|       |   +- auth.controller.js
|       |- middleware/
|       |   +- auth.middleware.js
|       |- models/
|       |   +- user.model.js
|       +- routes/
|           +- auth.routes.js
|
|- web/                        <- Vulnerable PHP Web Application
|   |- index.php
|   |- config.php
|   |- css/
|   |   +- style.css
|   +- uploads/
|
|- CLAUDE_CONTEXT.md           <- Claude session context (git-ignored, never committed)
|- setup.sh                    <- Ubuntu Server one-click installer
|- uninstall.sh                <- Ubuntu Server one-click uninstaller
+- README.md                   <- This file
```

---

## Quick Start (Ubuntu Server)

```bash
git clone https://github.com/asirguard/fluffy-paws-vuln-lab.git
cd fluffy-paws-vuln-lab
sudo bash setup.sh
```

Type YES when prompted. The installer handles everything.

---

## How setup.sh Works

The installer runs ten sequential stages:

**[1] Security warning** — displays a list of vulnerabilities deployed and requires typing YES to proceed. Aborts cleanly on anything else.

**[2] Preflight checks** — verifies root, Ubuntu OS, free ports 80 and 3000, repo structure (web/ and api/ directories present), and internet connectivity via curl to nodesource and archive.ubuntu.com.

**[3] System dependencies** — installs Apache, PHP, libapache2-mod-php, curl, gnupg, ca-certificates via apt.

**[4] Node.js 20** — checks if Node.js >= 20 is already present, skips if so. Otherwise adds the NodeSource apt repository and installs.

**[5] FerretDB v1.24** — MongoDB-compatible database with SQLite backend. Used instead of MongoDB because it requires no AVX CPU instructions and works on VirtualBox without CPU passthrough. Downloads the .deb package from GitHub Releases, installs it, creates /var/lib/ferretdb as data directory, registers and starts a systemd service (ferretdb.service) listening on 127.0.0.1:27017.

**[6] Web Lab** — copies web/ to /var/www/html/fluffy-paws, sets permissions (uploads/ is chmod 777 — intentional vulnerability), writes an Apache VirtualHost config for lab.local, adds lab.local to /etc/hosts, enables the site, disables the default site, enables mod_rewrite, restarts Apache.

**[7] API Lab** — copies api/ to /opt/fluffy-paws-api, runs npm install, seeds FerretDB with two users (alice and john) via an inline Node.js script, registers and starts a systemd service (fluffy-paws-api.service) running as www-data.

**[8] Linux user** — creates user dev with password SuperSecret123, writes a sudoers rule granting passwordless sudo access to /usr/bin/find only. This is the intentional misconfiguration for the privilege escalation chain.

**[9] Static IP** — detects interface enp0s8 (Host-Only adapter, Adapter 2 in VirtualBox). If present, writes /etc/netplan/99-lab-static.yaml with IP 192.168.56.20/24 and no gateway, then applies with netplan apply. If enp0s8 is not found, prints a warning and skips — lab still works via DHCP on Adapter 1.

**[10] Smoke tests + summary** — curls http://127.0.0.1:80 and http://127.0.0.1:3000/api/ping, prints status for both. Then prints the full summary: lab version, address, isolation instructions, credentials, and quick verification commands.

### Network architecture

Two VirtualBox adapters are required before running setup.sh:

- Adapter 1 - NAT - provides internet during install (apt, npm, FerretDB download). Disable in VirtualBox settings after setup to isolate the lab.
- Adapter 2 - Host-Only - setup.sh assigns static IP 192.168.56.20 via netplan on enp0s8. Lab is always reachable at this address from both Windows host and Kali.

IMPORTANT: never add a gateway to the Host-Only netplan config. Doing so overrides the NAT default route and breaks internet access on Adapter 1.

---

## Uninstall

```bash
sudo bash uninstall.sh
```

Type YES when prompted. Removes all services, files, the database, the dev user, the sudoers rule, and the Apache VirtualHost. Optionally removes packages and reverts netplan to DHCP.

---

## API

**Stack:** Node.js + Express + FerretDB (MongoDB-compatible, SQLite backend, no AVX required)
**Base URL after deploy:** http://192.168.56.20:3000/api

| Route | Method | Description |
|---|---|---|
| /api/ping | GET | Health check |
| /api/auth/register | POST | Registration |
| /api/auth/login | POST | Login |
| /api/users/:id | GET | User profile (requires JWT) |

## Web

**Stack:** PHP + Apache
**URL after deploy:** http://192.168.56.20

---

## Implemented Vulnerabilities

### API Vulnerabilities

**Mass Assignment (#4) — OWASP API6:2023**
Location: api/src/controllers/auth.controller.js -> register()
The register endpoint creates a new user with `{ ...req.body }` — all fields from the request body are spread directly into the document without filtering. An attacker can include `"role": "admin"` in the registration request and create an admin account.

**Excessive Data Exposure (#9) — OWASP API3:2023**
Location: api/src/controllers/auth.controller.js -> getUser()
The getUser endpoint returns the full MongoDB document without using .select() to restrict fields. The response includes password_hash and, as of v1.1.0, the plaintext password as well. Any authenticated user can retrieve credentials for any account on the platform.

**BOLA / IDOR via path (#1) — OWASP API1:2023**
Location: api/src/controllers/auth.controller.js -> getUser()
The getUser endpoint accepts a user ID in the path (`GET /api/users/:id`) and performs no ownership check. Any authenticated user can request any other user's profile by iterating IDs, including the admin account.

**NoSQL Injection (#12) — OWASP API8:2023**
Location: api/src/controllers/auth.controller.js -> login()
The login endpoint passes both the username and the password straight into MongoDB findOne() with no type checking: `User.findOne({ username, password })`. A normal login sends two strings and matches a single user. An attacker sends MongoDB operators instead of strings and bypasses authentication entirely:
- `{"username": {"$ne": null}, "password": {"$ne": null}}` matches the first user in the collection and logs in as that user (alice) with no valid credentials.
- `{"username": "john", "password": {"$ne": null}}` logs in as the admin account john without knowing the password.
A plaintext password is stored on each user (alongside password_hash) so the in-query comparison works for legitimate logins while remaining injectable.

**JWT Attacks (#7) — OWASP API2:2023**
Location: api/src/middleware/auth.middleware.js
Two weaknesses in one middleware:
- The JWT secret is hardcoded as `fluffy123` — brute-forceable offline after capturing any token.
- The middleware checks if `alg === "none"` and skips signature verification entirely if true. An attacker can forge a valid-looking JWT with algorithm set to none, sign it with an empty signature, and authenticate as any user including admin.

### Web Vulnerabilities

**Unrestricted File Upload -> Webshell -> RCE**
Location: web/index.php + web/uploads/
The upload form accepts any file type with no server-side validation. The uploads/ directory has execute permissions for PHP enabled via Apache config. An attacker uploads a PHP webshell, accesses it at /uploads/shell.php, and achieves Remote Code Execution on the server.

**Hardcoded Credentials**
Location: web/config.php
The config file contains plaintext credentials for the dev user: `dev / SuperSecret123`. These are readable via RCE (cat /var/www/html/fluffy-paws/config.php) or directly from the source if the attacker gains file read access.

**Sudo Misconfiguration -> Privilege Escalation**
Location: /etc/sudoers.d/dev-lab (written by setup.sh)
The dev user has passwordless sudo access to /usr/bin/find. The find binary supports -exec, which allows arbitrary command execution as root: `sudo find / -name x -exec /bin/bash \;`

### Full Attack Chain

The web and API components share the same Ubuntu Server and the same linux user dev.
The intended end-to-end chain across both:

```
API: Register with role:admin  ->  Escalate privileges in the application
API: NoSQL Injection           ->  Login bypass, access any account
API: JWT alg:none              ->  Forge admin token, access all API endpoints
API: BOLA                      ->  Extract all user profiles including admin
API: Excessive Data Exposure   ->  Harvest password hashes from profiles

Web: Upload PHP webshell       ->  RCE on the server
Web: RCE -> cat config.php     ->  Get dev credentials (dev / SuperSecret123)
Web: SSH as dev                ->  Shell on the machine
Web: sudo find -exec bash      ->  Root
```

---

## Test Credentials

### API Users (seeded by setup.sh)

| Username | Password | Role |
|---|---|---|
| alice | meow123 | user |
| john | whiskers99 | admin |

### Linux User

| Username | Password | Purpose |
|---|---|---|
| dev | SuperSecret123 | Privilege escalation target — sudo find misconfiguration |

---

## Service Management (Ubuntu Server)

```bash
sudo systemctl status fluffy-paws-api
sudo systemctl restart fluffy-paws-api
sudo journalctl -u fluffy-paws-api -f
sudo systemctl status apache2
sudo systemctl status ferretdb
```

---

## Disclaimer

This lab is created for educational purposes only.
Do not use these techniques without explicit permission.
Practice only on systems you own or have authorization to test.

---

*Version: 1.1.0 — Last updated: 2026-06-22*
