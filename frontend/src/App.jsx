import { BrowserRouter, Routes, Route } from 'react-router-dom'
import './App.css'

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={
          <div className="min-h-screen bg-gradient-to-br from-blue-600 to-blue-800 flex items-center justify-center">
            <div className="text-center text-white">
              <h1 className="text-5xl font-bold mb-4">BoPanel</h1>
              <p className="text-xl mb-8">Open Source MSP Platform</p>
              <div className="space-y-4">
                <div className="bg-white bg-opacity-10 p-6 rounded-lg">
                  <h2 className="text-2xl font-semibold mb-4">Features</h2>
                  <ul className="text-left space-y-2">
                    <li>✅ Ticketing System</li>
                    <li>✅ Time Tracking</li>
                    <li>✅ RMM Monitoring</li>
                    <li>✅ SLA Management</li>
                    <li>✅ Remote Access</li>
                    <li>✅ Analytics & Reports</li>
                  </ul>
                </div>
                <p className="text-sm opacity-75">v1.0.0 - Beta</p>
              </div>
            </div>
          </div>
        } />
      </Routes>
    </BrowserRouter>
  )
}

export default App
