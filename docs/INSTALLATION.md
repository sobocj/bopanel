# BoPanel v1.0 Installation Guide

## Prerequisites

- Ubuntu Server 22.04 LTS or later
- 4GB RAM minimum (8GB recommended)
- 20GB disk space minimum
- Docker & Docker Compose installed (script handles this)
- Internet connection

## Quick Installation (Recommended)

### Step 1: Clone the Repository

```bash
git clone https://github.com/sobocj/bopanel.git
cd bopanel
```

### Step 2: Configure Environment

```bash
# Copy template
cp .env.example .env

# Edit configuration
sudo nano .env

# Change these values:
# - DOMAIN: Your IP address or domain
# - SERVER_IP: Your server IP address
# - All "ChangeMe_" passwords to strong, unique values
# - SMTP settings for email notifications

# Save: Ctrl+O, Enter, Ctrl+X
```

### Step 3: Run Deployment Script

```bash
# Make script executable
sudo chmod +x deploy.sh

# Run deployment
sudo ./deploy.sh

# The script will:
# - Check system requirements
# - Install Docker & Docker Compose
# - Generate SSL certificates
# - Configure firewall
# - Initialize database
# - Start all services
# - Create admin user
# ⏱️ This takes 35-40 minutes
```

### Step 4: Access BoPanel

After deployment completes, open your browser:

```
🏠 Main Interface
   https://your-ip-or-domain
   
   Username: admin
   Password: (from your .env ADMIN_PASSWORD)
```

## Available Services

After successful deployment, you can access:

| Service | URL | Purpose |
|---------|-----|---------|
| BoPanel Web | https://your-ip:443 | Main application |
| Portainer | https://your-ip:9000 | Docker management |
| Grafana | https://your-ip:3000 | Dashboards |
| Prometheus | http://your-ip:9090 | Metrics collection |
| Guacamole | https://your-ip:8081 | Remote desktop access |
| Kibana | https://your-ip:5601 | Log visualization |
| API Docs | https://your-ip/api/docs | API documentation |

## Manual Step-by-Step Installation

If you prefer manual installation or debugging:

### 1. Install System Dependencies

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git docker.io docker-compose postgresql-client
```

### 2. Install Docker

```bash
# Add Docker repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker
```

### 3. Install Docker Compose

```bash
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 4. Clone Repository

```bash
git clone https://github.com/sobocj/bopanel.git
cd bopanel
cp .env.example .env
```

### 5. Edit Configuration

```bash
sudo nano .env
# Configure your settings
```

### 6. Create Directories

```bash
mkdir -p logs backups certs config
```

### 7. Generate SSL Certificate

```bash
openssl req -x509 -newkey rsa:4096 -keyout certs/key.pem -out certs/cert.pem -days 365 -nodes \
  -subj "/C=ES/ST=Spain/L=Madrid/O=BoPanel/CN=your-domain.com"
```

### 8. Start Services

```bash
docker-compose up -d
```

### 9: Verify Services

```bash
docker-compose ps

# Should show all services as "Up"
```

### 10: Initialize Database

```bash
# Wait for postgres to be ready (30 seconds)
sleep 30

# Run migrations
docker-compose exec postgres psql -U bopanel -d bopanel < database/migrations/001_initial_schema.sql

# Create admin user
docker-compose exec backend npm run setup:admin
```

## Troubleshooting

### Services not starting?

```bash
# Check logs
docker-compose logs -f

# Check specific service
docker-compose logs backend
docker-compose logs postgres

# Restart services
docker-compose restart
```

### Database connection failed?

```bash
# Check postgres container
docker-compose ps postgres

# Connect to postgres manually
docker-compose exec postgres psql -U bopanel -d bopanel

# Run migrations manually
docker-compose exec postgres psql -U bopanel -d bopanel < database/migrations/001_initial_schema.sql
```

### Port already in use?

```bash
# Check what's using the port
sudo lsof -i :443
sudo lsof -i :3000

# Change ports in docker-compose.yml or .env
```

### Firewall blocking connections?

```bash
# Enable firewall
sudo ufw enable

# Open required ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 3000/tcp  # Backend
sudo ufw allow 1194/udp  # OpenVPN
sudo ufw reload
```

## Post-Installation Tasks

1. **Change Admin Password**
   - Login at https://your-ip
   - Go to Settings → Change Password
   - Use a strong password

2. **Configure Email Notifications**
   - Settings → Notifications → Email
   - Enter your SMTP credentials
   - Test email delivery

3. **Create First Client**
   ```bash
   bopanel-create-client "My Company Name"
   ```

4. **Add Team Members**
   ```bash
   bopanel-create-user "technician1" --role technician
   bopanel-create-user "support1" --role support
   ```

5. **Configure SLA Profiles**
   - Go to Settings → SLA Profiles
   - Create profiles for your clients

6. **Install Monitoring Agent**
   - On your servers: Run agent installation script
   - Agents report metrics to BoPanel

7. **Setup Alerts**
   - Configure alert thresholds in Prometheus
   - Set notification channels

## Updating BoPanel

```bash
# Pull latest changes
cd /opt/bopanel
git pull origin main

# Rebuild images
docker-compose build

# Restart services
docker-compose up -d
```

## Backup & Recovery

### Create Backup

```bash
bopanel-backup

# Or manually:
docker-compose exec postgres pg_dump -U bopanel bopanel > backup.sql
```

### Restore Backup

```bash
# Stop services
docker-compose down

# Restore database
docker-compose up -d postgres
sleep 10
docker-compose exec postgres psql -U bopanel bopanel < backup.sql

# Restart all services
docker-compose up -d
```

## Uninstall

```bash
# Stop all services
docker-compose down -v

# Remove installation directory
sudo rm -rf /opt/bopanel

# Clean up Docker
docker system prune -a
```

## Support

For issues or questions:
- Check [Troubleshooting Guide](./TROUBLESHOOTING.md)
- Review logs: `docker-compose logs -f`
- GitHub Issues: https://github.com/sobocj/bopanel/issues

## Next Steps

1. Read [Architecture Guide](./ARCHITECTURE.md)
2. Review [API Documentation](./API-REFERENCE.md)
3. Setup [Monitoring](./MONITORING-GUIDE.md)
4. Configure [Remote Access](./REMOTE-ACCESS-GUIDE.md)
