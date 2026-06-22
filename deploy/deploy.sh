#!/bin/bash
# =============================================================
#  iSecurify GRC Platform — Deploy Script for Ubuntu Server
#  Run as root or with sudo:  sudo bash deploy.sh
# =============================================================
set -e

# ---- Configuration ----
APP_DIR="/opt/isecurify"
APP_USER="isecurify"
APP_DOMAIN="${1:-isecurify.yourdomain.com}"   # Pass domain as first argument

echo "============================================"
echo "  iSecurify GRC Platform — Deployment"
echo "============================================"
echo ""

# ---- Step 1: Install System Dependencies ----
echo "[1/8] Installing system dependencies..."
apt-get update -qq
apt-get install -y -qq curl git nginx certbot python3-certbot-nginx mysql-server mysql-client > /dev/null 2>&1
echo "       ✓ curl, git, nginx, certbot, mysql-client installed"

# ---- Step 2: Install Bun ----
echo "[2/8] Installing Bun runtime..."
if ! command -v bun &> /dev/null; then
    curl -fsSL https://bun.sh/install | bash
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi
echo "       ✓ Bun $(bun --version) installed"

# ---- Step 3: Create App User ----
echo "[3/8] Creating application user..."
if ! id "$APP_USER" &>/dev/null; then
    useradd -r -s /bin/bash -d "$APP_DIR" "$APP_USER"
fi
echo "       ✓ User '$APP_USER' ready"

# ---- Step 4: Setup MySQL Database ----
echo "[4/8] Setting up MySQL database..."
echo "       Enter MySQL root password when prompted:"
read -s -p "       MySQL root password: " MYSQL_ROOT_PASS
echo ""
MYSQL_DB="isecurify"
MYSQL_USER="isecurify"
MYSQL_PASS=$(openssl rand -base64 24 | tr -d '=/+' | head -c 24)

# Create database and user
mysql -u root -p"$MYSQL_ROOT_PASS" <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DB}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASS}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DB}\`.* TO '${MYSQL_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
echo "       ✓ Database '$MYSQL_DB' and user '$MYSQL_USER' created"

# ---- Step 5: Copy Application Files ----
echo "[5/8] Deploying application to $APP_DIR..."
mkdir -p "$APP_DIR"
cp -r . "$APP_DIR/" 2>/dev/null || {
    echo "       Copying from current directory..."
    # If running from within the project, copy source files
    rsync -a --exclude='node_modules' --exclude='.next' --exclude='.git' \
          --exclude='db/*.db' --exclude='dev.log' --exclude='upload' \
          --exclude='skills' --exclude='examples' --exclude='mini-services' \
          --exclude='.zscripts' --exclude='download' --exclude='tool-results' \
          . "$APP_DIR/"
}

# Ensure correct ownership
chown -R "$APP_USER:$APP_USER" "$APP_DIR"
echo "       ✓ Files deployed to $APP_DIR"

# ---- Step 6: Configure Environment ----
echo "[6/8] Configuring .env file..."
NEXTAUTH_SECRET=$(openssl rand -base64 32)
cat > "$APP_DIR/.env" <<ENVFILE
# ============================================================
#  iSecurify GRC Platform — Production Environment
# ============================================================

# ---- Database (MySQL) ----
DATABASE_URL="mysql://${MYSQL_USER}:${MYSQL_PASS}@localhost:3306/${MYSQL_DB}"

# ---- App ----
NEXTAUTH_SECRET="${NEXTAUTH_SECRET}"
NEXTAUTH_URL="https://${APP_DOMAIN}"
NEXT_PUBLIC_APP_URL="https://${APP_DOMAIN}"
NODE_ENV=production
PORT=3000
HOSTNAME=0.0.0.0

# ---- Uploads ----
UPLOAD_PATH=/opt/isecurify/uploads

# ---- Seed (set to "true" ONLY on first deploy) ----
SEED_DB=false
ENVFILE

chmod 600 "$APP_DIR/.env"
chown "$APP_USER:$APP_USER" "$APP_DIR/.env"
echo "       ✓ .env configured"

# ---- Step 7: Install Dependencies & Build ----
echo "[7/8] Installing dependencies and building..."
cd "$APP_DIR"

# Install dependencies as app user
su - "$APP_USER" -c "cd $APP_DIR && bun install" 2>&1 | tail -1

# Generate Prisma client
su - "$APP_USER" -c "cd $APP_DIR && bunx prisma generate" 2>&1 | tail -1

# Push schema to database
su - "$APP_USER" -c "cd $APP_DIR && bunx prisma db push --accept-data-loss 2>/dev/null || bunx prisma db push" 2>&1 | tail -1

# Build the application
su - "$APP_USER" -c "cd $APP_DIR && bun run build" 2>&1 | tail -3

echo "       ✓ Application built successfully"

# ---- Step 8: Configure Systemd & Nginx ----
echo "[8/8] Configuring system services..."

# Install systemd service
cp "$APP_DIR/deploy/isecurify.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable isecurify > /dev/null 2>&1
systemctl start isecurify
echo "       ✓ Systemd service 'isecurify' started"

# Install Nginx config
cp "$APP_DIR/deploy/nginx/isecurify.conf" /etc/nginx/sites-available/
sed -i "s/your-domain.com/${APP_DOMAIN}/g" /etc/nginx/sites-available/isecurify.conf
ln -sf /etc/nginx/sites-available/isecurify.conf /etc/nginx/sites-enabled/

# Remove default Nginx site if it conflicts
if [ -f /etc/nginx/sites-enabled/default ]; then
    rm -f /etc/nginx/sites-enabled/default
fi

nginx -t && systemctl reload nginx
echo "       ✓ Nginx configured for ${APP_DOMAIN}"

echo ""
echo "============================================"
echo "  ✅ Deployment Complete!"
echo "============================================"
echo ""
echo "  App URL:     https://${APP_DOMAIN}"
echo "  App running: systemctl status isecurify"
echo "  App logs:    journalctl -u isecurify -f"
echo ""
echo "  ⚠️  IMPORTANT: To get SSL certificate, run:"
echo "     sudo certbot --nginx -d ${APP_DOMAIN}"
echo ""
echo "  🔑 Default Login:"
echo "     Email:    admin@isecurify.com"
echo "     Password: Admin@123456"
echo "     (Change this immediately after first login!)"
echo ""
echo "  📋 To seed demo data on first deploy:"
echo "     1. Edit /opt/isecurify/.env"
echo "     2. Set SEED_DB=true"
echo "     3. sudo systemctl restart isecurify"
echo "     4. Set SEED_DB=false after seeding completes"
echo ""