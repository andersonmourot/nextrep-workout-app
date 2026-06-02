import { Route, Routes } from 'react-router-dom'
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

export default function App() {
  return (
    <Routes>
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
    </Routes>
  )
}
