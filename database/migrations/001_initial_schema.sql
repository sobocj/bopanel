-- ============================================
-- BoPanel v1.0 - Initial Database Schema
-- ============================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================
-- USERS & AUTHENTICATION
-- ============================================

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  username VARCHAR(255) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(255),
  last_name VARCHAR(255),
  role VARCHAR(50) NOT NULL DEFAULT 'technician',
  is_active BOOLEAN DEFAULT true,
  last_login TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);

-- ============================================
-- CLIENTS (Multi-tenant)
-- ============================================

CREATE TABLE clients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  email VARCHAR(255),
  phone VARCHAR(20),
  website VARCHAR(255),
  industry VARCHAR(100),
  employee_count INTEGER,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_clients_name ON clients(name);
CREATE INDEX idx_clients_is_active ON clients(is_active);

-- ============================================
-- CONTACTS
-- ============================================

CREATE TABLE contacts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(20),
  position VARCHAR(100),
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_contacts_client_id ON contacts(client_id);

-- ============================================
-- ASSETS (Servers, Devices, etc)
-- ============================================

CREATE TABLE assets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL, -- server, workstation, network, printer, etc
  os VARCHAR(100),
  ip_address INET,
  mac_address VARCHAR(17),
  serial_number VARCHAR(255),
  location VARCHAR(255),
  status VARCHAR(50) DEFAULT 'active',
  last_heartbeat TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_assets_client_id ON assets(client_id);
CREATE INDEX idx_assets_type ON assets(type);
CREATE INDEX idx_assets_status ON assets(status);
CREATE INDEX idx_assets_ip_address ON assets(ip_address);

-- ============================================
-- TICKETS
-- ============================================

CREATE TABLE tickets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ticket_number VARCHAR(20) UNIQUE NOT NULL,
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  asset_id UUID REFERENCES assets(id) ON DELETE SET NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'new', -- new, open, pending, resolved, closed
  priority VARCHAR(50) DEFAULT 'medium', -- critical, high, medium, low
  category VARCHAR(100),
  assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
  reporter_id UUID REFERENCES users(id) ON DELETE SET NULL,
  sla_profile_id UUID,
  response_due TIMESTAMP,
  resolution_due TIMESTAMP,
  resolved_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tickets_client_id ON tickets(client_id);
CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_tickets_priority ON tickets(priority);
CREATE INDEX idx_tickets_assigned_to ON tickets(assigned_to);
CREATE INDEX idx_tickets_created_at ON tickets(created_at);
CREATE INDEX idx_tickets_ticket_number ON tickets(ticket_number);

-- ============================================
-- TICKET COMMENTS
-- ============================================

CREATE TABLE ticket_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  comment TEXT NOT NULL,
  is_internal BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ticket_comments_ticket_id ON ticket_comments(ticket_id);
CREATE INDEX idx_ticket_comments_user_id ON ticket_comments(user_id);

-- ============================================
-- WORK LOGS (Time Tracking)
-- ============================================

CREATE TABLE work_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  hours_spent DECIMAL(10, 2) NOT NULL,
  description TEXT,
  is_billable BOOLEAN DEFAULT true,
  work_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_work_logs_ticket_id ON work_logs(ticket_id);
CREATE INDEX idx_work_logs_user_id ON work_logs(user_id);
CREATE INDEX idx_work_logs_work_date ON work_logs(work_date);
CREATE INDEX idx_work_logs_is_billable ON work_logs(is_billable);

-- ============================================
-- SLA PROFILES
-- ============================================

CREATE TABLE sla_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  response_time_hours INTEGER,
  resolution_time_hours INTEGER,
  priority_weights JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sla_profiles_is_active ON sla_profiles(is_active);

-- ============================================
-- ALERTS
-- ============================================

CREATE TABLE alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
  alert_type VARCHAR(100) NOT NULL,
  severity VARCHAR(50) DEFAULT 'medium', -- critical, high, medium, low, info
  message TEXT NOT NULL,
  value DECIMAL(10, 2),
  threshold DECIMAL(10, 2),
  status VARCHAR(50) DEFAULT 'open', -- open, acknowledged, resolved
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_alerts_asset_id ON alerts(asset_id);
CREATE INDEX idx_alerts_severity ON alerts(severity);
CREATE INDEX idx_alerts_status ON alerts(status);
CREATE INDEX idx_alerts_created_at ON alerts(created_at);

-- ============================================
-- AUDIT TRAIL
-- ============================================

CREATE TABLE audit_trail (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action VARCHAR(100) NOT NULL,
  entity_type VARCHAR(100),
  entity_id VARCHAR(255),
  old_values JSONB,
  new_values JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_trail_user_id ON audit_trail(user_id);
CREATE INDEX idx_audit_trail_action ON audit_trail(action);
CREATE INDEX idx_audit_trail_created_at ON audit_trail(created_at);

-- ============================================
-- METRICS (Monitoring)
-- ============================================

CREATE TABLE metrics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
  metric_type VARCHAR(100) NOT NULL, -- cpu, memory, disk, network
  value DECIMAL(10, 2) NOT NULL,
  unit VARCHAR(50),
  recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_metrics_asset_id ON metrics(asset_id);
CREATE INDEX idx_metrics_metric_type ON metrics(metric_type);
CREATE INDEX idx_metrics_recorded_at ON metrics(recorded_at);

-- ============================================
-- NOTIFICATIONS
-- ============================================

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  message TEXT,
  notification_type VARCHAR(50), -- email, sms, slack, in-app
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);

-- ============================================
-- REMOTE ACCESS SESSIONS
-- ============================================

CREATE TABLE remote_access_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  access_type VARCHAR(50), -- rdp, ssh, vnc
  connected_at TIMESTAMP,
  disconnected_at TIMESTAMP,
  duration_minutes INTEGER,
  ip_address INET,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_remote_access_asset_id ON remote_access_sessions(asset_id);
CREATE INDEX idx_remote_access_user_id ON remote_access_sessions(user_id);
CREATE INDEX idx_remote_access_created_at ON remote_access_sessions(created_at);

-- ============================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assets_updated_at BEFORE UPDATE ON assets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tickets_updated_at BEFORE UPDATE ON tickets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_work_logs_updated_at BEFORE UPDATE ON work_logs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sla_profiles_updated_at BEFORE UPDATE ON sla_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_alerts_updated_at BEFORE UPDATE ON alerts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- INITIAL DATA
-- ============================================

-- Insert default SLA profiles
INSERT INTO sla_profiles (name, description, response_time_hours, resolution_time_hours, is_active)
VALUES 
  ('Basic', 'Basic SLA - 8 hours response, 24 hours resolution', 8, 24, true),
  ('Standard', 'Standard SLA - 4 hours response, 8 hours resolution', 4, 8, true),
  ('Premium', 'Premium SLA - 1 hour response, 4 hours resolution', 1, 4, true),
  ('Critical', 'Critical SLA - 30 minutes response, 2 hours resolution', 0.5, 2, true);

COMMIT;
