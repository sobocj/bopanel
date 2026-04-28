import { useState, useEffect } from 'react'
import { BrowserRouter, Routes, Route, Link, useNavigate } from 'react-router-dom'
import './App.css'

// Dashboard Component
function Dashboard() {
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(true)
  const navigate = useNavigate()

  useEffect(() => {
    fetchStats()
  }, [])

  const fetchStats = async () => {
    try {
      const response = await fetch('/api/stats')
      if (response.ok) {
        setStats(await response.json())
      }
    } catch (error) {
      console.log('Stats not available yet')
    } finally {
      setLoading(false)
    }
  }

  const panels = [
    {
      name: 'BoPanel',
      description: 'Main MSP Management Platform',
      icon: '🎯',
      url: '/',
      color: 'from-blue-600 to-blue-800',
      status: 'local',
    },
    {
      name: 'Portainer',
      description: 'Docker Container Management',
      icon: '🐳',
      url: process.env.REACT_APP_PORTAINER_URL || 'https://' + window.location.hostname + ':9000',
      color: 'from-purple-600 to-purple-800',
      status: 'external',
    },
    {
      name: 'Grafana',
      description: 'Metrics & Visualization',
      icon: '📊',
      url: process.env.REACT_APP_GRAFANA_URL || 'http://' + window.location.hostname + ':3000',
      color: 'from-orange-600 to-orange-800',
      status: 'external',
    },
    {
      name: 'Prometheus',
      description: 'Metrics Collection',
      icon: '📈',
      url: process.env.REACT_APP_PROMETHEUS_URL || 'http://' + window.location.hostname + ':9090',
      color: 'from-red-600 to-red-800',
      status: 'external',
    },
    {
      name: 'Kibana',
      description: 'Logs & Analytics',
      icon: '🔍',
      url: process.env.REACT_APP_KIBANA_URL || 'http://' + window.location.hostname + ':5601',
      color: 'from-yellow-600 to-yellow-800',
      status: 'external',
    },
    {
      name: 'Guacamole',
      description: 'Remote Desktop Access',
      icon: '🖥️',
      url: process.env.REACT_APP_GUACAMOLE_URL || 'https://' + window.location.hostname + ':8081',
      color: 'from-green-600 to-green-800',
      status: 'external',
    },
  ]

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 to-slate-800">
      {/* Header */}
      <header className="bg-slate-800 shadow-lg border-b border-slate-700">
        <div className="max-w-7xl mx-auto px-6 py-4">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-4xl font-bold text-white">🎯 BoPanel</h1>
              <p className="text-slate-400 mt-1">Open Source MSP Management Platform</p>
            </div>
            <div className="text-right">
              <p className="text-slate-300">v1.0.0 - Beta</p>
              <p className="text-sm text-slate-500">{new Date().toLocaleDateString()}</p>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-6 py-12">
        {/* Quick Stats */}
        {stats && !loading && (
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-12">
            <div className="bg-slate-700 rounded-lg p-4 border border-slate-600">
              <p className="text-slate-400 text-sm">Total Tickets</p>
              <p className="text-3xl font-bold text-white">{stats.tickets || 0}</p>
            </div>
            <div className="bg-slate-700 rounded-lg p-4 border border-slate-600">
              <p className="text-slate-400 text-sm">Active Clients</p>
              <p className="text-3xl font-bold text-white">{stats.clients || 0}</p>
            </div>
            <div className="bg-slate-700 rounded-lg p-4 border border-slate-600">
              <p className="text-slate-400 text-sm">System Users</p>
              <p className="text-3xl font-bold text-white">{stats.users || 0}</p>
            </div>
            <div className="bg-slate-700 rounded-lg p-4 border border-slate-600">
              <p className="text-slate-400 text-sm">Server Status</p>
              <p className="text-3xl font-bold text-green-400">✓ Online</p>
            </div>
          </div>
        )}

        {/* Panels Grid */}
        <div>
          <h2 className="text-2xl font-bold text-white mb-6">📋 Management Panels</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {panels.map((panel, idx) => (
              <a
                key={idx}
                href={panel.url}
                target={panel.status === 'external' ? '_blank' : '_self'}
                rel={panel.status === 'external' ? 'noopener noreferrer' : ''}
                className="group"
              >
                <div className={`bg-gradient-to-br ${panel.color} rounded-lg p-6 shadow-lg hover:shadow-2xl transition-all transform hover:scale-105 cursor-pointer border border-opacity-20 border-white`}>
                  <div className="text-5xl mb-4">{panel.icon}</div>
                  <h3 className="text-2xl font-bold text-white mb-2">{panel.name}</h3>
                  <p className="text-white text-opacity-90 mb-4">{panel.description}</p>
                  <div className="flex justify-between items-center">
                    <span className="text-sm bg-white bg-opacity-20 px-3 py-1 rounded text-white">
                      {panel.status === 'local' ? '🏠 Local' : '🔗 External'}
                    </span>
                    <span className="text-xl group-hover:translate-x-2 transition-transform">→</span>
                  </div>
                </div>
              </a>
            ))}
          </div>
        </div>

        {/* Features Section */}
        <div className="mt-16 bg-slate-700 rounded-lg p-8 border border-slate-600">
          <h2 className="text-2xl font-bold text-white mb-6">✨ Features</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="flex items-start space-x-3">
              <span className="text-2xl">🎟️</span>
              <div>
                <h3 className="font-semibold text-white">Ticketing System</h3>
                <p className="text-slate-400 text-sm">Complete issue tracking and management</p>
              </div>
            </div>
            <div className="flex items-start space-x-3">
              <span className="text-2xl">⏱️</span>
              <div>
                <h3 className="font-semibold text-white">Time Tracking</h3>
                <p className="text-slate-400 text-sm">Track billable hours per ticket</p>
              </div>
            </div>
            <div className="flex items-start space-x-3">
              <span className="text-2xl">📊</span>
              <div>
                <h3 className="font-semibold text-white">RMM Monitoring</h3>
                <p className="text-slate-400 text-sm">Real-time system monitoring</p>
              </div>
            </div>
            <div className="flex items-start space-x-3">
              <span className="text-2xl">🎯</span>
              <div>
                <h3 className="font-semibold text-white">SLA Management</h3>
                <p className="text-slate-400 text-sm">Define and track SLA profiles</p>
              </div>
            </div>
            <div className="flex items-start space-x-3">
              <span className="text-2xl">🖥️</span>
              <div>
                <h3 className="font-semibold text-white">Remote Access</h3>
                <p className="text-slate-400 text-sm">Secure remote desktop via Guacamole</p>
              </div>
            </div>
            <div className="flex items-start space-x-3">
              <span className="text-2xl">📈</span>
              <div>
                <h3 className="font-semibold text-white">Analytics & Reports</h3>
                <p className="text-slate-400 text-sm">Detailed performance metrics</p>
              </div>
            </div>
          </div>
        </div>

        {/* Quick Links */}
        <div className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-slate-700 rounded-lg p-6 border border-slate-600">
            <h3 className="text-lg font-semibold text-white mb-4">📚 Documentation</h3>
            <ul className="space-y-2">
              <li><a href="/docs" className="text-blue-400 hover:text-blue-300">User Guide</a></li>
              <li><a href="/docs" className="text-blue-400 hover:text-blue-300">API Reference</a></li>
              <li><a href="/docs" className="text-blue-400 hover:text-blue-300">Troubleshooting</a></li>
            </ul>
          </div>
          <div className="bg-slate-700 rounded-lg p-6 border border-slate-600">
            <h3 className="text-lg font-semibold text-white mb-4">🔗 Resources</h3>
            <ul className="space-y-2">
              <li><a href="https://github.com/sobocj/bopanel" target="_blank" rel="noopener noreferrer" className="text-blue-400 hover:text-blue-300">GitHub Repository</a></li>
              <li><a href="https://github.com/sobocj/bopanel/issues" target="_blank" rel="noopener noreferrer" className="text-blue-400 hover:text-blue-300">Report Issues</a></li>
              <li><a href="https://github.com/sobocj/bopanel/discussions" target="_blank" rel="noopener noreferrer" className="text-blue-400 hover:text-blue-300">Discussions</a></li>
            </ul>
          </div>
          <div className="bg-slate-700 rounded-lg p-6 border border-slate-600">
            <h3 className="text-lg font-semibold text-white mb-4">🆘 Support</h3>
            <ul className="space-y-2">
              <li><a href="mailto:support@bopanel.io" className="text-blue-400 hover:text-blue-300">Email Support</a></li>
              <li><a href="/docs" className="text-blue-400 hover:text-blue-300">Help Center</a></li>
              <li><a href="https://status.bopanel.io" target="_blank" rel="noopener noreferrer" className="text-blue-400 hover:text-blue-300">Status Page</a></li>
            </ul>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-slate-900 border-t border-slate-700 mt-16">
        <div className="max-w-7xl mx-auto px-6 py-8 text-center text-slate-400">
          <p>&copy; 2026 BoPanel - Open Source MSP Management Platform</p>
          <p className="text-sm mt-2">Made with ❤️ for MSPs worldwide</p>
        </div>
      </footer>
    </div>
  )
}

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="*" element={
          <div className="min-h-screen bg-gradient-to-br from-slate-900 to-slate-800 flex items-center justify-center">
            <div className="text-center text-white">
              <h1 className="text-4xl font-bold mb-4">404</h1>
              <p className="text-xl mb-8">Page not found</p>
              <a href="/" className="bg-blue-600 hover:bg-blue-700 px-6 py-3 rounded-lg">
                Back to Dashboard
              </a>
            </div>
          </div>
        } />
      </Routes>
    </BrowserRouter>
  )
}

export default App
