# Pushing to IONOS VPS

Quick reference for deploying and updating Odoo 18 on the IONOS VPS.

---

## Server Details

| Item | Value |
|------|-------|
| **Provider** | IONOS VPS (Cloud Server) |
| **OS** | Ubuntu |
| **User** | `root` |
| **Odoo Source** | `/opt/odoo/odoo18/` |
| **Custom Addons** | `/opt/odoo/custom/addons/` |
| **Odoo Config** | `/etc/odoo.conf` |
| **Odoo Venv** | `/opt/odoo/venv/` |
| **Odoo Service** | `odoo.service` (systemd) |
| **Odoo Log** | `/var/log/odoo/odoo.log` |
| **Nginx Config** | `/etc/nginx/sites-available/odoo` |

### Domains Hosted

| Domain | Type |
|--------|------|
| `books.ovoco.co` | Production (subdomain) |
| `test.ovoco.co` | Test / staging |
| `test.morelmediastudio.com` | Test / staging |
| `test.i84mobile.com` | Test / staging |
| `ovoco.co` / `www.ovoco.co` | Production |
| `property.ovoco.co` | Production (subdomain) |
| `morelmediastudio.com` / `www.morelmediastudio.com` | Production |
| `i84mobile.com` / `www.i84mobile.com` | Production |

---

## 1. SSH into the Server

```bash
ssh root@YOUR_VPS_IP
```

> Replace `YOUR_VPS_IP` with the actual IP from your IONOS Cloud Panel.

---

## 2. Deploy Custom Modules

Custom modules live in `/opt/odoo/custom/addons/` on the VPS. This path is
already in the `addons_path` in `/etc/odoo.conf`.

### Option A: SCP from Windows (Quickest for a Single Module)

From PowerShell on your local machine:

```powershell
# Push a single custom module
scp -r C:\Projects\ovoco\custom_addons\your_module root@YOUR_VPS_IP:/opt/odoo/custom/addons/

# Push all custom modules
scp -r C:\Projects\ovoco\custom_addons\* root@YOUR_VPS_IP:/opt/odoo/custom/addons/
```

### Option B: rsync (Best for Incremental Updates)

```bash
# From your local machine (Git Bash or WSL)
rsync -avz --exclude='__pycache__' \
  /c/Projects/ovoco/custom_addons/ root@YOUR_VPS_IP:/opt/odoo/custom/addons/
```

### Option C: Git (If Custom Addons Have Their Own Repo)

```bash
# On the VPS
cd /opt/odoo/custom/addons
git clone https://github.com/lindyjan/ovoco.git -b main temp_clone
cp -r temp_clone/custom_addons/* /opt/odoo/custom/addons/
rm -rf temp_clone
```

### After Deploying

Fix ownership so the `odoo` user can read the files:

```bash
chown -R odoo:odoo /opt/odoo/custom/addons/
```

---

## 3. Restart Odoo

After pushing code changes:

```bash
# Restart the Odoo service
systemctl restart odoo

# Check it started cleanly
systemctl status odoo

# Watch the logs
tail -f /var/log/odoo/odoo.log
```

Press `Ctrl+C` to stop following logs.

---

## 4. Install or Update a Module

After deploying module files to the VPS:

### Install a New Module

1. Restart Odoo: `systemctl restart odoo`
2. Go to **Apps** in the Odoo web UI
3. Click **Update Apps List** (enable Developer Mode first if needed)
4. Search for your module and click **Install**

Enable Developer Mode at: `https://your-domain.com/web?debug=1`

### Update an Existing Module (Command Line)

```bash
# Stop the running Odoo service
systemctl stop odoo

# Run the update command as the odoo user
sudo -u odoo /opt/odoo/venv/bin/python3 /opt/odoo/odoo18/odoo-bin \
  -c /etc/odoo.conf \
  -d YOUR_DATABASE_NAME \
  -u your_module_name \
  --stop-after-init

# Update multiple modules
sudo -u odoo /opt/odoo/venv/bin/python3 /opt/odoo/odoo18/odoo-bin \
  -c /etc/odoo.conf \
  -d YOUR_DATABASE_NAME \
  -u module1,module2 \
  --stop-after-init

# Start Odoo back up
systemctl start odoo
```

> Replace `YOUR_DATABASE_NAME` with your actual Odoo database name.

### List Available Databases

```bash
sudo -u postgres psql -l
```

---

## 5. Multisite Setup

All domains are served by a **single Odoo instance** using **one database**
(`odoo18prod`). Odoo's built-in multi-website module routes each domain to
the correct website content/theme within that database.

### Architecture

```
                     ┌─────────────┐
  i84mobile.com ────>│             │
  morelmediastudio ─>│   Nginx     │──> 127.0.0.1:8069 ──> Odoo 18
  ovoco.co ─────────>│  (SSL/TLS)  │──> 127.0.0.1:8072 ──> (websocket)
  books.ovoco.co ───>│             │
  property.ovoco.co─>│             │         │
                     └─────────────┘         ▼
                                        odoo18prod DB
                                     (multi-website module)
```

### Key Config Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| `db_name` | `odoo18prod` | Lock to single database |
| `dbfilter` | `^odoo18prod$` | Prevent other DB access |
| `proxy_mode` | `True` | Trust Nginx forwarded headers |
| `list_db` | `False` | Hide database manager |

### Config Files in This Repo

| File | Deploys to | Purpose |
|------|-----------|---------|
| `deploy/odoo-server.conf` | `/etc/odoo.conf` | Odoo config with multisite dbfilter |
| `deploy/nginx-multisite.conf` | `/etc/nginx/sites-available/odoo` | All domain server blocks |
| `deploy/setup-multisite.sh` | Run on VPS as root | Automated setup (SSL + Nginx + Odoo) |

### Quick Setup (Automated)

```bash
# From your local machine, copy the script to VPS
scp deploy/setup-multisite.sh root@YOUR_VPS_IP:/tmp/

# SSH in and run it
ssh root@YOUR_VPS_IP
chmod +x /tmp/setup-multisite.sh
CERTBOT_EMAIL=your@email.com /tmp/setup-multisite.sh
```

The script handles: Nginx config, SSL certificates, Odoo config, and restarts.

### Manual Setup

#### Step 1: DNS Records

Point all domains to your VPS IP in your registrar's DNS settings:

| Domain | Record Type | Value |
|--------|-------------|-------|
| `i84mobile.com` | A | YOUR_VPS_IP |
| `www.i84mobile.com` | A | YOUR_VPS_IP |
| `morelmediastudio.com` | A | YOUR_VPS_IP |
| `www.morelmediastudio.com` | A | YOUR_VPS_IP |
| `ovoco.co` | A | YOUR_VPS_IP |
| `www.ovoco.co` | A | YOUR_VPS_IP |
| `books.ovoco.co` | A | YOUR_VPS_IP |
| `property.ovoco.co` | A | YOUR_VPS_IP |

#### Step 2: Deploy Configs

```bash
# Copy Odoo config
scp deploy/odoo-server.conf root@YOUR_VPS_IP:/etc/odoo.conf

# Copy Nginx config
scp deploy/nginx-multisite.conf root@YOUR_VPS_IP:/etc/nginx/sites-available/odoo

# On the VPS: symlink and test
ssh root@YOUR_VPS_IP
ln -sf /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/odoo
nginx -t && systemctl reload nginx
```

#### Step 3: SSL Certificates

```bash
# Get certs for each domain group
certbot --nginx -d i84mobile.com -d www.i84mobile.com
certbot --nginx -d morelmediastudio.com -d www.morelmediastudio.com
certbot --nginx -d ovoco.co -d www.ovoco.co
certbot --nginx -d books.ovoco.co
certbot --nginx -d property.ovoco.co
```

#### Step 4: Restart Services

```bash
chown odoo:odoo /etc/odoo.conf
chmod 640 /etc/odoo.conf
systemctl restart odoo
systemctl reload nginx
```

#### Step 5: Configure Websites in Odoo

1. Log in at `https://ovoco.co/web?debug=1`
2. Go to **Apps** > search **Website** > **Install**
3. After install, go to **Settings** > **Website**
4. Click **Websites** in the top menu bar
5. Create websites:

| Website Name | Domain |
|-------------|--------|
| Ovoco | `ovoco.co` |
| i84 Mobile | `i84mobile.com` |
| Morel Media Studio | `morelmediastudio.com` |

6. For each website, configure:
   - **Domain**: the exact domain (e.g., `i84mobile.com`)
   - **Company**: assign to the correct company (if multi-company)
   - **Homepage**: set the landing page
   - **Theme**: pick a theme per site

7. Use the **website switcher** (top-right of Website Builder) to edit
   content for each site independently.

### Editing the Nginx Config

```bash
nano /etc/nginx/sites-available/odoo
```

### After Making Changes

```bash
nginx -t && systemctl reload nginx
```

### Adding a New Domain

1. Point the domain's DNS A record to your VPS IP
2. Add HTTP redirect + HTTPS server blocks to the Nginx config
   (see `deploy/nginx-multisite.conf` for the pattern)
3. Get an SSL certificate:
   ```bash
   certbot --nginx -d newdomain.com -d www.newdomain.com
   ```
4. Test and reload: `nginx -t && systemctl reload nginx`
5. In Odoo: **Settings** > **Website** > **Websites** > create a new website
   with the domain set to `newdomain.com`

---

## 6. SSL Certificate Management

Certificates are managed by Let's Encrypt via certbot.

```bash
# Check current certificates
certbot certificates

# Renew all certificates (dry run first)
certbot renew --dry-run

# Actually renew
certbot renew

# Add SSL to a new domain
certbot --nginx -d newdomain.com -d www.newdomain.com
```

Certbot sets up automatic renewal via a systemd timer. Verify it's active:

```bash
systemctl status certbot.timer
```

---

## 7. Database Backup and Restore

### Backup

```bash
# Backup a specific database
sudo -u postgres pg_dump YOUR_DATABASE_NAME > ~/backup_$(date +%F).sql

# Backup all databases
sudo -u postgres pg_dumpall > ~/backup_all_$(date +%F).sql
```

### Restore

```bash
# Restore a specific database
sudo -u postgres psql YOUR_DATABASE_NAME < ~/backup_2025-01-15.sql
```

### Backup Odoo Filestore

The filestore (uploaded files, attachments) is stored on disk:

```bash
# The filestore is typically at:
ls /opt/odoo/.local/share/Odoo/filestore/

# Copy the filestore to a backup location
cp -r /opt/odoo/.local/share/Odoo/filestore/ ~/odoo-filestore-backup/
```

---

## 8. Viewing Logs

```bash
# Follow Odoo logs (live)
tail -f /var/log/odoo/odoo.log

# Last 100 lines
tail -100 /var/log/odoo/odoo.log

# Search for errors
grep -i error /var/log/odoo/odoo.log | tail -20

# Odoo service status
systemctl status odoo

# Nginx logs
tail -f /var/log/nginx/odoo.access.log
tail -f /var/log/nginx/odoo.error.log
```

---

## 9. Common Operations Cheat Sheet

```bash
# SSH in
ssh root@YOUR_VPS_IP

# Restart Odoo
systemctl restart odoo

# Stop Odoo
systemctl stop odoo

# Start Odoo
systemctl start odoo

# Check Odoo status
systemctl status odoo

# View Odoo config
cat /etc/odoo.conf

# List databases
sudo -u postgres psql -l

# Check disk space
df -h

# Check memory usage
free -h

# Check running processes
htop
```

---

## 10. Typical Deploy Workflow

Here's the full workflow from making changes locally to seeing them live:

1. **Develop locally** on Windows with VS Code
2. **Test locally** at `http://localhost:8069`
3. **Commit and push** to GitHub:
   ```powershell
   cd C:\Projects\ovoco
   git add .
   git commit -m "describe your changes"
   git push origin main
   ```
4. **SSH into the VPS**:
   ```bash
   ssh root@YOUR_VPS_IP
   ```
5. **Copy custom modules to the VPS** (from a second PowerShell window):
   ```powershell
   scp -r C:\Projects\ovoco\custom_addons\* root@YOUR_VPS_IP:/opt/odoo/custom/addons/
   ```
6. **Fix ownership and restart**:
   ```bash
   chown -R odoo:odoo /opt/odoo/custom/addons/
   systemctl restart odoo
   ```
7. **Install/update modules if needed**:
   ```bash
   systemctl stop odoo
   sudo -u odoo /opt/odoo/venv/bin/python3 /opt/odoo/odoo18/odoo-bin \
     -c /etc/odoo.conf -d YOUR_DATABASE_NAME -u your_module_name --stop-after-init
   systemctl start odoo
   ```
8. **Verify** by visiting your domain in the browser
