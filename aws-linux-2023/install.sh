#!/bin/bash

# AWS Linux 2023 - Web Application Setup Script
# This script installs PHP, Nginx, MySQL, Supervisor, NVM, Node, Yarn, PM2

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root (use sudo)"
    exit 1
fi

# Variables
INSTALL_PHP=false
INSTALL_NGINX=false
INSTALL_MYSQL=false
INSTALL_SUPERVISOR=false
INSTALL_NVM=false
MYSQL_ROOT_PASSWORD=""
MYSQL_DB_NAME=""
MYSQL_DB_USER=""
MYSQL_DB_PASSWORD=""
PHP_VERSION=""
NODE_VERSION=""

# Function to display menu
show_menu() {
    clear
    echo "=========================================="
    echo "  AWS Linux 2023 - Web App Setup"
    echo "=========================================="
    echo ""
    echo "Select services to install:"
    echo ""
    echo "1. PHP + Nginx + PHP-FPM + Composer"
    echo "2. MySQL"
    echo "3. Supervisor"
    echo "4. Nginx + NVM + Node + Yarn + PM2"
    echo "5. Install All"
    echo "6. Start Installation"
    echo "0. Exit"
    echo ""
}

# Function to toggle selection
toggle_service() {
    case $1 in
        1)
            INSTALL_PHP=true
            INSTALL_NGINX=true
            log_info "Selected: PHP + Nginx + PHP-FPM + Composer"
            ;;
        2)
            INSTALL_MYSQL=true
            log_info "Selected: MySQL"
            ;;
        3)
            INSTALL_SUPERVISOR=true
            log_info "Selected: Supervisor"
            ;;
        4)
            INSTALL_NGINX=true
            INSTALL_NVM=true
            log_info "Selected: Nginx + NVM + Node + Yarn + PM2"
            ;;
        5)
            INSTALL_PHP=true
            INSTALL_NGINX=true
            INSTALL_MYSQL=true
            INSTALL_SUPERVISOR=true
            INSTALL_NVM=true
            log_info "Selected: All services"
            ;;
    esac
}

# Interactive menu
while true; do
    show_menu

    echo "Current selections:"
    [ "$INSTALL_PHP" = true ] && echo "  ✓ PHP + Nginx + PHP-FPM + Composer"
    [ "$INSTALL_NGINX" = true ] && [ "$INSTALL_PHP" = false ] && echo "  ✓ Nginx"
    [ "$INSTALL_MYSQL" = true ] && echo "  ✓ MySQL"
    [ "$INSTALL_SUPERVISOR" = true ] && echo "  ✓ Supervisor"
    [ "$INSTALL_NVM" = true ] && echo "  ✓ NVM + Node + Yarn + PM2"
    echo ""

    read -p "Enter your choice: " choice

    case $choice in
        0)
            log_info "Exiting..."
            exit 0
            ;;
        1|2|3|4|5)
            toggle_service $choice
            sleep 1
            ;;
        6)
            break
            ;;
        *)
            log_error "Invalid option"
            sleep 1
            ;;
    esac
done

# Check if any service is selected
if [ "$INSTALL_PHP" = false ] && [ "$INSTALL_MYSQL" = false ] && [ "$INSTALL_SUPERVISOR" = false ] && [ "$INSTALL_NVM" = false ]; then
    log_error "No services selected. Exiting..."
    exit 1
fi

# PHP version selection if selected
if [ "$INSTALL_PHP" = true ]; then
    echo ""
    log_info "PHP Version Selection"
    echo "Available PHP versions:"
    echo "1. PHP 8.1"
    echo "2. PHP 8.2 (recommended)"
    echo "3. PHP 8.3"
    read -p "Select PHP version (1-3) [default: 2]: " php_choice

    case ${php_choice:-2} in
        1)
            PHP_VERSION="8.1"
            ;;
        2)
            PHP_VERSION="8.2"
            ;;
        3)
            PHP_VERSION="8.3"
            ;;
        *)
            PHP_VERSION="8.2"
            ;;
    esac
    log_info "Selected PHP $PHP_VERSION"
fi

# Node version selection if selected
if [ "$INSTALL_NVM" = true ]; then
    echo ""
    log_info "Node.js Version Selection"
    echo "Available Node.js versions:"
    echo "1. Node LTS (Latest Long Term Support)"
    echo "2. Node 18.x LTS"
    echo "3. Node 20.x LTS"
    echo "4. Node 22.x (Latest)"
    read -p "Select Node version (1-4) [default: 1]: " node_choice

    case ${node_choice:-1} in
        1)
            NODE_VERSION="--lts"
            ;;
        2)
            NODE_VERSION="18"
            ;;
        3)
            NODE_VERSION="20"
            ;;
        4)
            NODE_VERSION="22"
            ;;
        *)
            NODE_VERSION="--lts"
            ;;
    esac
    log_info "Selected Node.js version: ${NODE_VERSION}"
fi

# MySQL configuration if selected
if [ "$INSTALL_MYSQL" = true ]; then
    echo ""
    log_info "MySQL Configuration"
    read -sp "Enter MySQL root password: " MYSQL_ROOT_PASSWORD
    echo ""
    read -sp "Confirm MySQL root password: " MYSQL_ROOT_PASSWORD_CONFIRM
    echo ""

    if [ "$MYSQL_ROOT_PASSWORD" != "$MYSQL_ROOT_PASSWORD_CONFIRM" ]; then
        log_error "Passwords do not match"
        exit 1
    fi

    read -p "Enter database name: " MYSQL_DB_NAME
    read -p "Enter database user: " MYSQL_DB_USER
    read -sp "Enter database user password: " MYSQL_DB_PASSWORD
    echo ""
fi

log_info "Starting installation..."

# Update system
log_info "Updating system packages..."
dnf update -y

# Install Nginx (standalone or with PHP)
if [ "$INSTALL_NGINX" = true ] && [ "$INSTALL_PHP" = false ]; then
    log_info "Installing Nginx..."
    dnf install -y nginx

    # Start and enable Nginx
    systemctl start nginx
    systemctl enable nginx

    log_info "Nginx $(nginx -v 2>&1 | cut -d '/' -f 2) installed"
fi

# Install PHP + Nginx + PHP-FPM + Composer
if [ "$INSTALL_PHP" = true ]; then
    log_info "Installing PHP, Nginx, PHP-FPM, and Composer..."

    # Install PHP and extensions
    log_info "Installing PHP $PHP_VERSION..."
    dnf install -y php${PHP_VERSION} php${PHP_VERSION}-fpm php${PHP_VERSION}-cli \
        php${PHP_VERSION}-mysqlnd php${PHP_VERSION}-pdo php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-xml php${PHP_VERSION}-gd php${PHP_VERSION}-zip \
        php${PHP_VERSION}-opcache php${PHP_VERSION}-intl php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-process php${PHP_VERSION}-common php${PHP_VERSION}-sodium

    # Install Nginx
    dnf install -y nginx

    # Configure PHP-FPM
    sed -i 's/user = apache/user = nginx/' /etc/php-fpm.d/www.conf
    sed -i 's/group = apache/group = nginx/' /etc/php-fpm.d/www.conf

    # Start and enable services
    systemctl start php-fpm
    systemctl enable php-fpm
    systemctl start nginx
    systemctl enable nginx

    # Install Composer
    log_info "Installing Composer..."
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    chmod +x /usr/local/bin/composer

    log_info "PHP $(php -v | head -n 1 | cut -d ' ' -f 2) installed"
    log_info "Nginx $(nginx -v 2>&1 | cut -d '/' -f 2) installed"
    log_info "Composer $(composer --version | cut -d ' ' -f 3) installed"
fi

# Install MySQL
if [ "$INSTALL_MYSQL" = true ]; then
    log_info "Installing MySQL..."

    # Add MySQL repository
    log_info "Adding MySQL repository..."
    dnf install -y https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm

    # Import MySQL GPG key
    rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023

    # Install MySQL 8.0
    dnf install -y mysql-community-server

    # Start MySQL
    systemctl start mysqld
    systemctl enable mysqld

    # Wait for MySQL to start
    sleep 5

    # Get temporary root password
    TEMP_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log 2>/dev/null | tail -1 | awk '{print $NF}')

    # Secure MySQL installation
    log_info "Configuring MySQL..."

    if [ -n "$TEMP_PASSWORD" ]; then
        log_info "Found temporary password, changing root password..."

        # Change root password using temporary password
        mysql --connect-expired-password -u root -p"${TEMP_PASSWORD}" <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
    else
        log_warn "No temporary password found, trying to set password directly..."
        # Try without password first (fresh install or already configured)
        mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;" 2>/dev/null || \
        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;"
    fi

    # Remove anonymous users
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
DELETE FROM mysql.user WHERE User='';
FLUSH PRIVILEGES;
EOF

    # Disallow root login remotely
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
FLUSH PRIVILEGES;
EOF

    # Remove test database
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

    # Create database and user
    if [ -n "$MYSQL_DB_NAME" ] && [ -n "$MYSQL_DB_USER" ] && [ -n "$MYSQL_DB_PASSWORD" ]; then
        log_info "Creating database: $MYSQL_DB_NAME"
        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_DB_USER}'@'localhost' IDENTIFIED BY '${MYSQL_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DB_NAME}.* TO '${MYSQL_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
        log_info "Database and user created successfully"
    fi

    log_info "MySQL $(mysql --version | cut -d ' ' -f 6 | cut -d ',' -f 1) installed"
fi

# Install Supervisor
if [ "$INSTALL_SUPERVISOR" = true ]; then
    log_info "Installing Supervisor..."

    # Install Python and pip if not already installed
    dnf install -y python3 python3-pip

    # Install supervisor via pip
    pip3 install supervisor

    # Create supervisor directories
    mkdir -p /etc/supervisor/conf.d
    mkdir -p /var/log/supervisor

    # Create supervisor config file
    cat > /etc/supervisord.conf <<'SUPERVISOR_EOF'
[unix_http_server]
file=/var/run/supervisor.sock
chmod=0700

[supervisord]
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid
childlogdir=/var/log/supervisor
nodaemon=false

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[include]
files = /etc/supervisor/conf.d/*.conf
SUPERVISOR_EOF

    # Create systemd service file for supervisor
    cat > /etc/systemd/system/supervisord.service <<'SERVICE_EOF'
[Unit]
Description=Supervisor process control system for UNIX
Documentation=http://supervisord.org
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/bin/supervisord -c /etc/supervisord.conf
ExecStop=/usr/local/bin/supervisorctl shutdown
ExecReload=/usr/local/bin/supervisorctl reload
KillMode=process
Restart=on-failure
RestartSec=50s

[Install]
WantedBy=multi-user.target
SERVICE_EOF

    # Reload systemd
    systemctl daemon-reload

    # Start and enable Supervisor
    systemctl start supervisord
    systemctl enable supervisord

    log_info "Supervisor $(supervisord -v) installed"
fi

# Install NVM + Node + Yarn + PM2
if [ "$INSTALL_NVM" = true ]; then
    log_info "Installing NVM, Node, Yarn, and PM2..."

    # Get the actual user (not root)
    ACTUAL_USER=${SUDO_USER:-$USER}
    ACTUAL_HOME=$(eval echo ~$ACTUAL_USER)

    # Install NVM
    log_info "Installing NVM..."
    su - $ACTUAL_USER -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"

    # Wait a moment for NVM to be ready
    sleep 2

    # Load NVM and install Node
    log_info "Installing Node.js ${NODE_VERSION}..."
    echo "This may take a few minutes..."

    su - $ACTUAL_USER bash -c "
        export NVM_DIR=\"$ACTUAL_HOME/.nvm\"
        [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"

        echo \"==> Loading NVM...\"
        nvm --version || { echo \"ERROR: NVM not loaded properly\"; exit 1; }

        echo \"==> Installing Node.js ${NODE_VERSION}...\"
        nvm install ${NODE_VERSION}

        echo \"==> Setting default Node version...\"
        nvm use ${NODE_VERSION}
        nvm alias default ${NODE_VERSION}

        echo \"==> Verifying Node installation...\"
        node --version
        npm --version
    "

    if [ $? -ne 0 ]; then
        log_error "Failed to install Node.js"
        exit 1
    fi

    # Install Yarn
    log_info "Installing Yarn..."
    su - $ACTUAL_USER bash -c "
        export NVM_DIR=\"$ACTUAL_HOME/.nvm\"
        [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
        npm install -g yarn
    "

    # Install PM2
    log_info "Installing PM2..."
    su - $ACTUAL_USER bash -c "
        export NVM_DIR=\"$ACTUAL_HOME/.nvm\"
        [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
        npm install -g pm2
    "

    # Setup PM2 to start on boot
    log_info "Setting up PM2 startup..."
    su - $ACTUAL_USER bash -c "
        export NVM_DIR=\"$ACTUAL_HOME/.nvm\"
        [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
        pm2 startup systemd -u $ACTUAL_USER --hp $ACTUAL_HOME
    " | grep '^sudo env' | sh || true

    log_info "NVM, Node.js, Yarn, and PM2 installed for user: $ACTUAL_USER"

    # Display installed versions
    NODE_VER=$(su - $ACTUAL_USER bash -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && node --version' 2>/dev/null || echo "N/A")
    YARN_VER=$(su - $ACTUAL_USER bash -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && yarn --version' 2>/dev/null || echo "N/A")
    PM2_VER=$(su - $ACTUAL_USER bash -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && pm2 --version' 2>/dev/null || echo "N/A")

    log_info "Node.js $NODE_VER installed"
    log_info "Yarn $YARN_VER installed"
    log_info "PM2 $PM2_VER installed"
fi

# Summary
echo ""
echo "=========================================="
log_info "Installation completed successfully!"
echo "=========================================="
echo ""

if [ "$INSTALL_PHP" = true ]; then
    echo "PHP + Nginx + PHP-FPM + Composer:"
    echo "  - PHP version: $(php -v | head -n 1 | cut -d ' ' -f 2)"
    echo "  - Nginx config: /etc/nginx/nginx.conf"
    echo "  - PHP-FPM config: /etc/php-fpm.d/www.conf"
    echo "  - Web root: /usr/share/nginx/html"
fi

if [ "$INSTALL_NGINX" = true ] && [ "$INSTALL_PHP" = false ]; then
    echo "Nginx:"
    echo "  - Version: $(nginx -v 2>&1 | cut -d '/' -f 2)"
    echo "  - Config: /etc/nginx/nginx.conf"
    echo "  - Web root: /usr/share/nginx/html"
fi

if [ "$INSTALL_MYSQL" = true ]; then
    echo ""
    echo "MySQL:"
    echo "  - Version: $(mysql --version | cut -d ' ' -f 6 | cut -d ',' -f 1)"
    echo "  - Root password: [hidden]"
    if [ -n "$MYSQL_DB_NAME" ]; then
        echo "  - Database: $MYSQL_DB_NAME"
        echo "  - User: $MYSQL_DB_USER"
    fi
fi

if [ "$INSTALL_SUPERVISOR" = true ]; then
    echo ""
    echo "Supervisor:"
    echo "  - Version: $(supervisord -v)"
    echo "  - Config: /etc/supervisord.conf"
    echo "  - Program configs: /etc/supervisor/conf.d/"
fi

if [ "$INSTALL_NVM" = true ]; then
    echo ""
    echo "NVM + Node + Yarn + PM2:"
    echo "  - Installed for user: $ACTUAL_USER"
    echo "  - Node version: $NODE_VER"
    echo "  - Yarn version: $YARN_VER"
    echo "  - PM2 version: $PM2_VER"
    echo ""
    echo "  To use Node/NPM/Yarn/PM2, run as user $ACTUAL_USER:"
    echo "    su - $ACTUAL_USER"
    echo "  Or load NVM in current shell:"
    echo "    export NVM_DIR=\"/home/$ACTUAL_USER/.nvm\""
    echo "    [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\""
fi

echo ""
log_info "All services are running and enabled to start on boot"
echo ""
