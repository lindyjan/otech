# Ovoco Project Notes

## Odoo Multi-Website Setup

This is a multi-website, multi-company Odoo deployment. Each website belongs to a different company.

### Setup Steps
1. **Settings → Users & Companies → Companies** → create a company per website
2. **Website → Configuration → Settings → Website Info → Company** → assign each website to its company
3. Assign users to the appropriate company

### Websites / Companies
- ovoco.co
- i84mobile.com

### Database
- **Database name: `ovoco.co`**

### VPS Configuration
- **Server**: IONOS VPS (Ubuntu)
- **Python venv**: `/opt/odoo/venv` (use `/opt/odoo/venv/bin/pip` for packages)
- **Odoo binary**: `/opt/odoo/odoo18/odoo-bin`
- **Odoo config**: `/etc/odoo.conf`
- **DB name**: `ovoco.co`
- **DB user**: `odoo`
- **DB auth**: PostgreSQL peer auth (socket, `db_host = False`)
- `dbfilter = ovoco.co`
- `list_db = False`
- `proxy_mode = True`
- `workers = 2`
- `log_level = info`
- `addons_path = /opt/odoo/odoo18/addons,/opt/odoo/ovoco/custom_addons`

### Server Directory Structure
```
/opt/odoo/
├── odoo18/   ← otech repo (Odoo 18 core + standard addons)
├── ovoco/    ← ovoco repo (custom_addons/ + deploy/)
└── venv/     ← Python virtual environment
```

| Server Path | GitHub Repo | Branch | Contains |
|---|---|---|---|
| `/opt/odoo/odoo18/` | `lindyjan/otech` | `17.0` | Odoo 18 core source, `odoo-bin`, standard `addons/` |
| `/opt/odoo/ovoco/` | `lindyjan/ovoco` | `main` | `custom_addons/` (custom modules), `deploy/` (config templates) |
| `/opt/odoo/venv/` | — | — | Python virtual environment for Odoo |

### VPS Maintenance Commands
```bash
# Stop/start Odoo
sudo systemctl stop odoo
sudo systemctl start odoo

# Update base module (fixes asset caching issues)
sudo -u odoo /opt/odoo/venv/bin/python /opt/odoo/odoo18/odoo-bin -c /etc/odoo.conf -u base --stop-after-init

# Nuke & recreate database
sudo -u postgres dropdb ovoco.co
sudo -u postgres createdb -O odoo ovoco.co
sudo -u odoo /opt/odoo/venv/bin/python /opt/odoo/odoo18/odoo-bin -c /etc/odoo.conf -d ovoco.co -i base --stop-after-init

# Install Python dependencies (use the venv!)
/opt/odoo/venv/bin/pip install <package>
```

### Email (IONOS)
- SMTP: `smtp.ionos.com` port `465` SSL/TLS
- IMAP: `imap.ionos.com` port `993` SSL/TLS
- Username: full IONOS email address
