# Arquitectura Técnica de BoPanel

## 📐 Descripción General

BoPanel es una plataforma MSP (Managed Service Provider) de código abierto diseñada como alternativa a ATERA. Utiliza una arquitectura moderna basada en microservicios containerizados con Docker, implementando patrones escalables y seguros.

---

## 🏗️ Arquitectura de Alto Nivel

```
┌─────────────────────────────────────────────────────────────┐
│                     Nginx Reverse Proxy                      │
│                    (SSL/TLS Termination)                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
   ┌─────────┐   ┌─────────┐   ┌──────────┐
   │Frontend │   │ Backend │   │Portainer │
   │ (React) │   │(Express)│   │ (Docker) │
   └────┬────┘   └────┬────┘   └──────────┘
        │             │
        └─────────┬───┘
                  │
        ┌─────────┴─────────┐
        │                   │
        ▼                   ▼
   ┌──────────┐      ┌──────────────┐
   │PostgreSQL│      │    Redis     │
   │(Database)│      │   (Cache)    │
   └──────────┘      └──────────────┘
```

---

## 🔧 Componentes Principales

### 1. **Frontend (React + Vite)**
- **Tecnología**: React 18, Tailwind CSS, Vite
- **Puerto**: 5173 (desarrollo) / 3000 (producción)
- **Características**:
  - UI responsiva con Tailwind CSS
  - Routing con React Router
  - Socket.io para actualizaciones en tiempo real
  - API proxy hacia backend

### 2. **Backend (Express.js + Node.js)**
- **Tecnología**: Node.js 18, Express.js
- **Puerto**: 3000
- **Características**:
  - REST API para gestión de datos
  - Socket.io para comunicación bidireccional
  - Autenticación JWT
  - RBAC (Role-Based Access Control)
  - Health checks integrados

### 3. **Base de Datos (PostgreSQL)**
- **Puerto**: 5432
- **Base de datos**: `bopanel`
- **Características**:
  - 12 tablas optimizadas
  - Índices para performance
  - Triggers para auditoría
  - Relaciones entre entidades

### 4. **Cache (Redis)**
- **Puerto**: 6379
- **Características**:
  - Sesiones de usuario
  - Cache de datos frecuentes
  - Rate limiting
  - Task queues

### 5. **Monitoreo (Prometheus + Grafana)**
- **Prometheus**: Puerto 9090 - Recolección de métricas
- **Grafana**: Puerto 3000 - Visualización de dashboards
- **Características**:
  - Métricas del sistema
  - Alertas automáticas
  - Dashboards personalizados

### 6. **Docker (Portainer)**
- **Puerto**: 9000
- **Características**:
  - Gestión visual de contenedores
  - Monitoreo de recursos
  - Actualizaciones de servicios

### 7. **Elasticsearch + Kibana**
- **Elasticsearch**: Puerto 9200 - Almacenamiento de logs
- **Kibana**: Puerto 5601 - Análisis de logs
- **Características**:
  - Logs centralizados
  - Búsqueda avanzada
  - Análisis de eventos

### 8. **Acceso Remoto (Guacamole)**
- **Puerto**: 8081
- **Características**:
  - RDP, SSH, VNC
  - Acceso sin cliente
  - Auditoría de conexiones

### 9. **VPN (OpenVPN)**
- **Puerto**: 1194 (UDP)
- **Características**:
  - Conexiones seguras
  - Acceso privado a recursos
  - Certificados SSL

---

## 📊 Modelo de Datos

### Tablas Principales

#### `users`
```sql
- id (PRIMARY KEY)
- email (UNIQUE)
- password (hashed)
- nombre
- rol (admin, manager, technician, client)
- activo
- created_at
- updated_at
```

#### `tickets`
```sql
- id (PRIMARY KEY)
- numero (UNIQUE)
- titulo
- descripcion
- estado (open, in_progress, resolved, closed)
- prioridad (low, medium, high, critical)
- user_id (FOREIGN KEY)
- asignado_a_id (FOREIGN KEY)
- created_at
- resolved_at
```

#### `time_tracking`
```sql
- id (PRIMARY KEY)
- ticket_id (FOREIGN KEY)
- user_id (FOREIGN KEY)
- horas
- descripcion
- created_at
```

#### `sla_rules`
```sql
- id (PRIMARY KEY)
- nombre
- tiempo_respuesta (minutos)
- tiempo_resolucion (minutos)
- prioridad
- activo
```

#### `audit_log`
```sql
- id (PRIMARY KEY)
- usuario_id (FOREIGN KEY)
- accion
- tabla
- registro_id
- cambios (JSON)
- ip_address
- created_at
```

---

## 🔐 Seguridad

### Autenticación
- **JWT (JSON Web Tokens)** para sesiones sin estado
- **Contraseñas hasheadas** con bcrypt
- **2FA opcional** para usuarios administradores

### Autorización
- **RBAC** (Role-Based Access Control)
- **Roles**: Admin, Manager, Technician, Client
- **Permisos granulares** por recurso

### Comunicación
- **SSL/TLS** para HTTPS
- **HTTPS forzado** en producción
- **Certificados Let's Encrypt** automáticos

### Auditoría
- **Audit log** para todas las acciones
- **Registro de IP** de acceso
- **Timestamps** en todas las operaciones

---

## 📡 Flujo de Comunicación

### Cliente → Servidor

1. **Request HTTP**
   ```
   Client → Nginx (SSL/TLS) → Frontend (React) → Backend (Express)
   ```

2. **Autenticación**
   ```
   JWT Token en headers Authorization
   Backend valida token y autoriza acción
   ```

3. **Respuesta JSON**
   ```
   Backend → Frontend → Browser
   Socket.io notifica cambios en tiempo real
   ```

### WebSocket (Socket.io)
- Conexión bidireccional
- Notificaciones en tiempo real
- Eventos: `ticket:created`, `ticket:updated`, etc.

---

## 📈 Escalabilidad

### Base de Datos
- **Connection Pooling** con PgBouncer
- **Índices optimizados** en columnas frecuentes
- **Replicación** para HA (disponible)

### Cache
- **Redis Sentinel** para HA
- **TTL automático** en keys
- **Eviction policy**: allkeys-lru

### Aplicación
- **Stateless backend** para horizontal scaling
- **Load Balancing** con Nginx
- **Docker Swarm/Kubernetes** compatible

---

## 🔄 Despliegue

### Docker Compose
```bash
docker-compose up -d
```

Levanta 17 servicios automáticamente:
- Frontend
- Backend
- PostgreSQL
- Redis
- Prometheus
- Grafana
- Elasticsearch
- Kibana
- Portainer
- OpenVPN
- Guacamole
- AlertManager
- Node Exporter
- cAdvisor
- Nginx
- y más...

### Variables de Entorno
Configuradas en `.env`:
- `DB_HOST`, `DB_USER`, `DB_PASSWORD`
- `REDIS_HOST`, `REDIS_PORT`
- `JWT_SECRET`
- `DOMAIN` (para SSL)
- `ADMIN_EMAIL`, `ADMIN_PASSWORD`

---

## 🎯 Flujos Principales

### Creación de Ticket
1. Usuario crea ticket (Frontend)
2. POST `/api/tickets` → Backend
3. Backend valida y guarda en DB
4. Emit `ticket:created` vía Socket.io
5. Usuarios suscritos reciben notificación en tiempo real
6. Triggers de BD actualizan audit_log

### Asignación de Ticket
1. Manager asigna ticket a technician
2. PATCH `/api/tickets/:id` → Backend
3. Backend actualiza asignación y checks SLA
4. Socket.io notifica a technician
5. Email de notificación (opcional)
6. Audit log registra cambio

### Time Tracking
1. Technician registra horas
2. POST `/api/time_tracking` → Backend
3. Backend calcula costo y facturación
4. Ticket se actualiza con total de horas
5. Grafana muestra metrics de productividad

---

## 📊 Performance

### Optimizaciones
- **Lazy Loading** en frontend
- **Gzip compression** en respuestas HTTP
- **CDN-ready** para assets estáticos
- **Database query optimization** con índices
- **Redis caching** para datos frecuentes

### Monitoreo
- **Prometheus** recolecta métricas
- **Grafana** visualiza dashboards
- **Alertas** configurables en AlertManager
- **Logs centralizados** en Elasticsearch

---

## 🔧 Stack Tecnológico

| Componente | Tecnología | Versión |
|-----------|-----------|---------|
| Frontend | React | 18+ |
| Backend | Node.js | 18+ |
| API | Express.js | 4.x |
| Database | PostgreSQL | 14+ |
| Cache | Redis | 7+ |
| Containerization | Docker | 20.10+ |
| Monitoring | Prometheus | 2.x |
| Visualization | Grafana | 9+ |
| Log Analysis | Elasticsearch | 8+ |
| Reverse Proxy | Nginx | 1.24+ |

---

## 📝 Notas Importantes

- **Stateless**: Backend no mantiene estado entre requests
- **Horizontal Scalability**: Puede escalarse agregando más instancias
- **Zero Downtime Deployments**: Mediante Docker Swarm/K8s
- **Data Persistence**: Todos los datos en PostgreSQL con backups automáticos
- **Real-time Updates**: Socket.io para notificaciones instantáneas
- **Multi-tenant Ready**: Arquitectura preparada para múltiples clientes

