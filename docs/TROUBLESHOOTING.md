# Guía de Troubleshooting - BoPanel

## 🆘 Problemas Comunes y Soluciones

---

## 🚀 Servicios No Inician

### Síntoma
Al ejecutar `docker-compose up -d`, los servicios no inician correctamente.

### Solución

#### 1. **Verificar que Docker está corriendo**
```bash
sudo systemctl status docker
sudo systemctl start docker
```

#### 2. **Ver logs de los servicios**
```bash
docker-compose logs -f
docker-compose logs backend
docker-compose logs frontend
```

#### 3. **Revisar archivo .env**
```bash
cat .env | grep -E "DB_|REDIS_|DOMAIN"
# Asegúrate que todas las variables están definidas
```

#### 4. **Eliminar y reiniciar servicios**
```bash
docker-compose down -v  # -v elimina volúmenes
docker-compose up -d
```

---

## 💾 Errores de Base de Datos

### Error: "connection refused"

```bash
# Verificar que PostgreSQL está running
docker-compose ps | grep postgres

# Ver logs de PostgreSQL
docker-compose logs postgres

# Conectar a la BD directamente
docker exec -it bopanel-postgres psql -U bopanel -d bopanel
```

### Error: "role 'bopanel' does not exist"

```bash
# Conectar como superusuario
docker exec -it bopanel-postgres psql -U postgres

# Crear usuario
CREATE ROLE bopanel WITH LOGIN PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE bopanel TO bopanel;
```

### Migración de BD fallida

```bash
# Ver estado de migraciones
docker-compose exec backend npm run db:status

# Rollback de migración
docker-compose exec backend npm run db:rollback

# Ejecutar nuevamente
docker-compose exec backend npm run db:migrate
```

### BD llena de datos de prueba

```bash
# Hacer backup primero
docker exec bopanel-postgres pg_dump -U bopanel bopanel > backup.sql

# Limpiar todas las tablas
docker-compose exec postgres psql -U bopanel -d bopanel -c "
  DROP SCHEMA public CASCADE;
  CREATE SCHEMA public;
  GRANT ALL ON SCHEMA public TO bopanel;
"

# Ejecutar migraciones nuevamente
docker-compose exec backend npm run db:migrate
```

---

## 🔓 Problemas de Autenticación

### Error: "Invalid token"

```bash
# El JWT_SECRET está mal configurado
# Verificar en .env
cat .env | grep JWT_SECRET

# Si está vacío, regenerar
openssl rand -base64 32 >> .env

# Reiniciar backend
docker-compose restart backend
```

### Error: "401 Unauthorized"

```bash
# Headers incorrectos
# Asegúrate de incluir:
# Authorization: Bearer <token>
# Content-Type: application/json

# Si estás usando curl:
curl -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     http://localhost:3000/api/tickets
```

### Usuario no puede iniciar sesión

```bash
# Verificar que el usuario existe
docker-compose exec postgres psql -U bopanel -d bopanel -c "
  SELECT email, rol FROM users;
"

# Resetear contraseña
docker-compose exec backend npm run reset:password -- admin@example.com
```

---

## 🔐 Errores SSL/TLS

### Error: "Certificate not found"

```bash
# Verificar certificados
ls -la /etc/letsencrypt/live/tu-dominio.com/

# Regenerar
sudo certbot certonly --standalone -d tu-dominio.com

# Copiar a Docker
sudo cp /etc/letsencrypt/live/tu-dominio.com/fullchain.pem ./certs/
sudo cp /etc/letsencrypt/live/tu-dominio.com/privkey.pem ./certs/
```

### Error: "SSL certificate problem: self signed certificate"

```bash
# En desarrollo, ignorar certificados
curl -k https://localhost/api/health

# En producción, usar certificados válidos
# Ver sección anterior
```

### HSTS - Mixed Content Warning

```bash
# Asegurar que Nginx fuerza HTTPS
docker exec bopanel-nginx cat /etc/nginx/conf.d/default.conf | grep "return 301"

# Debería mostrar:
# return 301 https://$server_name$request_uri;
```

---

## ⚡ Performance Lento

### Verificar recursos del sistema

```bash
# CPU y memoria
docker stats

# Si algún contenedor usa >80% de recursos:
docker-compose logs <service>

# Aumentar recursos en docker-compose.yml
# O en el sistema operativo:
free -h
```

### BD lenta

```bash
# Verificar tamaño de BD
docker-compose exec postgres psql -U bopanel -d bopanel -c "
  SELECT datname, pg_size_pretty(pg_database_size(datname)) 
  FROM pg_database 
  WHERE datname = 'bopanel';
"

# Ver queries lentas
docker-compose exec postgres psql -U bopanel -d bopanel -c "
  SELECT query, mean_exec_time, calls 
  FROM pg_stat_statements 
  ORDER BY mean_exec_time DESC 
  LIMIT 10;
"

# Reindexar BD
docker-compose exec postgres psql -U bopanel -d bopanel -c "
  REINDEX DATABASE bopanel;
"
```

### Redis lleno

```bash
# Ver memoria usada
docker-compose exec redis redis-cli INFO memory

# Limpiar cache
docker-compose exec redis redis-cli FLUSHALL

# Configurar eviction policy
docker-compose exec redis redis-cli CONFIG SET maxmemory-policy allkeys-lru
```

---

## 🔍 Elasticsearch/Kibana Vacío

### No hay logs

```bash
# Verificar que Elasticsearch está running
docker-compose ps | grep elasticsearch

# Ver índices
docker-compose exec elasticsearch curl -s http://localhost:9200/_cat/indices

# Crear índice manualmente
docker-compose exec elasticsearch curl -X PUT http://localhost:9200/logs-2026.04.27

# En Kibana, crear index pattern: logs-*
```

### Kibana no muestra datos

```bash
# Verificar conexión
docker-compose exec kibana curl -u elastic:password http://elasticsearch:9200/

# Ver logs de Kibana
docker-compose logs kibana

# Reiniciar Kibana
docker-compose restart kibana
```

---

## 🔄 Migraciones de Base de Datos

### Ver estado de migraciones

```bash
docker-compose exec backend npm run db:status
```

### Ejecutar migración

```bash
docker-compose exec backend npm run db:migrate
```

### Rollback de migración

```bash
docker-compose exec backend npm run db:rollback
```

### Forzar estado de migración

```bash
docker-compose exec postgres psql -U bopanel -d bopanel -c "
  UPDATE schema_migrations SET applied = false WHERE name = '001_initial_schema';
"
```

---

## 📝 Aumentar Verbosidad de Logs

### Backend (Express)

```bash
# Editar .env
echo "LOG_LEVEL=debug" >> .env
docker-compose restart backend

# Ver logs
docker-compose logs -f backend
```

### Frontend (React)

```bash
# En navegador, abrir DevTools (F12)
# Console tab para ver logs
# Network tab para ver requests
```

### PostgreSQL

```bash
docker-compose exec postgres psql -U bopanel -d bopanel -c "
  ALTER SYSTEM SET log_statement = 'all';
  SELECT pg_reload_conf();
"

docker-compose logs postgres
```

### Redis

```bash
docker-compose exec redis redis-cli DEBUG OBJECT <key>
docker-compose logs redis
```

---

## 🔄 Actualizar Versiones

### Actualizar imagen de servicio

```bash
# Backend
docker-compose pull backend
docker-compose up -d backend

# Frontend
docker-compose pull frontend
docker-compose up -d frontend

# PostgreSQL (con backup primero!)
docker exec bopanel-postgres pg_dump -U bopanel bopanel > backup.sql
docker-compose pull postgres
docker-compose up -d postgres
```

### Actualizar dependencias Node

```bash
# Backend
docker-compose exec backend npm update

# Frontend
docker-compose exec frontend npm update

# Rebuild
docker-compose down
docker-compose up -d --build
```

---

## 💾 Backup y Restauración

### Backup de BD

```bash
# Full backup
docker exec bopanel-postgres pg_dump -U bopanel bopanel > backup_$(date +%Y%m%d).sql

# Backup gzip
docker exec bopanel-postgres pg_dump -U bopanel bopanel | gzip > backup_$(date +%Y%m%d).sql.gz
```

### Restaurar BD

```bash
# Desde SQL
cat backup_20260427.sql | docker-compose exec -T postgres psql -U bopanel bopanel

# Desde gzip
gunzip -c backup_20260427.sql.gz | docker-compose exec -T postgres psql -U bopanel bopanel
```

### Backup de volúmenes

```bash
# Listar volúmenes
docker volume ls

# Backup de volumen
docker run --rm -v bopanel_postgres_data:/data -v $(pwd):/backup ubuntu tar czf /backup/postgres_backup.tar.gz -C / data

# Restaurar
docker run --rm -v bopanel_postgres_data:/data -v $(pwd):/backup ubuntu tar xzf /backup/postgres_backup.tar.gz -C /
```

---

## 🏥 Health Check Script

```bash
#!/bin/bash
# save as: health-check.sh

echo "=== BoPanel Health Check ==="
echo ""

# Docker
echo "1. Docker"
docker info > /dev/null 2>&1 && echo "✓ Docker running" || echo "✗ Docker not running"

# Services
echo ""
echo "2. Services"
services=("postgres" "redis" "backend" "frontend" "elasticsearch" "kibana")
for service in "${services[@]}"; do
  docker-compose ps $service | grep "Up" > /dev/null && echo "✓ $service" || echo "✗ $service"
done

# Ports
echo ""
echo "3. Ports"
curl -s http://localhost:3000/api/health > /dev/null && echo "✓ Backend (3000)" || echo "✗ Backend (3000)"
curl -s http://localhost:5173 > /dev/null && echo "✓ Frontend (5173)" || echo "✗ Frontend (5173)"
curl -s http://localhost:9090 > /dev/null && echo "✓ Prometheus (9090)" || echo "✗ Prometheus (9090)"
curl -s http://localhost:3000 > /dev/null && echo "✓ Grafana (3000)" || echo "✗ Grafana (3000)"

# Database
echo ""
echo "4. Database"
docker-compose exec -T postgres psql -U bopanel -d bopanel -c "SELECT COUNT(*) FROM users;" > /dev/null 2>&1 && echo "✓ PostgreSQL" || echo "✗ PostgreSQL"

# Redis
echo ""
echo "5. Cache"
docker-compose exec -T redis redis-cli ping > /dev/null 2>&1 && echo "✓ Redis" || echo "✗ Redis"

echo ""
echo "=== End Health Check ==="
```

---

## 📞 Contactar Soporte

Si el problema persiste:

1. **Recolectar logs**
```bash
docker-compose logs > logs_$(date +%Y%m%d_%H%M%S).txt
```

2. **Crear issue en GitHub**
- https://github.com/sobocj/bopanel/issues

3. **Email de soporte**
- support@bopanel.io

4. **Información a incluir**
- Versión de BoPanel
- OS y versión
- Output de `docker -v` y `docker-compose -v`
- Logs completos
- Pasos para reproducir

