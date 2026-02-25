#!/usr/bin/env bash
# ============================================================
# Odoo 18 Multisite Setup Script for IONOS VPS
# ============================================================
# Run as root on your IONOS VPS.
#
# What this script does:
#   1. Installs the Odoo config with multisite dbfilter
#   2. Installs the Nginx multisite config for all domains
#   3. Obtains SSL certificates via Let's Encrypt
#   4. Restarts Odoo and Nginx
#
# Usage:
#   scp deploy/setup-multisite.sh root@YOUR_VPS_IP:/tmp/
#   ssh root@YOUR_VPS_IP
#   chmod +x /tmp/setup-multisite.sh
#   /tmp/setup-multisite.sh
# ============================================================

set -euo pipefail

# --- Configuration ---
ODOO_CONF="/etc/odoo.conf"
NGINX_CONF="/etc/nginx/sites-available/odoo"
NGINX_ENABLED="/etc/nginx/sites-enabled/odoo"
DEPLOY_DIR="/opt/odoo/deploy"

# All domains to configure SSL for
PRODUCTION_DOMAINS=(
    "i84mobile.com"
    "www.i84mobile.com"
    "morelmediastudio.com"
    "www.morelmediastudio.com"
    "ovoco.co"
    "www.ovoco.co"
    "books.ovoco.co"
    "property.ovoco.co"
)

STAGING_DOMAINS=(
    "test.ovoco.co"
    "test.i84mobile.com"
    "test.morelmediastudio.com"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Preflight checks ---
echo ""
echo "============================================================"
echo "  Odoo 18 Multisite Setup for IONOS VPS"
echo "============================================================"
echo ""

if [[ $EUID -ne 0 ]]; then
    err "This script must be run as root."
    exit 1
fi

# Check that Odoo is installed
if ! systemctl list-unit-files | grep -q odoo.service; then
    err "Odoo systemd service not found. Is Odoo installed?"
    exit 1
fi

# Check that Nginx is installed
if ! command -v nginx &> /dev/null; then
    warn "Nginx not installed. Installing..."
    apt-get update && apt-get install -y nginx
    log "Nginx installed."
fi

# Check that certbot is installed
if ! command -v certbot &> /dev/null; then
    warn "Certbot not installed. Installing..."
    apt-get update && apt-get install -y certbot python3-certbot-nginx
    log "Certbot installed."
fi

# --- Step 1: Odoo Configuration ---
echo ""
echo "--- Step 1: Odoo Configuration ---"

if [[ -f "$ODOO_CONF" ]]; then
    # Backup existing config
    cp "$ODOO_CONF" "${ODOO_CONF}.bak.$(date +%Y%m%d%H%M%S)"
    log "Backed up existing config to ${ODOO_CONF}.bak.*"
fi

# Check if the deploy directory has the new config
if [[ -f "${DEPLOY_DIR}/odoo-server.conf" ]]; then
    cp "${DEPLOY_DIR}/odoo-server.conf" "$ODOO_CONF"
    log "Installed Odoo config from deploy directory."
else
    warn "No odoo-server.conf found in ${DEPLOY_DIR}."
    warn "You need to manually copy deploy/odoo-server.conf to ${ODOO_CONF}"
    warn "Continuing with existing config..."
fi

# Verify key multisite settings
if grep -q "dbfilter" "$ODOO_CONF"; then
    log "dbfilter is configured in odoo.conf"
else
    warn "dbfilter NOT found in odoo.conf. Adding it..."
    echo "dbfilter = ^odoo18prod$" >> "$ODOO_CONF"
    log "Added dbfilter = ^odoo18prod$ to odoo.conf"
fi

if grep -q "proxy_mode = True" "$ODOO_CONF"; then
    log "proxy_mode is enabled"
else
    warn "proxy_mode not enabled. This is required for Nginx reverse proxy."
fi

chown odoo:odoo "$ODOO_CONF"
chmod 640 "$ODOO_CONF"
log "Odoo config permissions set."

# --- Step 2: Nginx Configuration ---
echo ""
echo "--- Step 2: Nginx Configuration ---"

if [[ -f "$NGINX_CONF" ]]; then
    cp "$NGINX_CONF" "${NGINX_CONF}.bak.$(date +%Y%m%d%H%M%S)"
    log "Backed up existing Nginx config."
fi

if [[ -f "${DEPLOY_DIR}/nginx-multisite.conf" ]]; then
    cp "${DEPLOY_DIR}/nginx-multisite.conf" "$NGINX_CONF"
    log "Installed Nginx multisite config."
else
    warn "No nginx-multisite.conf found in ${DEPLOY_DIR}."
    warn "You need to manually copy deploy/nginx-multisite.conf to ${NGINX_CONF}"
fi

# Ensure symlink exists
if [[ ! -L "$NGINX_ENABLED" ]]; then
    ln -sf "$NGINX_CONF" "$NGINX_ENABLED"
    log "Created Nginx sites-enabled symlink."
fi

# Remove default Nginx site if it exists (conflicts on port 80)
if [[ -L /etc/nginx/sites-enabled/default ]]; then
    rm /etc/nginx/sites-enabled/default
    log "Removed default Nginx site."
fi

# --- Step 3: SSL Certificates ---
echo ""
echo "--- Step 3: SSL Certificates ---"
echo ""
echo "Before obtaining SSL certificates, the Nginx config needs to"
echo "work without SSL first. We'll temporarily create HTTP-only"
echo "server blocks, get the certs, then switch to the full config."
echo ""

# First, install a temporary HTTP-only config for certbot
TEMP_CONF=$(mktemp)
cat > "$TEMP_CONF" << 'TEMPEOF'
upstream odoo {
    server 127.0.0.1:8069;
}
upstream odoo-websocket {
    server 127.0.0.1:8072;
}
TEMPEOF

# Add HTTP server blocks for all domains
ALL_DOMAINS=("${PRODUCTION_DOMAINS[@]}" "${STAGING_DOMAINS[@]}")
declare -A SEEN_BLOCKS
for domain in "${ALL_DOMAINS[@]}"; do
    # Skip www variants for server blocks (they share with the base domain)
    base="${domain#www.}"
    if [[ -n "${SEEN_BLOCKS[$base]:-}" ]]; then
        continue
    fi
    SEEN_BLOCKS[$base]=1

    # Build server_name including www if it's a non-subdomain
    if [[ "$domain" == "$base" ]] && [[ ! "$domain" == *.*.* ]]; then
        server_names="$base www.$base"
    else
        server_names="$base"
    fi

    cat >> "$TEMP_CONF" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${server_names};
    location / {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:8069;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header Host \$host;
    }
}
EOF
done

cp "$TEMP_CONF" "$NGINX_CONF"
rm "$TEMP_CONF"

# Test and reload Nginx with temp config
if nginx -t 2>/dev/null; then
    systemctl reload nginx
    log "Nginx reloaded with temporary HTTP config for certbot."
else
    err "Nginx config test failed. Check syntax."
    nginx -t
    exit 1
fi

# Obtain SSL certificates for each domain group
echo ""
echo "Obtaining SSL certificates..."
echo ""

obtain_cert() {
    local primary="$1"
    shift
    local domains=("$@")

    local certbot_args=("--nginx" "--non-interactive" "--agree-tos" "--redirect")

    # Add email if available
    if [[ -n "${CERTBOT_EMAIL:-}" ]]; then
        certbot_args+=("--email" "$CERTBOT_EMAIL")
    else
        certbot_args+=("--register-unsafely-without-email")
    fi

    for d in "${domains[@]}"; do
        certbot_args+=("-d" "$d")
    done

    if certbot "${certbot_args[@]}" 2>/dev/null; then
        log "SSL certificate obtained for ${primary}"
    else
        warn "Could not obtain SSL for ${primary}. DNS may not be pointed yet."
        warn "Run manually later: certbot --nginx -d ${domains[*]}"
    fi
}

# Get certs grouped by primary domain
obtain_cert "i84mobile.com" "i84mobile.com" "www.i84mobile.com"
obtain_cert "morelmediastudio.com" "morelmediastudio.com" "www.morelmediastudio.com"
obtain_cert "ovoco.co" "ovoco.co" "www.ovoco.co"
obtain_cert "books.ovoco.co" "books.ovoco.co"
obtain_cert "property.ovoco.co" "property.ovoco.co"
obtain_cert "test.ovoco.co" "test.ovoco.co"
obtain_cert "test.i84mobile.com" "test.i84mobile.com"
obtain_cert "test.morelmediastudio.com" "test.morelmediastudio.com"

# --- Step 4: Install Final Nginx Config ---
echo ""
echo "--- Step 4: Final Nginx Config ---"

# Now put the full multisite config back (with SSL blocks)
if [[ -f "${DEPLOY_DIR}/nginx-multisite.conf" ]]; then
    cp "${DEPLOY_DIR}/nginx-multisite.conf" "$NGINX_CONF"
fi

if nginx -t 2>/dev/null; then
    systemctl reload nginx
    log "Nginx reloaded with full multisite SSL config."
else
    warn "Full SSL config has errors (some certs may be missing)."
    warn "Check with: nginx -t"
    warn "Fix missing certs, then: systemctl reload nginx"
fi

# --- Step 5: Restart Odoo ---
echo ""
echo "--- Step 5: Restart Odoo ---"

systemctl restart odoo
sleep 3

if systemctl is-active --quiet odoo; then
    log "Odoo is running."
else
    err "Odoo failed to start. Check: journalctl -u odoo -n 50"
fi

# --- Step 6: Post-Setup Instructions ---
echo ""
echo "============================================================"
echo "  Setup Complete!"
echo "============================================================"
echo ""
echo "Next steps (in Odoo admin UI):"
echo ""
echo "  1. Go to: https://ovoco.co/web?debug=1"
echo "     Log in as admin."
echo ""
echo "  2. Install the 'Website' module:"
echo "     Apps > Search 'Website' > Install"
echo ""
echo "  3. Configure websites:"
echo "     Settings > Website > click 'Websites' at the top"
echo ""
echo "     Create 3 websites:"
echo "     ┌──────────────────────┬────────────────────────────┐"
echo "     │ Website Name         │ Domain                     │"
echo "     ├──────────────────────┼────────────────────────────┤"
echo "     │ Ovoco                │ ovoco.co                   │"
echo "     │ i84 Mobile           │ i84mobile.com              │"
echo "     │ Morel Media Studio   │ morelmediastudio.com       │"
echo "     └──────────────────────┴────────────────────────────┘"
echo ""
echo "  4. For each website, set:"
echo "     - Domain name (e.g., i84mobile.com)"
echo "     - Company (if using multi-company)"
echo "     - Default language"
echo "     - Theme (customize per site)"
echo ""
echo "  5. Verify by visiting each domain in your browser."
echo ""
echo "  6. To manage per-site content, use the website switcher"
echo "     in the top-right of the Website Builder."
echo ""
echo "Useful commands:"
echo "  systemctl status odoo        # Check Odoo status"
echo "  systemctl status nginx       # Check Nginx status"
echo "  certbot certificates         # List SSL certs"
echo "  tail -f /var/log/odoo/odoo.log  # Watch Odoo logs"
echo ""
