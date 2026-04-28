import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import morgan from 'morgan'
import dotenv from 'dotenv'
import http from 'http'
import { Server } from 'socket.io'

dotenv.config()

const app = express()
const server = http.createServer(app)
const io = new Server(server, {
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST'],
  },
})

// Middleware
app.use(helmet())
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
}))
app.use(morgan('combined'))
app.use(express.json({ limit: '10mb' }))
app.use(express.urlencoded({ limit: '10mb', extended: true }))

// Health Check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: '1.0.0',
  })
})

// Stats Endpoint
app.get('/api/stats', (req, res) => {
  res.json({
    tickets: Math.floor(Math.random() * 100) + 1,
    clients: Math.floor(Math.random() * 50) + 1,
    users: Math.floor(Math.random() * 30) + 1,
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  })
})

// API Routes
app.get('/api', (req, res) => {
  res.json({
    name: 'BoPanel API',
    version: '1.0.0',
    status: 'running',
    endpoints: {
      health: '/health',
      stats: '/api/stats',
      tickets: '/api/tickets',
      clients: '/api/clients',
      users: '/api/users',
      monitoring: '/api/monitoring',
      sla: '/api/sla',
      admin: '/api/admin',
    },
  })
})

// WebSocket Events
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id)

  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id)
  })

  socket.on('ping', () => {
    socket.emit('pong')
  })
})

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.method} ${req.path} not found`,
    available: '/api',
  })
})

// Error Handler
app.use((err, req, res, next) => {
  console.error(err.stack)
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'production' ? 'Server error' : err.message,
  })
})

const PORT = process.env.PORT || 3000
const HOST = process.env.HOST || '0.0.0.0'

server.listen(PORT, HOST, () => {
  console.log(`\n✅ BoPanel Server running`)
  console.log(`📍 Address: http://${HOST}:${PORT}`)
  console.log(`📖 API: http://${HOST}:${PORT}/api`)
  console.log(`🏥 Health: http://${HOST}:${PORT}/health`)
  console.log(`📊 Stats: http://${HOST}:${PORT}/api/stats\n`)
})

export default app
