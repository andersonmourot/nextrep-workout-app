import { useEffect } from 'react'
import { Navigate, Outlet, Route, Routes } from 'react-router-dom'
import { Layout } from './components/Layout'
import { Dashboard } from './pages/Dashboard'
import { Programs } from './pages/Programs'
import { ProgramDetail } from './pages/ProgramDetail'
import { ProgramEditor } from './pages/ProgramEditor'
import { DayReview } from './pages/DayReview'
import { ProgramHistory } from './pages/ProgramHistory'
import { Exercises } from './pages/Exercises'
import { ExercisesLibrary } from './pages/ExercisesLibrary'
import { ExerciseDetail } from './pages/ExerciseDetail'
import { Progress } from './pages/Progress'
import { BodyWeightHistory, WorkoutHistory } from './pages/ProgressHistory'
import { Nutrition } from './pages/Nutrition'
import { MaxTracker } from './pages/MaxTracker'
import { MaxTrackerDetail } from './pages/MaxTrackerDetail'
import { People } from './pages/People'
import { Timer } from './pages/Timer'
import { Settings } from './pages/Settings'
import { AdminUsers } from './pages/AdminUsers'
import { Auth } from './pages/Auth'
import { ForgotPassword } from './pages/ForgotPassword'
import { ResetPassword } from './pages/ResetPassword'
import { Legal } from './pages/Legal'
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
      <Route path="/forgot-password" element={<ForgotPassword />} />
      <Route path="/reset-password" element={<ResetPassword />} />
      <Route element={<RequireAuth />}>
        <Route element={<Layout />}>
          <Route path="/" element={<Dashboard />} />
          <Route path="/programs" element={<Programs />} />
          {/* The live workout renders as an overlay from Layout on this path;
              Layout redirects here to the list when nothing is in progress. */}
          <Route path="/workout" element={null} />
          <Route path="/programs/exercises" element={<ExercisesLibrary />} />
          <Route path="/programs/history" element={<ProgramHistory />} />
          <Route path="/programs/new" element={<ProgramEditor />} />
          <Route path="/programs/:programId" element={<ProgramDetail />} />
          <Route path="/programs/:programId/edit" element={<ProgramEditor />} />
          <Route path="/programs/:programId/day/:dayIndex" element={<DayReview />} />
          <Route path="/exercises" element={<Exercises />} />
          <Route path="/exercises/:exerciseId" element={<ExerciseDetail />} />
          <Route path="/progress" element={<Progress />} />
          <Route path="/progress/history" element={<WorkoutHistory />} />
          <Route path="/progress/weight" element={<BodyWeightHistory />} />
          <Route path="/nutrition" element={<Nutrition />} />
          <Route path="/max" element={<MaxTracker />} />
          <Route path="/max/:id" element={<MaxTrackerDetail />} />
          <Route path="/people" element={<People />} />
          <Route path="/admin/users" element={<AdminUsers />} />
          <Route path="/timer" element={<Timer />} />
          <Route path="/settings" element={<Settings />} />
          <Route path="/legal/privacy" element={<Legal doc="privacy" />} />
          <Route path="/legal/terms" element={<Legal doc="terms" />} />
          <Route path="/legal/disclaimer" element={<Legal doc="disclaimer" />} />
          <Route path="*" element={<Dashboard />} />
        </Route>
      </Route>
    </Routes>
  )
}
