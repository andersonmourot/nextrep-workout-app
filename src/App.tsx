import { useEffect } from 'react'
import { Navigate, Outlet, Route, Routes } from 'react-router-dom'
import { Layout } from './components/Layout'
import { Dashboard } from './pages/Dashboard'
import { Programs } from './pages/Programs'
import { ProgramDetail } from './pages/ProgramDetail'
import { ProgramEditor } from './pages/ProgramEditor'
import { Workout } from './pages/Workout'
import { Exercises } from './pages/Exercises'
import { ExercisesLibrary } from './pages/ExercisesLibrary'
import { ExerciseDetail } from './pages/ExerciseDetail'
import { Progress } from './pages/Progress'
import { Nutrition } from './pages/Nutrition'
import { MaxTracker } from './pages/MaxTracker'
import { MaxTrackerDetail } from './pages/MaxTrackerDetail'
import { People } from './pages/People'
import { Timer } from './pages/Timer'
import { Settings } from './pages/Settings'
import { AdminUsers } from './pages/AdminUsers'
import { Auth } from './pages/Auth'
import { useAuth } from './auth'
import { useStore } from './store'
import { applyTheme } from './lib/theme'

function RequireAuth() {
  const token = useAuth((s) => s.token)
  const ready = useAuth((s) => s.ready)
  if (!ready) return null
  if (!token) return <Navigate to="/login" replace />
  return <Outlet />
}

export default function App() {
  const themeColor = useStore((s) => s.themeColor)
  const themeMode = useStore((s) => s.themeMode)

  useEffect(() => {
    void useAuth.getState().init()
  }, [])

  useEffect(() => {
    applyTheme(themeColor, themeMode)
  }, [themeColor, themeMode])

  return (
    <Routes>
      <Route path="/login" element={<Auth mode="login" />} />
      <Route path="/signup" element={<Auth mode="signup" />} />
      <Route element={<RequireAuth />}>
        <Route element={<Layout />}>
          <Route path="/" element={<Dashboard />} />
          <Route path="/programs" element={<Programs />} />
          <Route path="/programs/exercises" element={<ExercisesLibrary />} />
          <Route path="/programs/new" element={<ProgramEditor />} />
          <Route path="/programs/:programId" element={<ProgramDetail />} />
          <Route path="/programs/:programId/edit" element={<ProgramEditor />} />
          <Route path="/exercises" element={<Exercises />} />
          <Route path="/exercises/:exerciseId" element={<ExerciseDetail />} />
          <Route path="/progress" element={<Progress />} />
          <Route path="/nutrition" element={<Nutrition />} />
          <Route path="/max" element={<MaxTracker />} />
          <Route path="/max/:id" element={<MaxTrackerDetail />} />
          <Route path="/people" element={<People />} />
          <Route path="/admin/users" element={<AdminUsers />} />
          <Route path="/timer" element={<Timer />} />
          <Route path="/settings" element={<Settings />} />
          <Route path="/workout/:programId/:dayId" element={<Workout />} />
          <Route path="*" element={<Dashboard />} />
        </Route>
      </Route>
    </Routes>
  )
}
