#!/bin/bash

# =============================================================================
# Fluffy Paws — Vulnerable Lab Installer
# Version: 1.0
# =============================================================================
# This script sets up a full pentesting lab environment on Ubuntu Server.
# Installs: Apache + PHP (Web Lab), Node.js + FerretDB/SQLite (API Lab)
#
# Network setup:
#   Before install — configure two adapters in VirtualBox:
#     Adapter 1: NAT        (internet access for install and updates)
#     Adapter 2: Host-Only  (lab network, static IP 192.168.56.20)
#   Run setup.sh with both adapters active (Adapter 1 provides internet)
#   setup.sh assigns static IP 192.168.56.20 to enp0s8 (Host-Only adapter)
#   Lab is always reachable at 192.168.56.20 from Windows and Kali
#   To isolate: disable Adapter 1 in VirtualBox settings
#   To update:  re-enable Adapter 1
# =============================================================================

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
ok()   { echo -e "  ${GREEN}[OK]${RESET}    $1"; }
skip() { echo -e "  ${CYAN}[SKIP]${RESET}  $1"; }
info() { echo -e "  ${YELLOW}[INFO]${RESET}  $1"; }
fail() { echo -e "  ${RED}[FAIL]${RESET}  $1"; exit 1; }
warn() { echo -e "  ${YELLOW}[WARN]${RESET}  $1"; }
step() { echo -e "\n${BOLD}──────────────────────────────────────────${RESET}"; \
         echo -e "${BOLD} $1${RESET}"; \
         echo -e "${BOLD}──────────────────────────────────────────${RESET}"; }

# ── Config ────────────────────────────────────────────────────────────────────
LAB_VERSION="1.0"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_ROOT="/var/www/html/fluffy-paws"
API_ROOT="/opt/fluffy-paws-api"
DOMAIN="lab.local"
DEV_USER="dev"
DEV_PASS="SuperSecret123"
ALICE_PASS="meow123"
JOHN_PASS="whiskers99"
NODE_MAJOR=20

# =============================================================================
# [1] WARNING
# =============================================================================
clear
echo -e "${RED}"
cat << 'EOF'
 ██╗    ██╗ █████╗ ██████╗ ███╗   ██╗██╗███╗   ██╗ ██████╗
 ██║    ██║██╔══██╗██╔══██╗████╗  ██║██║████╗  ██║██╔════╝
 ██║ █╗ ██║███████║██████╔╝██╔██╗ ██║██║██╔██╗ ██║██║  ███╗
 ██║███╗██║██╔══██║██╔══██╗██║╚██╗██║██║██║╚██╗██║██║   ██║
 ╚███╔███╔╝██║  ██║██║  ██║██║ ╚████║██║██║ ╚████║╚██████╔╝
  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚═════╝
EOF
echo -e "${RESET}"

echo -e "${RED}${BOLD}  ⚠️  SECURITY WARNING — READ BEFORE CONTINUING${RESET}"
echo ""
echo -e "  This installer deploys an ${BOLD}INTENTIONALLY VULNERABLE${RESET} lab environment."
echo -e "  It contains ${RED}real exploitable vulnerabilities${RESET} including:"
echo ""
echo -e "    • Remote Code Execution via unrestricted file upload"
echo -e "    • Hardcoded credentials in source code"
echo -e "    • Privilege escalation via misconfigured sudo"
echo -e "    • Broken authentication (JWT, NoSQL injection)"
echo -e "    • Broken access control (BOLA/IDOR)"
echo ""
echo -e "  ${BOLD}THIS MACHINE MUST NEVER BE EXPOSED TO THE INTERNET.${RESET}"
echo -e "  Run this lab only on an isolated network or local VM."
echo -e "  Exposing this server publicly could lead to full system compromise."
echo ""
echo -e "${YELLOW}  Type ${BOLD}YES${RESET}${YELLOW} to confirm you understand and accept these risks:${RESET}"
echo -n "  > "
read -r CONFIRM

if [ "${CONFIRM^^}" != "YES" ]; then
    echo ""
    echo -e "  ${RED}Aborted. Setup was not run.${RESET}"
    echo ""
    exit 0
fi

# =============================================================================
# [2] PREFLIGHT CHECKS
# =============================================================================
step "Preflight Checks"

# Root check
if [ "$EUID" -ne 0 ]; then
    fail "Please run as root: sudo bash setup.sh"
fi
ok "Running as root"

# OS check
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        fail "This installer requires Ubuntu. Detected: $ID"
    fi
    ok "OS: Ubuntu $VERSION_ID"
else
    fail "Cannot detect OS. /etc/os-release not found."
fi

# Port 80
if ss -tlnp | grep -q ':80 '; then
    info "Port 80 is already in use — Apache may already be running (will reconfigure)"
else
    ok "Port 80 is free"
fi

# Port 3000
if ss -tlnp | grep -q ':3000 '; then
    info "Port 3000 is already in use — API service may already be running (will reconfigure)"
else
    ok "Port 3000 is free"
fi

# Repo structure check
if [ ! -d "$REPO_DIR/web" ]; then
    fail "web directory not found. Make sure you cloned the full repo and run: sudo bash setup.sh from inside fluffy-paws-vuln-lab/"
fi
if [ ! -d "$REPO_DIR/api" ]; then
    fail "api directory not found. Make sure you cloned the full repo and run: sudo bash setup.sh from inside fluffy-paws-vuln-lab/"
fi
ok "Repository structure verified"

# Internet connectivity
info "Checking internet connectivity..."
if ! curl -fsSL --max-time 10 https://deb.nodesource.com > /dev/null 2>&1 && \
   ! curl -fsSL --max-time 10 https://archive.ubuntu.com > /dev/null 2>&1; then
    fail "No internet connectivity. Make sure VirtualBox Adapter is set to NAT."
fi
ok "Internet reachable"

# =============================================================================
# [3] SYSTEM DEPENDENCIES
# =============================================================================
step "Installing System Dependencies"

info "Installing Apache, PHP, curl, gnupg..."
apt-get install -y -qq apache2 php libapache2-mod-php curl gnupg ca-certificates \
    > /dev/null 2>&1
ok "Apache + PHP installed"

# =============================================================================
# [4] NODE.JS
# =============================================================================
step "Installing Node.js $NODE_MAJOR"

NODE_INSTALLED_VERSION=""
if command -v node &>/dev/null; then
    NODE_INSTALLED_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
fi

if [ "$NODE_INSTALLED_VERSION" -ge "$NODE_MAJOR" ] 2>/dev/null; then
    skip "Node.js $(node -v) already installed"
else
    info "Adding NodeSource repository..."
    curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
        > /dev/null 2>&1
    apt-get install -y -qq nodejs > /dev/null 2>&1
    ok "Node.js $(node -v) installed"
fi

# =============================================================================
# [5] DATABASE (FerretDB + SQLite)
# =============================================================================
step "Installing FerretDB (MongoDB-compatible, no AVX required)"

# FerretDB v1.24 — last version with SQLite backend, no AVX, no PostgreSQL needed.
# Pure Go binary, works on VirtualBox without CPU passthrough.
# mongoose / MongoDB driver connects to it via standard mongodb:// URI on port 27017.
FERRETDB_VERSION="1.24.0"
FERRETDB_DATA="/var/lib/ferretdb"

if command -v ferretdb &>/dev/null; then
    skip "FerretDB already installed ($(ferretdb --version 2>&1 | head -1))"
else
    info "Downloading FerretDB v${FERRETDB_VERSION}..."
    curl -fsSL -o /tmp/ferretdb.deb \
        "https://github.com/FerretDB/FerretDB/releases/download/v${FERRETDB_VERSION}/ferretdb-linux-amd64.deb" \
        || fail "Failed to download FerretDB. Check internet connectivity."

    dpkg -i /tmp/ferretdb.deb > /dev/null 2>&1 \
        || fail "Failed to install FerretDB package."
    rm -f /tmp/ferretdb.deb
    ok "FerretDB v${FERRETDB_VERSION} installed"
fi

# Data directory for SQLite
mkdir -p "$FERRETDB_DATA"

# systemd service for FerretDB
info "Configuring FerretDB service..."
cat > /etc/systemd/system/ferretdb.service << EOF
[Unit]
Description=FerretDB (MongoDB-compatible database)
After=network.target remote-fs.target

[Service]
Type=simple
ExecStart=/usr/bin/ferretdb --handler="sqlite" --sqlite-url "file:${FERRETDB_DATA}/"
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ferretdb --quiet
systemctl restart ferretdb
sleep 2

if systemctl is-active --quiet ferretdb; then
    ok "FerretDB is running on 127.0.0.1:27017"
else
    fail "FerretDB failed to start. Check: systemctl status ferretdb"
fi

# =============================================================================
# [6] WEB LAB
# =============================================================================
step "Deploying Web Lab"

info "Copying web app to $WEB_ROOT..."
rm -rf "$WEB_ROOT"
mkdir -p "$WEB_ROOT"
cp -r "$REPO_DIR/web/." "$WEB_ROOT/"
ok "Web files deployed to $WEB_ROOT"

# Permissions
chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"
chmod 777 "$WEB_ROOT/uploads"
ok "Permissions set (uploads dir: 777)"

# Apache VirtualHost
info "Configuring Apache VirtualHost..."
cat > /etc/apache2/sites-available/fluffy-paws.conf << EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    DocumentRoot $WEB_ROOT

    <Directory $WEB_ROOT>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/fluffy-paws-error.log
    CustomLog \${APACHE_LOG_DIR}/fluffy-paws-access.log combined
</VirtualHost>
EOF

a2ensite fluffy-paws.conf > /dev/null 2>&1
a2dissite 000-default.conf > /dev/null 2>&1
a2enmod rewrite > /dev/null 2>&1

# /etc/hosts
if ! grep -q "$DOMAIN" /etc/hosts; then
    echo "127.0.0.1  $DOMAIN" >> /etc/hosts
    ok "Added $DOMAIN to /etc/hosts"
else
    skip "$DOMAIN already in /etc/hosts"
fi

systemctl restart apache2
ok "Apache restarted — Web Lab live at http://$DOMAIN"

# =============================================================================
# [7] API LAB
# =============================================================================
step "Deploying API Lab"

info "Copying API to $API_ROOT..."
rm -rf "$API_ROOT"
mkdir -p "$API_ROOT"
cp -r "$REPO_DIR/api/." "$API_ROOT/"
ok "API files deployed to $API_ROOT"

info "Installing npm dependencies..."
cd "$API_ROOT"
npm install --silent > /dev/null 2>&1
ok "npm install complete"

# Seed database
info "Seeding database with test users..."
node - << 'SEED'
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

async function seed() {
    await mongoose.connect('mongodb://127.0.0.1:27017/fluffy-paws');
    const db = mongoose.connection.db;
    const users = db.collection('users');

    await users.deleteMany({});

    const aliceHash = await bcrypt.hash('meow123', 10);
    const johnHash  = await bcrypt.hash('whiskers99', 10);

    await users.insertMany([
        {
            username: 'alice',
            email: 'alice@fluffypaws.com',
            password_hash: aliceHash,
            role: 'user',
            created_at: new Date()
        },
        {
            username: 'john',
            email: 'john@fluffypaws.com',
            password_hash: johnHash,
            role: 'admin',
            created_at: new Date()
        }
    ]);

    console.log('Seed complete');
    await mongoose.disconnect();
}

seed().catch(e => { console.error(e); process.exit(1); });
SEED
ok "Test users created (FerretDB/SQLite)"

# systemd service
info "Creating systemd service..."
cat > /etc/systemd/system/fluffy-paws-api.service << EOF
[Unit]
Description=Fluffy Paws Vulnerable API
After=network.target ferretdb.service
Requires=ferretdb.service

[Service]
Type=simple
User=www-data
WorkingDirectory=$API_ROOT
ExecStart=/usr/bin/node app.js
Restart=on-failure
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable fluffy-paws-api --quiet
systemctl restart fluffy-paws-api
sleep 2

if systemctl is-active --quiet fluffy-paws-api; then
    ok "API service is running"
else
    fail "API service failed to start. Check: journalctl -u fluffy-paws-api"
fi

# =============================================================================
# [8] LINUX USER (for privesc)
# =============================================================================
step "Creating Lab User"

if id "$DEV_USER" &>/dev/null; then
    skip "User '$DEV_USER' already exists — resetting password"
    echo "$DEV_USER:$DEV_PASS" | chpasswd
else
    useradd -m -s /bin/bash "$DEV_USER"
    echo "$DEV_USER:$DEV_PASS" | chpasswd
    ok "User '$DEV_USER' created"
fi

# Misconfigured sudo (intentional vulnerability)
echo "$DEV_USER ALL=(ALL) NOPASSWD: /usr/bin/find" > /etc/sudoers.d/dev-lab
chmod 440 /etc/sudoers.d/dev-lab
ok "sudo misconfiguration applied (intentional vuln)"

# =============================================================================
# [9] STATIC IP (Host-Only adapter)
# =============================================================================
step "Configuring Static IP on Host-Only Adapter"

HOST_ONLY_IFACE="enp0s8"
STATIC_IP="192.168.56.20"
NETPLAN_FILE="/etc/netplan/99-lab-static.yaml"

if ip link show "$HOST_ONLY_IFACE" > /dev/null 2>&1; then
    cat > "$NETPLAN_FILE" << EOF
network:
  version: 2
  ethernets:
    ${HOST_ONLY_IFACE}:
      dhcp4: no
      addresses:
        - ${STATIC_IP}/24
EOF
    chmod 600 "$NETPLAN_FILE"
    netplan apply > /dev/null 2>&1
    ok "Static IP ${STATIC_IP} assigned to ${HOST_ONLY_IFACE}"
else
    warn "Interface ${HOST_ONLY_IFACE} not found — skipping static IP setup"
    warn "Make sure Adapter 2 (Host-Only) is enabled in VirtualBox before running setup"
fi

# =============================================================================
# [9] SMOKE TESTS
# =============================================================================
step "Running Smoke Tests"

# Web
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:80" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    ok "Web Lab responding (HTTP 200)"
else
    info "Web Lab returned HTTP $HTTP_CODE — check Apache logs if unexpected"
fi

# API
sleep 1
API_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:3000/api/ping" 2>/dev/null || echo "000")
if [ "$API_CODE" = "200" ]; then
    ok "API responding (HTTP 200)"
else
    info "API returned HTTP $API_CODE — check: journalctl -u fluffy-paws-api -n 20"
fi

# =============================================================================
# [10] SUMMARY
# =============================================================================

echo ""
echo -e "${GREEN}${BOLD}"
cat << 'EOF'
  ╔══════════════════════════════════════════════════════╗
  ║           Fluffy Paws Lab — Setup Complete           ║
  ╚══════════════════════════════════════════════════════╝
EOF
echo -e "${RESET}"

echo -e "  ${BOLD}Version${RESET}                  ${LAB_VERSION}"
echo ""
echo -e "  ${BOLD}Lab address (Host-Only)${RESET}"
echo -e "  └─ http://192.168.56.20"
echo ""
echo -e "  ${BOLD}To isolate (disable internet)${RESET}"
echo -e "  └─ VirtualBox -> Settings -> Network -> Adapter 1 -> uncheck Enable"
echo ""
echo -e "  ${BOLD}To update (re-enable internet)${RESET}"
echo -e "  └─ VirtualBox -> Settings -> Network -> Adapter 1 -> check Enable"
echo ""
echo -e "  ${BOLD}API Test Users${RESET}"
echo -e "  ├─ alice  /  meow123      (role: user)"
echo -e "  └─ john   /  whiskers99   (role: admin)"
echo ""
echo -e "  ${BOLD}Linux User (for privesc chain)${RESET}"
echo -e "  └─ dev  /  SuperSecret123"
echo ""
echo -e "  ${BOLD}Quick Verification${RESET}"
echo -e "  ├─ curl http://192.168.56.20:80"
echo -e "  ├─ curl http://192.168.56.20:3000/api/ping"
echo -e "  └─ curl -s -X POST http://192.168.56.20:3000/api/auth/login \\"
echo -e "          -H 'Content-Type: application/json' \\"
echo -e "          -d '{\"username\":\"alice\",\"password\":\"meow123\"}'"
echo ""
echo -e "  ${BOLD}Service Management${RESET}"
echo -e "  ├─ sudo systemctl status fluffy-paws-api"
echo -e "  ├─ sudo systemctl restart fluffy-paws-api"
echo -e "  └─ sudo journalctl -u fluffy-paws-api -f"
echo ""
echo -e "  ${RED}${BOLD}This lab is intentionally exploitable. Keep Adapter 1 disabled when not updating.${RESET}"
echo ""
