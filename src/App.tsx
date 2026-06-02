import { useEffect } from 'react'
import { Navigate, Outlet, Route, Routes } from 'react-router-dom'
import { Layout } from './components/Layout'
import { Dashboard } from './pages/Dashboard'
import { Programs } from './pages/Programs'
import { ProgramDetail } from './pages/ProgramDetail'
import { ProgramEditor } from './pages/ProgramEditor'
import { Workout } from './pages/Workout'
import { Exercises } from './pages/Exercises'
import { ExerciseDetail } from './pages/ExerciseDetail'
import { Progress } from './pages/Progress'
import { Settings } from './pages/Settings'
import { Auth } from './pages/Auth'
import { useAuth } from './auth'
import { loadCurrentUserData } from './store'

function RequireAuth() {
  const currentUserId = useAuth((s) => s.currentUserId)
  if (!currentUserId) return <Navigate to="/login" replace />
  return <Outlet />
}

export default function App() {
  useEffect(() => {
    void loadCurrentUserData()
  }, [])

  return (
    <Routes>
      <Route path="/login" element={<Auth mode="login" />} />
      <Route path="/signup" element={<Auth mode="signup" />} />
      <Route element={<RequireAuth />}>
        <Route element={<Layout />}>
          <Route path="/" element={<Dashboard />} />
          <Route path="/programs" element={<Programs />} />
          <Route path="/programs/new" element={<ProgramEditor />} />
          <Route path="/programs/:programId" element={<ProgramDetail />} />
          <Route path="/programs/:programId/edit" element={<ProgramEditor />} />
          <Route path="/exercises" element={<Exercises />} />
          <Route path="/exercises/:exerciseId" element={<ExerciseDetail />} />
          <Route path="/progress" element={<Progress />} />
          <Route path="/settings" element={<Settings />} />
          <Route path="/workout/:programId/:dayId" element={<Workout />} />
          <Route path="*" element={<Dashboard />} />
        </Route>
      </Route>
    </Routes>
  )
}
