# BoPanel v1.0 - Open Source MSP Platform

**BoPanel** es una plataforma de gestión de servicios profesionales (MSP) tipo ATERA, de código abierto y totalmente gratuita.

## 🎯 ¿Qué es BoPanel?

BoPanel es un sistema integral para MSPs que incluye:

- **🎫 Ticketing System** - Gestión de incidentes y solicitudes
- **⏱️ Time Tracking** - Control de horas y productividad
- **📊 Monitoring & RMM** - Monitoreo en tiempo real de servidores
- **🎯 SLA Management** - Seguimiento de acuerdos de nivel de servicio
- **🌐 Remote Access** - Acceso remoto seguro (RDP, SSH, VNC via Guacamole)
- **🐳 Docker Management** - Gestión de contenedores via Portainer
- **📈 Analytics & Reports** - Reportes y análisis de negocio
- **👥 Multi-tenant** - Soporte para múltiples clientes
- **🔐 RBAC** - Control de acceso basado en roles
- **🔔 Notifications** - Email, SMS, Slack integrados

## 🚀 Quick Start

### Requisitos
- Ubuntu Server 22.04 LTS o superior
- 4GB RAM mínimo (8GB recomendado)
- 20GB disco duro
- Conexión a internet

### Instalación Rápida

```bash
# 1. Clonar repositorio
git clone https://github.com/sobocj/bopanel.git
cd bopanel

# 2. Copiar configuración
cp .env.example .env

# 3. Editar configuración
sudo nano .env
# Cambiar DOMAIN, SERVER_IP y contraseñas

# 4. Ejecutar despliegue
sudo chmod +x deploy.sh
sudo ./deploy.sh

# ⏱️ Espera 35-40 minutos
# ✅ TODO funciona automáticamente
```

## 📚 Documentación

- [📖 Guía de Instalación](docs/INSTALLATION.md)
- [🏗️ Arquitectura Técnica](docs/ARCHITECTURE.md)
- [📡 Referencia API](docs/API-REFERENCE.md)
- [🎫 Guía de Ticketing](docs/TICKETING-GUIDE.md)
- [⏱️ Guía de Time Tracking](docs/WORKLOG-GUIDE.md)
- [🎯 Gestión de SLAs](docs/SLA-GUIDE.md)
- [🌐 Acceso Remoto](docs/REMOTE-ACCESS-GUIDE.md)
- [🐳 Portainer & Docker](docs/PORTAINER-GUIDE.md)
- [⚙️ Operaciones](docs/OPERATIONS.md)
- [🔒 Seguridad](docs/SECURITY.md)
- [🆘 Troubleshooting](docs/TROUBLESHOOTING.md)

## 🎨 URLs de Acceso

Tras instalar, accede a:

```
🏠 Panel Principal:        https://tu-ip
🐳 Portainer:              https://tu-ip:9000
📊 Grafana:                https://tu-ip:3000
📈 Prometheus:             http://tu-ip:9090
🎯 Guacamole (Remote):     https://tu-ip:8080
📚 Kibana (Logs):          https://tu-ip:5601
🔔 AlertManager:           http://tu-ip:9093
📖 API Docs:               https://tu-ip/api/docs
```

## 📋 Características Principales

### RMM (Remote Monitoring & Management)
- ✅ Monitoreo en tiempo real
- ✅ Métricas CPU, RAM, Disco, Red
- ✅ Alertas automáticas
- ✅ Integración Prometheus/Grafana
- ✅ Dashboards personalizados

### Ticketing
- ✅ Estados completos
- ✅ Prioridades configurable
- ✅ Asignación automática
- ✅ Escaladas automáticas
- ✅ SLA tracking
- ✅ Historial de cambios

### Time Tracking
- ✅ Timer automático
- ✅ Tracking manual
- ✅ Facturación vs no-facturación
- ✅ Reportes de productividad

### Remote Access
- ✅ VPN OpenVPN
- ✅ Guacamole (RDP/SSH/VNC)
- ✅ Acceso web sin instalación
- ✅ Logs de conexiones

### Seguridad
- ✅ JWT Authentication
- ✅ LDAP/AD Support
- ✅ RBAC Granular
- ✅ Audit Trail Completo
- ✅ SSL/TLS Automático

## 🛠️ Tech Stack

**Backend**
- Node.js 18+
- Express.js
- PostgreSQL
- Redis
- Prometheus

**Frontend**
- React 18
- Vite
- Tailwind CSS
- Chart.js

**DevOps**
- Docker & Docker Compose
- Nginx
- Portainer
- Guacamole
- OpenVPN

## 📦 Servicios Incluidos

- **backend** - API REST
- **frontend** - UI React
- **postgres** - Base de datos
- **redis** - Cache
- **nginx** - Reverse proxy
- **portainer** - Docker management
- **prometheus** - Métricas
- **grafana** - Dashboards
- **alertmanager** - Alertas
- **elasticsearch** - Logs
- **kibana** - Visualización
- **logstash** - ETL
- **node-exporter** - Métricas sistema
- **cadvisor** - Docker stats
- **guacamole** - Remote access
- **guacd** - Guacamole daemon
- **openvpn** - VPN

## 📋 Primeros Pasos Post-Instalación

```bash
# Verificar que TODO está corriendo
docker-compose ps

# Ver logs en vivo
docker-compose logs -f

# Crear primer cliente
sobopanel-create-client "Mi Empresa"

# Crear usuario técnico
sobopanel-create-user "tecnico1" --role technician

# Health check
sobopanel-health-check
```

## 🤝 Contribuir

Este es un proyecto de código abierto. Las contribuciones son bienvenidas.

1. Fork el repositorio
2. Crea una rama (`git checkout -b feature/amazing-feature`)
3. Commit cambios (`git commit -m 'Add amazing feature'`)
4. Push a la rama (`git push origin feature/amazing-feature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la licencia GPL-3.0. Ver [LICENSE](LICENSE) para más detalles.

## 📞 Soporte

- 📖 [Documentación](docs/)
- 🆘 [Troubleshooting](docs/TROUBLESHOOTING.md)
- 💬 Issues en GitHub

## 🗺️ Roadmap ODOO Integration (FASE 2)

- [ ] Sincronización de clientes con ODOO
- [ ] Integración de facturas
- [ ] Sincronización de proyectos
- [ ] Reportes integrados
- [ ] SSO con ODOO

## 👨‍💻 Autor

**Javier Sobo** - MSP Developer & DevOps Engineer

---

**Versión:** 1.0.0  
**Estado:** Beta  
**Última actualización:** Abril 2026

⭐ Si te gusta el proyecto, dale una estrella en GitHub!
