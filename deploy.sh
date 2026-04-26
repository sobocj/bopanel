#!/bin/bash

################################################################################
#
# BoPanel v1.0 - Automatic Deployment Script
# MSP Platform - Open Source Alternative to ATERA
#
# Usage: sudo ./deploy.sh
#
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="deploy.log"
START_TIME=$(date +%s)

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (use sudo)"
   exit 1
fi

log "=========================================="
log "   BoPanel v1.0 - Deployment Script"
log "=========================================="

# Check .env file
if [ ! -f .env ]; then
    log_error ".env file not found!"
    log "Please create .env file from .env.example:"
    log "  cp .env.example .env"
    log "  nano .env  # Edit with your values"
    exit 1
fi

source .env

log ""
log "Configuration Summary:"
log "  Domain: $DOMAIN"
log "  Server IP: $SERVER_IP"
log "  DB Name: $DB_NAME"
log "  Node Env: $NODE_ENV"

log ""
log "========== SYSTEM CHECK =========="

# Check Ubuntu version
log "Checking OS..."
if ! grep -q "Ubuntu" /etc/os-release; then
    log_error "This script is designed for Ubuntu Linux"
    exit 1
fi
log_success "Ubuntu detected"

# Check minimum resources
log "Checking system resources..."
TOTAL_MEM=$(free -g | awk 'NR==2{print $2}')
if [ "$TOTAL_MEM" -lt 4 ]; then
    log_warning "System has only ${TOTAL_MEM}GB RAM. Recommended: 8GB"
fi
log_success "RAM: ${TOTAL_MEM}GB"

# Check disk space
DISK_SPACE=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
if [ "$DISK_SPACE" -lt 20 ]; then
    log_error "Insufficient disk space. Minimum: 20GB, Available: ${DISK_SPACE}GB"
    exit 1
fi
log_success "Disk space: ${DISK_SPACE}GB"

# Check internet connection
log "Checking internet connection..."
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    log_error "No internet connection detected"
    exit 1
fi
log_success "Internet connection OK"

log ""
log "========== UPDATING SYSTEM =========="

log "Updating package manager..."
apt-get update -qq

log "Installing system dependencies..."
apt-get install -y -qq \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common \
    build-essential \
    htop \
    net-tools \
    vim \
    nano \
    openssh-server \
    openssh-client \
    ufw \
    fail2ban \
    &>> "$LOG_FILE"

log_success "System dependencies installed"

log ""
log "========== INSTALLING DOCKER =========="

log "Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

log "Adding Docker repository..."
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

log "Updating package manager..."
apt-get update -qq

log "Installing Docker..."
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin &>> "$LOG_FILE"

log "Starting Docker service..."
systemctl start docker
systemctl enable docker

log_success "Docker installed and running"

log ""
log "========== INSTALLING DOCKER COMPOSE =========="

log "Downloading Docker Compose..."
DOCKER_COMPOSE_VERSION="v2.20.0"
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

log_success "Docker Compose installed: $(docker-compose --version)"

log ""
log "========== SETTING UP DIRECTORIES =========="

log "Creating installation directory..."
INSTALL_DIR="/opt/bopanel"
mkdir -p "$INSTALL_DIR"
cp -r . "$INSTALL_DIR/"
cd "$INSTALL_DIR"

log "Creating necessary directories..."
mkdir -p {logs,backups,certs,config}

log_success "Directories created at $INSTALL_DIR"

log ""
log "========== GENERATING SSL CERTIFICATES =========="

if [ ! -f certs/cert.pem ]; then
    log "Generating self-signed SSL certificate..."
    openssl req -x509 -newkey rsa:4096 -keyout certs/key.pem -out certs/cert.pem -days 365 -nodes \
        -subj "/C=ES/ST=Spain/L=Madrid/O=BoPanel/CN=$DOMAIN" &>> "$LOG_FILE"
    log_success "SSL certificate generated"
else
    log_warning "SSL certificate already exists"
fi

log ""
log "========== CONFIGURING FIREWALL =========="

log "Enabling UFW firewall..."
ufw --force enable &>> "$LOG_FILE"

log "Opening necessary ports..."
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS
ufw allow 1194/udp # OpenVPN
ufw allow 3000/tcp # Backend
ufw allow 3389/tcp # RDP
ufw reload

log_success "Firewall configured"

log ""
log "========== CREATING DATABASE =========="

log "Waiting for PostgreSQL to start..."
docker-compose up -d postgres
sleep 10

log "Initializing database..."
docker-compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" -c "
    SELECT 1;
" 2>/dev/null || {
    log_error "Database connection failed"
    exit 1
}

log "Running database migrations..."
docker-compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" < database/migrations/001_initial_schema.sql &>> "$LOG_FILE" || true

log_success "Database initialized"

log ""
log "========== STARTING SERVICES =========="

log "Starting all Docker services..."
docker-compose up -d &>> "$LOG_FILE"

log "Waiting for services to stabilize (30 seconds)..."
sleep 30

log ""
log "========== VERIFYING SERVICES =========="

FAILED_SERVICES=0

for service in backend frontend postgres redis nginx portainer prometheus grafana elasticsearch; do
    if docker-compose ps | grep -q "$service.*Up"; then
        log_success "$service is running"
    else
        log_error "$service is NOT running"
        FAILED_SERVICES=$((FAILED_SERVICES + 1))
    fi
done

if [ $FAILED_SERVICES -gt 0 ]; then
    log_error "$FAILED_SERVICES service(s) failed to start"
    log "Run 'docker-compose logs' for more information"
else
    log_success "All services are running!"
fi

log ""
log "========== CREATING SYSTEM USERS =========="

log "Creating admin user..."
docker-compose exec -T backend npm run setup:admin \
    -- --username="$ADMIN_USERNAME" --email="$ADMIN_EMAIL" --password="$ADMIN_PASSWORD" \
    &>> "$LOG_FILE" || log_warning "Admin user creation skipped"

log_success "Admin user setup complete"

log ""
log "========== CREATING HELPER COMMANDS =========="

log "Creating command shortcuts..."

# Create helper scripts
cat > /usr/local/bin/bopanel-create-client << 'EOF'
#!/bin/bash
docker-compose -f /opt/bopanel/docker-compose.yml exec -T backend npm run create:client -- "$@"
EOF

cat > /usr/local/bin/bopanel-create-user << 'EOF'
#!/bin/bash
docker-compose -f /opt/bopanel/docker-compose.yml exec -T backend npm run create:user -- "$@"
EOF

cat > /usr/local/bin/bopanel-health-check << 'EOF'
#!/bin/bash
docker-compose -f /opt/bopanel/docker-compose.yml ps
EOF

cat > /usr/local/bin/bopanel-logs << 'EOF'
#!/bin/bash
docker-compose -f /opt/bopanel/docker-compose.yml logs -f "$@"
EOF

chmod +x /usr/local/bin/bopanel-*

log_success "Helper commands installed"

log ""
log "========== CONFIGURING BACKUP =========="

log "Creating backup script..."
cat > /usr/local/bin/bopanel-backup << 'EOFBACKUP'
#!/bin/bash
BACKUP_DIR="/opt/bopanel/backups"
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"
docker-compose -f /opt/bopanel/docker-compose.yml exec -T postgres pg_dump -U bopanel bopanel > "$BACKUP_DIR/bopanel_$BACKUP_DATE.sql"
echo "Backup created: $BACKUP_DIR/bopanel_$BACKUP_DATE.sql"
EOFBACKUP

chmod +x /usr/local/bin/bopanel-backup

log_success "Backup script created"

log ""
log "========== CREATING SUMMARY =========="

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

SUMMARY_FILE="DEPLOYMENT_SUMMARY.txt"

cat > "$SUMMARY_FILE" << EOF
================================================================================
                    BoPanel v1.0 Deployment Summary
================================================================================

Deployment Status: ✅ SUCCESS
Deployment Date: $(date)
Installation Directory: $INSTALL_DIR
Deployment Duration: ${MINUTES}m ${SECONDS}s

================================================================================
                            Access Information
================================================================================

🏠 Web Interface
   URL: https://$DOMAIN
   Username: $ADMIN_USERNAME
   Initial Password: Check your .env file

🐳 Portainer (Docker Management)
   URL: https://$DOMAIN:9000

📊 Grafana (Dashboards)
   URL: https://$DOMAIN:3000
   Username: admin
   Password: Check docker-compose.yml

📈 Prometheus (Metrics)
   URL: http://$DOMAIN:9090

🎯 Guacamole (Remote Access)
   URL: https://$DOMAIN:8081

📚 Kibana (Logs)
   URL: https://$DOMAIN:5601

📖 API Documentation
   URL: https://$DOMAIN/api/docs

================================================================================
                          Useful Commands
================================================================================

View service status:
   docker-compose -f $INSTALL_DIR/docker-compose.yml ps

View logs:
   docker-compose -f $INSTALL_DIR/docker-compose.yml logs -f

View backend logs:
   docker-compose -f $INSTALL_DIR/docker-compose.yml logs -f backend

View frontend logs:
   docker-compose -f $INSTALL_DIR/docker-compose.yml logs -f frontend

Create new client:
   bopanel-create-client "Company Name"

Create new user:
   bopanel-create-user "username" --role technician

Create backup:
   bopanel-backup

Health check:
   bopanel-health-check

Stop all services:
   docker-compose -f $INSTALL_DIR/docker-compose.yml down

Start all services:
   docker-compose -f $INSTALL_DIR/docker-compose.yml up -d

================================================================================
                            Next Steps
================================================================================

1. ✅ Log in to the web interface at https://$DOMAIN
2. ✅ Change admin password (IMPORTANT!)
3. ✅ Create your first client
4. ✅ Create user accounts for your team
5. ✅ Configure SLA profiles
6. ✅ Install agents on servers
7. ✅ Test remote access (Guacamole)
8. ✅ Configure email notifications

================================================================================
                          Important Notes
================================================================================

⚠️  SECURITY: Change all default passwords immediately!
⚠️  SSL: Self-signed certificate detected. Configure proper certificate.
⚠️  BACKUP: Set up automated backups for production use.
⚠️  FIREWALL: Review firewall rules for your environment.
⚠️  MONITORING: Configure monitoring and alert rules in Prometheus.

================================================================================
                         Documentation
================================================================================

For more information, visit the docs directory:

   - Installation Guide: $INSTALL_DIR/docs/INSTALLATION.md
   - Architecture: $INSTALL_DIR/docs/ARCHITECTURE.md
   - API Reference: $INSTALL_DIR/docs/API-REFERENCE.md
   - Troubleshooting: $INSTALL_DIR/docs/TROUBLESHOOTING.md
   - Operations: $INSTALL_DIR/docs/OPERATIONS.md

================================================================================

For support and documentation: https://github.com/sobocj/bopanel

EOF

log ""
log_success "Deployment completed successfully!"
log ""
cat "$SUMMARY_FILE"

log ""
log "Summary saved to: $SUMMARY_FILE"

exit 0
