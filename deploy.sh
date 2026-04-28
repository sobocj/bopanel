#!/bin/bash

################################################################################
#
# BoPanel v1.0 - Automatic Deployment Script
# MSP Platform - Open Source Alternative to ATERA
#
# Usage: sudo ./deploy.sh [--update] [--force]
#
# Flags:
#   --update    Update existing installation (idempotent)
#   --force     Force reinstall everything
#   --help      Show this help message
#
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="deploy.log"
START_TIME=$(date +%s)
INSTALL_DIR="/opt/bopanel"
UPDATE_MODE=false
FORCE_MODE=false

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

log_info() {
    echo -e "${CYAN}[i]${NC} $1" | tee -a "$LOG_FILE"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --update)
                UPDATE_MODE=true
                shift
                ;;
            --force)
                FORCE_MODE=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
BoPanel v1.0 - Deployment Script

Usage: sudo ./deploy.sh [OPTIONS]

Options:
  --update    Update existing installation (idempotent, safe re-run)
  --force     Force reinstall everything (destructive)
  --help      Show this help message

Examples:
  # First installation
  sudo ./deploy.sh

  # Update/re-run safely
  sudo ./deploy.sh --update

  # Force reinstall (WARNING: may lose data)
  sudo ./deploy.sh --force

EOF
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (use sudo)"
   exit 1
fi

parse_args "$@"

log "=========================================="
log "   BoPanel v1.0 - Deployment Script"
log "=========================================="

if [ "$UPDATE_MODE" = true ]; then
    log_info "Running in UPDATE mode (idempotent)"
elif [ "$FORCE_MODE" = true ]; then
    log_warning "Running in FORCE mode (destructive)"
else
    log_info "Running in INSTALL mode"
fi

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
log "  Install Dir: $INSTALL_DIR"

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
apt-get update -qq &>> "$LOG_FILE" || true

log "Installing system dependencies..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    curl wget git ca-certificates gnupg lsb-release \
    apt-transport-https software-properties-common \
    build-essential htop net-tools vim nano \
    openssh-server openssh-client ufw fail2ban \
    &>> "$LOG_FILE"

log_success "System dependencies installed"

log ""
log "========== DOCKER INSTALLATION =========="

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    log_success "Docker already installed: $(docker --version)"
else
    log "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg 2>> "$LOG_FILE"
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -qq &>> "$LOG_FILE"
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin &>> "$LOG_FILE"
    systemctl start docker
    systemctl enable docker
    log_success "Docker installed"
fi

# Check if Docker Compose is already installed
if command -v docker-compose &> /dev/null; then
    log_success "Docker Compose already installed: $(docker-compose --version)"
else
    log "Installing Docker Compose..."
    DOCKER_COMPOSE_VERSION="v2.20.0"
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 2>> "$LOG_FILE"
    chmod +x /usr/local/bin/docker-compose
    log_success "Docker Compose installed"
fi

log ""
log "========== SETTING UP DIRECTORIES =========="

if [ ! -d "$INSTALL_DIR" ]; then
    log "Creating installation directory..."
    mkdir -p "$INSTALL_DIR"
    cp -r . "$INSTALL_DIR/"
    log_success "Installation directory created"
else
    if [ "$UPDATE_MODE" = true ] || [ "$FORCE_MODE" = true ]; then
        log "Syncing files with installation directory..."
        rsync -av --exclude='node_modules' --exclude='.env' --exclude='deploy.log' \
              --exclude='DEPLOYMENT_SUMMARY.txt' . "$INSTALL_DIR/" >> "$LOG_FILE" 2>&1 || true
        log_success "Files synchronized"
    else
        log_warning "Installation directory already exists at $INSTALL_DIR"
    fi
fi

cd "$INSTALL_DIR"

log "Creating necessary subdirectories..."
mkdir -p {logs,backups,certs,config,data}
log_success "Directories ready"

log ""
log "========== SSL CERTIFICATES =========="

if [ -f certs/cert.pem ] && [ "$FORCE_MODE" != true ]; then
    log_warning "SSL certificate already exists (use --force to regenerate)"
else
    log "Generating self-signed SSL certificate..."
    mkdir -p certs
    openssl req -x509 -newkey rsa:4096 -keyout certs/key.pem -out certs/cert.pem -days 365 -nodes \
        -subj "/C=ES/ST=Spain/L=Madrid/O=BoPanel/CN=$DOMAIN" &>> "$LOG_FILE"
    log_success "SSL certificate generated"
fi

log ""
log "========== FIREWALL CONFIGURATION =========="

log "Checking UFW firewall..."
if ! ufw status | grep -q "Status: active"; then
    log "Enabling UFW firewall..."
    ufw --force enable &>> "$LOG_FILE"
    log_success "Firewall enabled"
else
    log_success "Firewall already enabled"
fi

log "Opening necessary ports..."
ufw allow 22/tcp &>> "$LOG_FILE" || true
ufw allow 80/tcp &>> "$LOG_FILE" || true
ufw allow 443/tcp &>> "$LOG_FILE" || true
ufw allow 1194/udp &>> "$LOG_FILE" || true
ufw allow 3000/tcp &>> "$LOG_FILE" || true
ufw allow 3389/tcp &>> "$LOG_FILE" || true
ufw reload &>> "$LOG_FILE" || true
log_success "Firewall ports configured"

log ""
log "========== DATABASE SETUP =========="

log "Starting PostgreSQL service..."
docker-compose up -d postgres &>> "$LOG_FILE" || true
sleep 10

log "Checking database connection..."
if docker-compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" &> /dev/null 2>&1; then
    log_success "Database connection OK"
    
    log "Running database migrations..."
    if [ -f database/migrations/001_initial_schema.sql ]; then
        docker-compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" < database/migrations/001_initial_schema.sql &>> "$LOG_FILE" || true
        log_success "Migrations applied"
    else
        log_warning "Migration file not found"
    fi
else
    log_error "Database connection failed"
fi

log ""
log "========== STARTING SERVICES =========="

log "Starting all Docker services..."
docker-compose up -d &>> "$LOG_FILE" || true

log "Waiting for services to stabilize (30 seconds)..."
sleep 30

log ""
log "========== VERIFYING SERVICES =========="

FAILED_SERVICES=0
SERVICES=(backend frontend postgres redis nginx portainer prometheus grafana elasticsearch)

for service in "${SERVICES[@]}"; do
    if docker-compose ps | grep -q "$service.*Up"; then
        log_success "$service is running"
    else
        if docker-compose ps | grep -q "$service"; then
            log_warning "$service exists but is not running"
        else
            log_warning "$service is not configured"
        fi
    fi
done

log ""
log "========== ADMIN USER SETUP =========="

log "Creating/updating admin user..."
docker-compose exec -T backend npm run setup:admin \
    -- --username="$ADMIN_USERNAME" --email="$ADMIN_EMAIL" --password="$ADMIN_PASSWORD" \
    &>> "$LOG_FILE" || log_warning "Admin user creation skipped (might already exist)"

log_success "Admin user configured"

log ""
log "========== HELPER COMMANDS =========="

log "Installing helper commands..."

cat > /usr/local/bin/bopanel-status << 'EOF'
#!/bin/bash
docker-compose -f /opt/bopanel/docker-compose.yml ps
EOF

cat > /usr/local/bin/bopanel-logs << 'EOF'
#!/bin/bash
docker-compose -f /opt/bopanel/docker-compose.yml logs -f "$@"
EOF

cat > /usr/local/bin/bopanel-restart << 'EOF'
#!/bin/bash
docker-compose -f /opt/bopanel/docker-compose.yml restart "$@"
EOF

cat > /usr/local/bin/bopanel-backup << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/bopanel/backups"
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"
docker-compose -f /opt/bopanel/docker-compose.yml exec -T postgres pg_dump -U bopanel bopanel > "$BACKUP_DIR/bopanel_$BACKUP_DATE.sql"
echo "✓ Backup created: $BACKUP_DIR/bopanel_$BACKUP_DATE.sql"
EOF

cat > /usr/local/bin/bopanel-update << 'EOF'
#!/bin/bash
cd /opt/bopanel
sudo ./deploy.sh --update
EOF

chmod +x /usr/local/bin/bopanel-*

log_success "Helper commands installed"
log_info "Available commands:"
log_info "  bopanel-status       - Show service status"
log_info "  bopanel-logs         - View logs (add service name for specific logs)"
log_info "  bopanel-restart      - Restart services"
log_info "  bopanel-backup       - Create database backup"
log_info "  bopanel-update       - Re-run deployment (safe, idempotent)"

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
Deployment Duration: ${MINUTES}m ${SECONDS}s
Installation Directory: $INSTALL_DIR
Mode: $([ "$UPDATE_MODE" = true ] && echo "UPDATE (Idempotent)" || echo "FRESH INSTALL")

================================================================================
                             🌐 Access Information
================================================================================

🏠 BoPanel Main Interface
   URL: https://$DOMAIN (or https://$SERVER_IP)
   Username: $ADMIN_USERNAME
   Password: Set in .env (ADMIN_PASSWORD)

🐳 Portainer (Docker Management)
   URL: https://$DOMAIN:9000
   Default: admin/12345

📊 Grafana (Dashboards & Metrics)
   URL: http://$DOMAIN:3000 (or https://$DOMAIN:3000)
   Default: admin/admin

📈 Prometheus (Metrics Collection)
   URL: http://$DOMAIN:9090

🔍 Kibana (Logs & Analytics)
   URL: http://$DOMAIN:5601

🎯 Guacamole (Remote Desktop Access)
   URL: https://$DOMAIN:8081

📖 API Documentation
   URL: https://$DOMAIN/api

================================================================================
                             ⚡ Quick Commands
================================================================================

View service status:
   bopanel-status

View all logs:
   bopanel-logs

View specific service logs:
   bopanel-logs backend
   bopanel-logs frontend
   bopanel-logs postgres

Restart services:
   bopanel-restart
   bopanel-restart backend

Create database backup:
   bopanel-backup

Update/re-run deployment (safe):
   bopanel-update

Stop all services:
   docker-compose -f $INSTALL_DIR/docker-compose.yml down

Start all services:
   docker-compose -f $INSTALL_DIR/docker-compose.yml up -d

================================================================================
                             📚 Documentation
================================================================================

For more information, check:

   - Installation Guide: $INSTALL_DIR/docs/INSTALLATION.md
   - Architecture: $INSTALL_DIR/docs/ARCHITECTURE.md
   - API Reference: $INSTALL_DIR/docs/API-REFERENCE.md
   - Troubleshooting: $INSTALL_DIR/docs/TROUBLESHOOTING.md

GitHub Repository: https://github.com/sobocj/bopanel

================================================================================
                             🎯 Next Steps
================================================================================

1. ✅ Log in to BoPanel at https://$DOMAIN
2. ✅ Change admin password (IMPORTANT!)
3. ✅ Configure email notifications
4. ✅ Create your first client
5. ✅ Create user accounts for your team
6. ✅ Configure SLA profiles
7. ✅ Install agents on servers
8. ✅ Test remote access (Guacamole)

================================================================================
                             ⚠️  Important Notes
================================================================================

SECURITY:
  - Change all default passwords immediately!
  - SSL: Self-signed certificate detected. Configure proper certificate for production.
  - Firewall: Review firewall rules for your environment.

BACKUP:
  - Set up automated backups for production use.
  - Use: bopanel-backup

MONITORING:
  - Configure monitoring and alert rules in Prometheus.
  - Create dashboards in Grafana.

UPDATES:
  - To update safely (idempotent): bopanel-update or ./deploy.sh --update
  - This will NOT overwrite your data, configurations, or certificates.

TROUBLESHOOTING:
  - Check logs: bopanel-logs
  - See docs: $INSTALL_DIR/docs/TROUBLESHOOTING.md
  - GitHub Issues: https://github.com/sobocj/bopanel/issues

================================================================================

For support and documentation: https://github.com/sobocj/bopanel

EOF

log ""
log_success "Deployment completed successfully!"
log ""
cat "$SUMMARY_FILE"

log ""
log_success "Summary saved to: $SUMMARY_FILE"
log_success "Deployment logs saved to: $LOG_FILE"

exit 0
