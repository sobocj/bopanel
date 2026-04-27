# BoPanel API Reference

## 📋 Descripción General

BoPanel expone una **API REST completa** para gestionar todos los aspectos de la plataforma. Todos los endpoints (excepto `/auth/login`) requieren autenticación con JWT.

---

## 🔑 Autenticación

### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "admin@example.com",
  "password": "tu_contraseña"
}
```

**Respuesta (200):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "uuid",
      "email": "admin@example.com",
      "nombre": "Admin User",
      "rol": "admin",
      "permisos": ["read:all", "write:all", "admin"]
    }
  },
  "timestamp": "2026-04-27T13:00:00Z"
}
```

### Headers Requeridos
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
```

### Logout
```http
POST /api/auth/logout
```

---

## 👥 Usuarios

### Listar Usuarios
```http
GET /api/users?page=1&limit=20&search=john&rol=technician
Authorization: Bearer <token>
```

**Respuesta (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "email": "tech@example.com",
      "nombre": "John Technician",
      "rol": "technician",
      "activo": true,
      "created_at": "2026-04-20T10:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45
  }
}
```

### Crear Usuario
```http
POST /api/users
Authorization: Bearer <token>
Content-Type: application/json

{
  "email": "newtech@example.com",
  "password": "SecurePassword123!",
  "nombre": "New Technician",
  "rol": "technician",
  "activo": true
}
```

### Actualizar Usuario
```http
PUT /api/users/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "nombre": "Updated Name",
  "rol": "manager"
}
```

### Eliminar Usuario
```http
DELETE /api/users/:id
Authorization: Bearer <token>
```

---

## 🏢 Clientes

### Listar Clientes
```http
GET /api/clients?page=1&limit=20&search=acme
Authorization: Bearer <token>
```

**Respuesta:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "nombre": "ACME Corporation",
      "email": "contact@acme.com",
      "telefono": "+34 91 123 4567",
      "ciudad": "Madrid",
      "pais": "España",
      "sla_profile_id": "uuid",
      "activo": true,
      "created_at": "2026-04-20T10:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 12
  }
}
```

### Crear Cliente
```http
POST /api/clients
Authorization: Bearer <token>
Content-Type: application/json

{
  "nombre": "New Client Ltd",
  "email": "info@newclient.com",
  "telefono": "+34 91 555 6666",
  "ciudad": "Barcelona",
  "pais": "España",
  "sla_profile_id": "uuid-sla-standard"
}
```

### Obtener Cliente
```http
GET /api/clients/:id
Authorization: Bearer <token>
```

### Actualizar Cliente
```http
PUT /api/clients/:id
Authorization: Bearer <token>
```

### Eliminar Cliente
```http
DELETE /api/clients/:id
Authorization: Bearer <token>
```

---

## 🎟️ Tickets

### Listar Tickets
```http
GET /api/tickets?page=1&limit=50&estado=open&prioridad=high&assigned_to=uuid&client_id=uuid
Authorization: Bearer <token>
```

**Respuesta:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "numero": "TKT-00123",
      "titulo": "Servidor no responde",
      "descripcion": "El servidor de producción está caído",
      "estado": "open",
      "prioridad": "critical",
      "client_id": "uuid",
      "usuario_id": "uuid",
      "asignado_a_id": "uuid",
      "sla_profile_id": "uuid",
      "created_at": "2026-04-27T09:00:00Z",
      "resuelto_at": null,
      "tiempo_respuesta_minutos": 15,
      "tiempo_resolucion_minutos": 120,
      "horas_totales": 0
    }
  ]
}
```

### Crear Ticket
```http
POST /api/tickets
Authorization: Bearer <token>
Content-Type: application/json

{
  "titulo": "Problema con correo",
  "descripcion": "No puedo enviar correos desde Outlook",
  "client_id": "uuid",
  "prioridad": "high",
  "categoria": "email",
  "asignado_a_id": "uuid" (opcional)
}
```

### Actualizar Ticket
```http
PUT /api/tickets/:id
Authorization: Bearer <token>

{
  "estado": "in_progress",
  "prioridad": "medium",
  "asignado_a_id": "uuid"
}
```

### Cerrar Ticket
```http
POST /api/tickets/:id/close
Authorization: Bearer <token>

{
  "nota_final": "Problema resuelto. Servidor reiniciado."
}
```

### Agregar Comentario
```http
POST /api/tickets/:id/comments
Authorization: Bearer <token>

{
  "comentario": "He reiniciado el servicio",
  "es_interno": false
}
```

### Cambiar Estado a Aceptado
```http
POST /api/tickets/:id/accept
Authorization: Bearer <token>
```

---

## ⏱️ Time Tracking

### Crear Registro de Tiempo
```http
POST /api/time-tracking
Authorization: Bearer <token>

{
  "ticket_id": "uuid",
  "horas": 2.5,
  "descripcion": "Diagnóstico del problema y aplicación de parches",
  "es_facturable": true,
  "fecha_trabajo": "2026-04-27"
}
```

### Listar Registros de Tiempo
```http
GET /api/time-tracking?ticket_id=uuid&user_id=uuid&fecha_desde=2026-04-01&fecha_hasta=2026-04-30
Authorization: Bearer <token>
```

### Obtener Total de Horas por Ticket
```http
GET /api/tickets/:id/hours
Authorization: Bearer <token>
```

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "ticket_id": "uuid",
    "horas_totales": 5.5,
    "horas_facturables": 5.5,
    "horas_no_facturables": 0,
    "costo_total": 192.5
  }
}
```

---

## 📊 Monitoreo

### Obtener Métricas del Sistema
```http
GET /api/monitoring/system
Authorization: Bearer <token>
```

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "cpu_usage": 45.2,
    "memory_usage": 62.5,
    "disk_usage": 38.1,
    "network_in": 125.5,
    "network_out": 89.3,
    "uptime_hours": 720
  }
}
```

### Obtener Alertas
```http
GET /api/monitoring/alerts?estado=active
Authorization: Bearer <token>
```

### Crear Alerta Manual
```http
POST /api/monitoring/alerts
Authorization: Bearer <token>

{
  "titulo": "Espacio en disco bajo",
  "descripcion": "Servidor backup con 95% de capacidad",
  "severidad": "warning"
}
```

---

## 📈 SLA

### Listar Perfiles SLA
```http
GET /api/sla-profiles
Authorization: Bearer <token>
```

### Crear Perfil SLA
```http
POST /api/sla-profiles
Authorization: Bearer <token>

{
  "nombre": "Premium",
  "descripcion": "Soporte prioritario 24/7",
  "tiempo_respuesta_minutos": 30,
  "tiempo_resolucion_minutos": 240,
  "precio_mensual": 500
}
```

### Obtener Estadísticas SLA
```http
GET /api/sla-profiles/:id/stats
Authorization: Bearer <token>
```

---

## 📄 Reportes

### Reporte de Tickets por Período
```http
GET /api/reports/tickets?fecha_desde=2026-04-01&fecha_hasta=2026-04-30
Authorization: Bearer <token>
```

### Reporte de Productividad
```http
GET /api/reports/productivity?user_id=uuid&fecha_desde=2026-04-01&fecha_hasta=2026-04-30
Authorization: Bearer <token>
```

### Reporte de Facturación
```http
GET /api/reports/billing?client_id=uuid&mes=04&anio=2026
Authorization: Bearer <token>
```

---

## 🔧 Status Codes

| Código | Significado | Descripción |
|--------|-----------|-------------|
| 200 | OK | Request exitoso |
| 201 | Created | Recurso creado exitosamente |
| 204 | No Content | Éxito sin contenido de respuesta |
| 400 | Bad Request | Parámetros inválidos |
| 401 | Unauthorized | No autenticado o token inválido |
| 403 | Forbidden | Permisos insuficientes |
| 404 | Not Found | Recurso no encontrado |
| 409 | Conflict | Violación de restricción única |
| 422 | Unprocessable | Validación fallida |
| 429 | Too Many Requests | Rate limit alcanzado |
| 500 | Server Error | Error en el servidor |
| 503 | Service Unavailable | Servicio no disponible |

---

## ⏳ Rate Limiting

- **100 requests** por 15 minutos por IP
- **1000 requests** por hora por usuario autenticado
- **Headers de respuesta**:
  - `X-RateLimit-Limit`
  - `X-RateLimit-Remaining`
  - `X-RateLimit-Reset`

---

## 📝 Ejemplo completo con curl

### Crear ticket completo
```bash
# 1. Autenticarse
TOKEN=$(curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password123"}' \
  | jq -r '.data.token')

# 2. Crear ticket
curl -X POST http://localhost:3000/api/tickets \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "titulo": "Problemas de conectividad",
    "descripcion": "La oficina no tiene internet",
    "client_id": "uuid-cliente",
    "prioridad": "high",
    "categoria": "network"
  }'

# 3. Asignar a técnico
TICKET_ID="uuid-ticket"
curl -X PUT http://localhost:3000/api/tickets/$TICKET_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "asignado_a_id": "uuid-tecnico",
    "estado": "accepted"
  }'

# 4. Registrar tiempo
curl -X POST http://localhost:3000/api/time-tracking \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "ticket_id": "'$TICKET_ID'",
    "horas": 1.5,
    "descripcion": "Reinicio de router",
    "es_facturable": true
  }'
```

---

## 🔗 Webhooks (próxima versión)

Notificaciones automáticas para eventos:
- `ticket.created`
- `ticket.updated`
- `ticket.closed`
- `sla.breach`
- `alert.triggered`

