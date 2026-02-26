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
- Odoo config: `/etc/odoo.conf`
- `db_name = ovoco.co`
- `dbfilter = ovoco.co`
- `list_db = False`

### Email (IONOS)
- SMTP: `smtp.ionos.com` port `465` SSL/TLS
- IMAP: `imap.ionos.com` port `993` SSL/TLS
- Username: full IONOS email address
