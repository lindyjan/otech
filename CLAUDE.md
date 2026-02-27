# Ovoco Project Notes — otech repo

This repo contains the Odoo 18 core source code (`odoo-bin`, standard `addons/`).
It is a fork of `odoo/odoo` tracking the `18.0` branch, deployed to `/opt/odoo/odoo18/` on the VPS.

Custom modules live in the **ovoco** repo (`lindyjan/ovoco`), NOT here.

## VPS
- **IP**: 108.175.12.143
- **SSH**: `ssh root@108.175.12.143`
- **Odoo core path**: `/opt/odoo/odoo18`
- **Custom modules path**: `/opt/odoo/ovoco/custom_addons`

## Odoo Multi-Website Setup

This is a multi-website, multi-company Odoo 18 deployment. Each website belongs to a different company.
All companies share one Odoo instance and one PostgreSQL database (`ovoco.co`).

### Websites / Companies

| ID | Company | Domain | Business | Key Odoo Modules |
|----|---------|--------|----------|-----------------|
| 1 | Ovoco | ovoco.co | Federal PM, marketing, proposals | Project, CRM, Sales, Invoicing, Documents, Timesheet |
| 2 | Morel Media Studio | morelmediastudio.com | Media & creative agency | Project, Timesheet, Sales, Invoicing, CRM |
| — | Ovoco Property | property.ovoco.co | Tax deed buying/selling, rentals, construction/rehab | Construction suite (pragtech_ppc + all custom modules), Sales, Invoicing, Rental |
| — | i84 Mobile | i84mobile.com | Diesel repair shop | Field Service, Inventory, Sales, Invoicing |

- **Website ID 1** = Ovoco (the default website, XML ID `website.default_website`)
- **Website ID 2** = Morel Media Studio
- Ovoco Property and i84 Mobile websites have not been created yet
- **books.ovoco.co** — Separate accounting app that interfaces with Odoo via API (JSON-RPC / REST)
- Each domain gets its own Nginx server block → Odoo website → company

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
├── odoo18/   ← THIS REPO (otech — Odoo 18 core + standard addons)
├── ovoco/    ← ovoco repo (custom_addons/ + deploy/)
└── venv/     ← Python virtual environment
```

| Server Path | GitHub Repo | Branch | Contains |
|---|---|---|---|
| `/opt/odoo/odoo18/` | `lindyjan/otech` | `18.0` | Odoo 18 core source, `odoo-bin`, standard `addons/` |
| `/opt/odoo/ovoco/` | `lindyjan/ovoco` | `main` | `custom_addons/` (custom modules), `deploy/` (config templates) |
| `/opt/odoo/venv/` | — | — | Python virtual environment for Odoo |

### Git Authentication
- **Method**: SSH keys (password auth is not supported by GitHub)
- **SSH key**: ed25519 key at `~/.ssh/id_ed25519` on the VPS
- **Remote URLs** (SSH format):
  - otech origin: `git@github.com:lindyjan/otech.git`
  - otech upstream: `https://github.com/odoo/odoo.git` (official Odoo repo)
  - ovoco origin: `git@github.com:lindyjan/ovoco.git`
- **GitHub user**: `lindyjan`
- **Git identity on VPS**: `lindyjan` / `lindyjan@users.noreply.github.com`

### Git Push Commands
```bash
# Push otech (Odoo core — this repo)
cd /opt/odoo/odoo18
git push -u origin 18.0

# Push ovoco (custom modules — other repo)
cd /opt/odoo/ovoco
git push -u origin main
```

### Updating Odoo 18 Core
```bash
cd /opt/odoo/odoo18
git fetch upstream 18.0
git merge upstream/18.0
# Re-apply project_todo bug fix after every core update (see below)
sudo sed -i 's/GROUP BY is_task, states, act.res_model, act.res_id/GROUP BY t.project_id, states, act.res_model, act.res_id/' /opt/odoo/odoo18/addons/project_todo/models/res_users.py
sudo systemctl stop odoo
sudo -u odoo /opt/odoo/venv/bin/python /opt/odoo/odoo18/odoo-bin -c /etc/odoo.conf -u base --stop-after-init
sudo systemctl start odoo
git push -u origin 18.0
```

### Known Core Bugs (fix after each upstream pull)
- **project_todo GROUP BY bug**: `addons/project_todo/models/res_users.py` uses `GROUP BY is_task` (an alias) which PostgreSQL rejects. Fix: replace `is_task` with `t.project_id` in the GROUP BY clause.
  ```bash
  sudo sed -i 's/GROUP BY is_task, states, act.res_model, act.res_id/GROUP BY t.project_id, states, act.res_model, act.res_id/' /opt/odoo/odoo18/addons/project_todo/models/res_users.py
  ```

### VPS Maintenance Commands
```bash
# Stop/start Odoo
sudo systemctl stop odoo
sudo systemctl start odoo

# Update a single module
sudo systemctl stop odoo
sudo -u odoo /opt/odoo/venv/bin/python /opt/odoo/odoo18/odoo-bin \
    -c /etc/odoo.conf -d ovoco.co -u <module_name> --stop-after-init
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

### Custom Modules (in the ovoco repo, NOT this repo)

Custom modules are in `lindyjan/ovoco` → `custom_addons/`. Key modules:

| Module | Technical Name | Purpose |
|--------|---------------|---------|
| Morel Media Studio Theme | `website_morel` | Custom website theme + portfolio for morelmediastudio.com (website ID 2) |
| Project Planning & Controlling | `pragtech_ppc` | **Install first.** Core WBS, budgeting, material/labour estimation |
| Gantt Chart | `pragtech_ppc_ganttchart` | Visual Gantt chart for project timelines (depends on pragtech_ppc) |
| Sub-Contracting | `pragtech_contracting` | Work orders, RA billing, retention (depends on pragtech_ppc) |
| Tender Management | `pragtech_tender_management` | Publish tenders, collect bids (depends on pragtech_ppc) |
| Land Acquisition | `odoo_pragtech_construction_land_acquisition` | Property records, proposals, sales |
| Project Expenses | `odoo_pragtech_construction_project_expenses` | Links HR expenses to projects |

### Default Odoo Credentials (fresh install)
- **Login**: `admin`
- **Password**: `admin`
- After running setup script (`deploy/setup_odoo.py` in ovoco repo), admin login changes to `admin@ovoco.co`

### Email Servers

| Company | Email | Provider | SMTP | IMAP |
|---------|-------|----------|------|------|
| Ovoco | admin@ovoco.co | Gmail | smtp.gmail.com:465 SSL | imap.gmail.com:993 SSL |
| Ovoco Property | *(shares Ovoco)* | Gmail | *(shares Ovoco)* | *(shares Ovoco)* |
| Morel Media Studio | info@morelmediastudio.com | IONOS | smtp.ionos.com:465 SSL | imap.ionos.com:993 SSL |
| i84 Mobile | tech@i84mobile.com | Gmail | smtp.gmail.com:465 SSL | imap.gmail.com:993 SSL |
