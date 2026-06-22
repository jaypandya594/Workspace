# iSecurify — GRC Platform

A full-featured **Governance, Risk, and Compliance (GRC)** platform for managing policies, frameworks, controls, audits, risks, vulnerabilities, evidence, and multi-tenant operations.

Built with **Next.js 16**, **TypeScript**, **Prisma ORM**, **MySQL**, and **shadcn/ui**.

---

## 📋 Table of Contents

1. [Features](#-features)
2. [Tech Stack](#-tech-stack)
3. [Quick Start — Ubuntu Server + Nginx + MySQL](#-quick-start--ubuntu-server--nginx--mysql)
4. [Alternative: Docker + Docker Compose](#-alternative-docker--docker-compose)
5. [Alternative: Apache HTTP Server](#-alternative-apache-http-server)
6. [Environment Variables](#-environment-variables)
7. [Database Schema](#-database-schema)
8. [Default Login Credentials](#-default-login-credentials)
9. [Post-Deployment Checklist](#-post-deployment-checklist)
10. [Useful Commands](#-useful-commands)
11. [Troubleshooting](#-troubleshooting)
12. [Local Development](#-local-development)

---

## ✨ Features

| Module | Description |
|--------|-------------|
| **Dashboard** | Real-time compliance metrics, risk heat map, audit progress, vulnerability summary |
| **Controls Catalog** | Import/export controls (JSON, CSV, Word .docx), per-framework management, status tracking |
| **Frameworks** | ISO 27001, SOC 2, GDPR, HIPAA, PCI DSS — add any custom framework |
| **Policies** | Rich-text policy editor, versioning, approval workflow |
| **Audits** | Internal/external/regulatory audits with tasks, scheduling, and reporting |
| **Risks** | Risk register with likelihood × impact scoring, inherent/residual risk tracking |
| **Vulnerabilities** | Vulnerability tracking with CVSS scoring, severity, status management |
| **Evidence** | Upload files/links as evidence for control implementation |
| **Checklists** | Compliance questionnaires with Yes/No, text, rating, and multi-choice items |
| **Multi-Tenancy** | Each tenant has isolated data; super admin manages all tenants |
| **User Management** | RBAC: super_admin, tenant_admin, compliance_officer, auditor, employee |
| **Import/Export** | Bulk import controls from JSON, CSV, or Word documents with auto-column mapping |

---

## 🏗 Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Next.js 16 (App Router, standalone output) |
| Language | TypeScript 5 |
| Runtime | Bun (can also use Node.js) |
| Database | MySQL 8.0+ via Prisma ORM 6 |
| UI | React 19 + shadcn/ui + Tailwind CSS 4 + Framer Motion |
| State | Zustand (client), TanStack Query (server) |
| Auth | Custom scrypt-based session auth |
| Icons | Lucide React |

---

## 🚀 Quick Start — Ubuntu Server + Nginx + MySQL

This is the recommended production deployment method. Works on **Ubuntu 20.04, 22.04, or 24.04**.

### Prerequisites

- Ubuntu server (fresh or existing) with **root/sudo** access
- At least **2 GB RAM** (4 GB recommended)
- A **domain name** pointing to your server's IP (for HTTPS/SSL)
- SSH access to the server

### Step 1: Upload the Code to Your Server

```bash
# On your LOCAL machine — upload the project zip
scp isecurify.zip root@YOUR_SERVER_IP:/root/

# On the SERVER — extract
cd /root
unzip isecurify.zip -d /root/isecurify-src
cd /root/isecurify-src
```

### Step 2: Run the Deploy Script

```bash
# Make executable and run (pass your domain name)
chmod +x deploy/deploy.sh
sudo bash deploy/deploy.sh isecurify.yourdomain.com
```

The script will automatically:
1. Install system packages (nginx, mysql-server, certbot, curl)
2. Install Bun runtime
3. Create the `isecurify` Linux user
4. Create MySQL database and user
5. Copy application files to `/opt/isecurify/`
6. Configure `.env` with secure random secrets
7. Install npm/bun dependencies
8. Generate Prisma client and push schema to MySQL
9. Build the Next.js application
10. Install and start the systemd service
11. Configure Nginx reverse proxy

### Step 3: Setup SSL Certificate (HTTPS)

```bash
sudo certbot --nginx -d isecurify.yourdomain.com
```

Follow the prompts. Certbot will automatically configure SSL and redirect HTTP → HTTPS.

### Step 4: Seed Demo Data (First Time Only)

```bash
# Edit .env
sudo nano /opt/isecurify/.env
# Change SEED_DB=false to SEED_DB=true

# Restart to seed
sudo systemctl restart isecurify

# Wait 10-15 seconds, then set it back to false
sudo nano /opt/isecurify/.env
# Change SEED_DB=true back to SEED_DB=false
sudo systemctl restart isecurify
```

### Step 5: Verify Deployment

```bash
# Check service status
sudo systemctl status isecurify

# Check app logs
sudo journalctl -u isecurify -f

# Check Nginx
sudo nginx -t
```

Visit `https://isecurify.yourdomain.com` and log in with:
- **Email:** `admin@isecurify.com`
- **Password:** `Admin@123456`

> ⚠️ **Change the default password immediately after first login!**

---

## 🐳 Alternative: Docker + Docker Compose

If you prefer containerized deployment:

### Step 1: Upload and Configure

```bash
scp isecurify.zip root@YOUR_SERVER_IP:/root/
ssh root@YOUR_SERVER_IP
cd /root && unzip isecurify.zip -d /root/isecurify-src && cd /root/isecurify-src
```

### Step 2: Create .env File

```bash
cp .env.example .env
nano .env
```

Edit these values:
```env
DATABASE_URL=mysql://isecurify:YourStrongPassword123@db:3306/isecurify
NEXTAUTH_SECRET=$(openssl rand -base64 32)
NEXTAUTH_URL=https://isecurify.yourdomain.com
NEXT_PUBLIC_APP_URL=https://isecurify.yourdomain.com
SEED_DB=true    # Only on first deploy!
MYSQL_ROOT_PASSWORD=RootPassword123
MYSQL_DATABASE=isecurify
MYSQL_USER=isecurify
MYSQL_PASSWORD=YourStrongPassword123
```

### Step 3: Build and Start

```bash
docker compose up -d --build
```

### Step 4: Setup Nginx + SSL (same as Step 3-5 above)

The Docker container exposes port 3000. Configure Nginx to proxy to `127.0.0.1:3000`.

### Docker Management

```bash
docker compose logs -f app      # View app logs
docker compose logs -f db       # View MySQL logs
docker compose restart app      # Restart app
docker compose down             # Stop everything
docker compose up -d --build    # Rebuild and start
```

---

## 🌐 Alternative: Apache HTTP Server

If you prefer Apache over Nginx:

### Step 1: Install Apache

```bash
sudo apt-get update
sudo apt-get install -y apache2 certbot python3-certbot-apache
```

### Step 2: Enable Proxy Modules

```bash
sudo a2enmod proxy proxy_http proxy_wstunnel ssl headers rewrite
```

### Step 3: Create Apache Virtual Host

Create `/etc/apache2/sites-available/isecurify.conf`:

```apache
<VirtualHost *:80>
    ServerName isecurify.yourdomain.com

    # Let's Encrypt challenge
    DocumentRoot /var/www/html

    <IfModule mod_rewrite.c>
        RewriteEngine On
        RewriteRule ^/.well-known/acme-challenge/ - [L]
        RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    </IfModule>
</VirtualHost>

<VirtualHost *:443>
    ServerName isecurify.yourdomain.com

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/isecurify.yourdomain.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/isecurify.yourdomain.com/privkey.pem

    # Security Headers
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"

    # File upload limit
    LimitRequestBody 52428800

    # Proxy to iSecurify
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:3000/
    ProxyPassReverse / http://127.0.0.1:3000/

    # WebSocket support
    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} websocket [NC]
    RewriteCond %{HTTP:Connection} upgrade [NC]
    RewriteRule ^/?(.*) ws://127.0.0.1:3000/$1 [P,L]

    # Timeouts
    ProxyTimeout 120
</VirtualHost>
```

### Step 4: Enable and Configure

```bash
sudo a2dissite 000-default.conf
sudo a2ensite isecurify.conf
sudo apache2ctl configtest
sudo systemctl reload apache2

# Get SSL
sudo certbot --apache -d isecurify.yourdomain.com
```

---

## ⚙️ Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | ✅ | MySQL connection string: `mysql://user:pass@host:3306/dbname` |
| `NEXTAUTH_SECRET` | ✅ | Random 32+ char string for session encryption |
| `NEXTAUTH_URL` | ✅ | Your app's public URL (with https://) |
| `NEXT_PUBLIC_APP_URL` | ✅ | Same as NEXTAUTH_URL |
| `NODE_ENV` | ✅ | Set to `production` for deployed instances |
| `PORT` | No | Default: `3000` |
| `HOSTNAME` | No | Default: `0.0.0.0` (bind to all interfaces) |
| `UPLOAD_PATH` | No | Path for uploaded evidence files |
| `SEED_DB` | No | Set to `true` only on first deploy to create demo data |

Generate a secure `NEXTAUTH_SECRET`:
```bash
openssl rand -base64 32
```

---

## 🗄 Database Schema

The platform uses **17 models** managed by Prisma ORM:

- **Tenant** — Multi-tenant organization
- **User** — Users with RBAC roles
- **Session** — Active login sessions
- **PasswordReset** — Password reset tokens
- **Framework** — Compliance frameworks (ISO 27001, SOC 2, GDPR, etc.)
- **Control** — Framework controls (importable via JSON/CSV/Word)
- **ControlAssignment** — Per-tenant control implementation status
- **Evidence** — Files/links proving control implementation
- **Checklist** — Compliance questionnaires
- **ChecklistItem** — Individual checklist questions
- **ChecklistAnswer** — User responses to checklist items
- **Vulnerability** — Security vulnerabilities with CVSS
- **Risk** — Risk register entries
- **Policy** — Organizational policies
- **PolicyApproval** — Policy approval workflow
- **Audit** — Audit engagements
- **AuditTask** — Tasks within an audit
- **AuditLog** — System audit trail
- **Notification** — In-app notifications

---

## 🔑 Default Login Credentials

| Role | Email | Password |
|------|-------|----------|
| Super Admin | `admin@isecurify.com` | `Admin@123456` |
| Tenant Admin | `tenant@demo.com` | `Tenant@123` |
| Employee | `user@demo.com` | `User@123456` |

> ⚠️ **IMPORTANT:** Change all default passwords immediately after first login!

---

## ✅ Post-Deployment Checklist

- [ ] Application loads at `https://your-domain.com`
- [ ] Login works with `admin@isecurify.com` / `Admin@123456`
- [ ] Change default admin password
- [ ] SSL certificate is valid (check with `curl -I https://your-domain.com`)
- [ ] MySQL database has tables (run `mysql -u isecurify -p isecurify -e "SHOW TABLES;"`)
- [ ] Demo data seeded (frameworks, controls visible in Controls page)
- [ ] File uploads work (try uploading evidence)
- [ ] Import controls works (try JSON/CSV import)
- [ ] Systemd service is enabled: `systemctl is-enabled isecurify`
- [ ] Nginx is running: `systemctl status nginx`
- [ ] Firewall allows 80/443: `ufw status`
- [ ] Set up automatic MySQL backups (see below)
- [ ] Set up log rotation (see below)

---

## 🛠 Useful Commands

### Service Management
```bash
sudo systemctl start isecurify       # Start
sudo systemctl stop isecurify        # Stop
sudo systemctl restart isecurify     # Restart
sudo systemctl status isecurify      # Check status
journalctl -u isecurify -f           # Follow logs
```

### Database Management
```bash
# Connect to MySQL
mysql -u isecurify -p isecurify

# Backup database
mysqldump -u isecurify -p isecurify > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore database
mysql -u isecurify -p isecurify < backup_20250622.sql

# Push schema changes (after code update)
cd /opt/isecurify && bunx prisma db push
```

### Updates
```bash
cd /opt/isecurify
git pull origin main                    # Or re-upload zip
bun install                             # Install new dependencies
bunx prisma generate && bunx prisma db push   # Update DB schema
bun run build                           # Rebuild
sudo systemctl restart isecurify        # Restart
```

### Automatic MySQL Backup (Cron)
```bash
# Create backup script
sudo mkdir -p /opt/isecurify/backups
echo '#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
mysqldump -u isecurify -p"YOUR_DB_PASSWORD" isecurify | gzip > /opt/isecurify/backups/db_${DATE}.sql.gz
find /opt/isecurify/backups -name "*.sql.gz" -mtime +30 -delete
' | sudo tee /opt/isecurify/backup-db.sh

sudo chmod +x /opt/isecurify/backup-db.sh

# Run daily at 2 AM
echo "0 2 * * * /opt/isecurify/backup-db.sh" | sudo tee /etc/cron.d/isecurify-backup
```

---

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| **Blank page after deploy** | Check `journalctl -u isecurify -f` for errors. Usually a build or DATABASE_URL issue. |
| **Database connection error** | Verify `DATABASE_URL` in `.env`. Test with: `mysql -u USER -p -h HOST DBNAME` |
| **502 Bad Gateway** | App not running. Check `systemctl status isecurify` and restart. |
| **Port 3000 already in use** | Kill the process: `sudo lsof -ti:3000 \| xargs kill -9` then restart. |
| **SSL certificate error** | Run `sudo certbot --nginx -d your-domain.com --force-renewal` |
| **Permission denied** | Run `sudo chown -R isecurify:isecurify /opt/isecurify` |
| **Schema push fails** | Check MySQL user has ALL PRIVILEGES. Run `bunx prisma db push --accept-data-loss` |
| **Import not working** | Ensure the JSON/CSV has columns that map to `ref` and `title`. The import auto-detects 30+ column name variants. |
| **Data lost on restart** | Verify DATABASE_URL points to MySQL (not SQLite file path). Data in SQLite is not persistent across deployments. |
| **Nginx config test fails** | Run `sudo nginx -t` to see the exact error. Usually a syntax issue. |
| **High memory usage** | Add swap: `sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile` |

---

## 💻 Local Development

```bash
# 1. Install dependencies
bun install

# 2. Setup .env (SQLite for local dev)
echo "DATABASE_URL=file:./db/dev.db" > .env

# 3. Push schema and seed
bunx prisma db push
bunx prisma db seed

# 4. Start dev server
bun run dev
```

Open http://localhost:3000 — login with `admin@isecurify.com` / `Admin@123456`

---

## 📁 Project Structure

```
isecurify/
├── deploy/
│   ├── deploy.sh              # Automated deployment script
│   ├── isecurify.service      # Systemd service file
│   └── nginx/
│       └── isecurify.conf     # Nginx reverse proxy config
├── prisma/
│   ├── schema.prisma          # MySQL schema (production)
│   └── seed.ts                # Demo data seeder
├── public/
│   ├── isecurify-icon.png     # App icon/logo
│   └── robots.txt
├── src/
│   ├── app/
│   │   ├── api/               # All API routes (auth, controls, frameworks, etc.)
│   │   ├── layout.tsx         # Root layout
│   │   ├── page.tsx           # Main page (auth-gated)
│   │   └── globals.css        # Brand theme
│   ├── components/
│   │   ├── app/               # iSecurify components (AppShell, LoginPage, views)
│   │   └── ui/                # shadcn/ui components
│   ├── hooks/                 # Custom React hooks
│   └── lib/                   # Utilities (db, auth, stores, types)
├── .env.example               # Environment template
├── Dockerfile                 # 3-stage Docker build
├── docker-compose.yml         # Docker Compose (app + MySQL)
├── docker-entrypoint.sh       # Container startup script
├── next.config.ts             # Next.js config (standalone output)
├── package.json               # Dependencies and scripts
└── README.md                  # This file
```

---

## 📄 License

Proprietary — iSecurify GRC Platform. All rights reserved.