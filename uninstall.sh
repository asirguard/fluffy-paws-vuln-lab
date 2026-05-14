#!/bin/bash

# =============================================================================
# Fluffy Paws — Vulnerable Lab Uninstaller
# =============================================================================
# Removes everything deployed by setup.sh:
#   - systemd services (fluffy-paws-api, ferretdb)
#   - Apache VirtualHost + web files
#   - API files at /opt/fluffy-paws-api
#   - FerretDB binary + data
#   - Linux user 'dev' + sudoers rule
#   - /etc/hosts entry for lab.local
#   - Optionally: Apache, Node.js, FerretDB packages
#   - Optionally: netplan static IP config
# =============================================================================

set -uo pipefail

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
warn() { echo -e "  ${YELLOW}[WARN]${RESET}  $1"; }
step() { echo -e "\n${BOLD}──────────────────────────────────────────${RESET}"; \
         echo -e "${BOLD} $1${RESET}"; \
         echo -e "${BOLD}──────────────────────────────────────────${RESET}"; }

# ── Config (must match setup.sh) ──────────────────────────────────────────────
WEB_ROOT="/var/www/html/fluffy-paws"
API_ROOT="/opt/fluffy-paws-api"
FERRETDB_DATA="/var/lib/ferretdb"
DOMAIN="lab.local"
DEV_USER="dev"
NETPLAN_CONFIG="/etc/netplan/00-installer-config.yaml"

# =============================================================================
# [1] WARNING + CONFIRMATION
# =============================================================================
clear
echo -e "${RED}"
cat << 'EOF'
 ██╗   ██╗███╗   ██╗██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗
 ██║   ██║████╗  ██║██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║
 ██║   ██║██╔██╗ ██║██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║
 ██║   ██║██║╚██╗██║██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║
 ╚██████╔╝██║ ╚████║██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
  ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
EOF
echo -e "${RESET}"

echo -e "  ${BOLD}Fluffy Paws — Uninstaller${RESET}"
echo ""
echo -e "  This script will ${RED}permanently remove${RESET} the lab from this machine:"
echo ""
echo -e "    • systemd services: fluffy-paws-api, ferretdb"
echo -e "    • Web files:  $WEB_ROOT"
echo -e "    • API files:  $API_ROOT"
echo -e "    • Database:   $FERRETDB_DATA (all data lost)"
echo -e "    • Apache VirtualHost for $DOMAIN"
echo -e "    • Linux user '$DEV_USER' and its home directory"
echo -e "    • sudoers rule: /etc/sudoers.d/dev-lab"
echo -e "    • /etc/hosts entry for $DOMAIN"
echo ""
echo -e "  ${YELLOW}You will be asked separately about:${RESET}"
echo -e "    • Removing packages (Apache, Node.js, FerretDB)"
echo -e "    • Reverting netplan static IP config"
echo ""

# Root check before asking
if [ "$EUID" -ne 0 ]; then
    echo -e "  ${RED}[FAIL]${RESET}  Please run as root: sudo bash uninstall.sh"
    exit 1
fi

echo -e "${YELLOW}  Type ${BOLD}YES${RESET}${YELLOW} to confirm uninstall:${RESET}"
echo -n "  > "
read -r CONFIRM

if [ "${CONFIRM^^}" != "YES" ]; then
    echo ""
    echo -e "  ${CYAN}Aborted. Nothing was removed.${RESET}"
    echo ""
    exit 0
fi

# =============================================================================
# [2] systemd SERVICES
# =============================================================================
step "Stopping and Removing systemd Services"

for SVC in fluffy-paws-api ferretdb; do
    if systemctl list-unit-files | grep -q "^${SVC}.service"; then
        systemctl stop "$SVC"    2>/dev/null && true
        systemctl disable "$SVC" 2>/dev/null --quiet && true
        rm -f "/etc/systemd/system/${SVC}.service"
        ok "Removed service: $SVC"
    else
        skip "Service not found: $SVC"
    fi
done

systemctl daemon-reload
ok "systemd daemon reloaded"

# =============================================================================
# [3] APACHE — VirtualHost + Web Files
# =============================================================================
step "Removing Apache VirtualHost and Web Files"

if [ -f /etc/apache2/sites-available/fluffy-paws.conf ]; then
    a2dissite fluffy-paws.conf > /dev/null 2>&1 && true
    rm -f /etc/apache2/sites-available/fluffy-paws.conf
    ok "VirtualHost config removed"
else
    skip "VirtualHost config not found"
fi

# Re-enable default site if it was disabled
if [ ! -f /etc/apache2/sites-enabled/000-default.conf ]; then
    if [ -f /etc/apache2/sites-available/000-default.conf ]; then
        a2ensite 000-default.conf > /dev/null 2>&1 && true
        info "Re-enabled Apache default site"
    fi
fi

if [ -d "$WEB_ROOT" ]; then
    rm -rf "$WEB_ROOT"
    ok "Removed web files: $WEB_ROOT"
else
    skip "Web root not found: $WEB_ROOT"
fi

if systemctl is-active --quiet apache2; then
    systemctl restart apache2
    ok "Apache restarted"
fi

# =============================================================================
# [4] API FILES
# =============================================================================
step "Removing API Files"

if [ -d "$API_ROOT" ]; then
    rm -rf "$API_ROOT"
    ok "Removed API files: $API_ROOT"
else
    skip "API root not found: $API_ROOT"
fi

# =============================================================================
# [5] FERRETDB DATA
# =============================================================================
step "Removing FerretDB Data"

if [ -d "$FERRETDB_DATA" ]; then
    rm -rf "$FERRETDB_DATA"
    ok "Removed database: $FERRETDB_DATA"
else
    skip "FerretDB data directory not found"
fi

# =============================================================================
# [6] LINUX USER
# =============================================================================
step "Removing Lab User"

if id "$DEV_USER" &>/dev/null; then
    userdel -r "$DEV_USER" 2>/dev/null && ok "Removed user '$DEV_USER' and home dir" \
        || warn "userdel returned non-zero — user may have running processes"
else
    skip "User '$DEV_USER' does not exist"
fi

if [ -f /etc/sudoers.d/dev-lab ]; then
    rm -f /etc/sudoers.d/dev-lab
    ok "Removed sudoers rule: /etc/sudoers.d/dev-lab"
else
    skip "Sudoers rule not found"
fi

# =============================================================================
# [7] /etc/hosts
# =============================================================================
step "Cleaning /etc/hosts"

if grep -q "$DOMAIN" /etc/hosts; then
    sed -i "/$DOMAIN/d" /etc/hosts
    ok "Removed '$DOMAIN' from /etc/hosts"
else
    skip "'$DOMAIN' not found in /etc/hosts"
fi

# =============================================================================
# [8] OPTIONAL — Remove Packages
# =============================================================================
step "Optional: Remove Installed Packages"

echo ""
echo -e "  Remove packages installed by setup.sh?"
echo -e "  ${YELLOW}This will remove:${RESET} apache2, php, libapache2-mod-php, nodejs, ferretdb"
echo -e "  ${RED}Warning:${RESET} if these packages are used by other apps, they will break."
echo ""
echo -n "  Remove packages? [y/N] > "
read -r REMOVE_PKGS

if [[ "${REMOVE_PKGS,,}" == "y" ]]; then
    info "Removing packages..."
    apt-get remove -y --purge apache2 php libapache2-mod-php nodejs ferretdb \
        > /dev/null 2>&1 && true
    apt-get autoremove -y > /dev/null 2>&1 && true
    ok "Packages removed"

    # Remove NodeSource repo if present
    if [ -f /etc/apt/sources.list.d/nodesource.list ]; then
        rm -f /etc/apt/sources.list.d/nodesource.list
        ok "Removed NodeSource repo"
    fi
else
    skip "Packages kept"
fi

# =============================================================================
# [9] OPTIONAL — Revert Netplan
# =============================================================================
step "Optional: Revert Static IP (netplan)"

if [ -f "$NETPLAN_CONFIG" ]; then
    echo ""
    echo -e "  Found netplan config: $NETPLAN_CONFIG"
    echo -e "  ${YELLOW}Removing it will revert to DHCP.${RESET}"
    echo -e "  ${RED}Warning:${RESET} your SSH session may drop if you're connected remotely."
    echo ""
    echo -n "  Remove netplan static IP config? [y/N] > "
    read -r REMOVE_NETPLAN

    if [[ "${REMOVE_NETPLAN,,}" == "y" ]]; then
        rm -f "$NETPLAN_CONFIG"
        ok "Removed $NETPLAN_CONFIG"

        # Write a minimal DHCP config so the machine doesn't lose connectivity
        NETWORK_IFACE=$(ip link show | awk -F': ' '/^[0-9]+: e/{print $2; exit}')
        if [ -n "$NETWORK_IFACE" ]; then
            cat > /etc/netplan/00-dhcp.yaml << EOF
network:
  version: 2
  ethernets:
    ${NETWORK_IFACE}:
      dhcp4: true
EOF
            chmod 600 /etc/netplan/00-dhcp.yaml
            netplan apply 2>/dev/null && ok "Switched to DHCP on $NETWORK_IFACE" \
                || warn "netplan apply returned non-zero — verify with: ip addr show $NETWORK_IFACE"
        else
            warn "No ethernet interface detected — skipping netplan apply"
        fi
    else
        skip "Netplan config kept"
    fi
else
    skip "Netplan config not found: $NETPLAN_CONFIG"
fi

# =============================================================================
# [10] SUMMARY
# =============================================================================
echo ""
echo -e "${GREEN}${BOLD}"
cat << 'EOF'
  ╔══════════════════════════════════════════════════════╗
  ║          Fluffy Paws Lab — Uninstall Complete        ║
  ╚══════════════════════════════════════════════════════╝
EOF
echo -e "${RESET}"
echo -e "  All lab components have been removed."
echo -e "  The system is clean."
echo ""
