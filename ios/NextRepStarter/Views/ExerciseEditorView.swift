import SwiftUI

struct ExerciseEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Exercise
    @State private var secondaryText: String
    @State private var instructionsText: String
    @State private var tipsText: String
    @State private var showingDeleteConfirm = false

    private let muscles = [
        "Chest", "Back", "Shoulders", "Biceps", "Triceps", "Quads", "Hamstrings",
        "Glutes", "Calves", "Core", "Forearms", "Full Body"
    ]
    private let equipmentOptions = ["Barbell", "Dumbbell", "Machine", "Cable", "Bodyweight", "Kettlebell", "Bands"]
    private let difficulties = ["Beginner", "Intermediate", "Advanced"]

    init(exercise: Exercise? = nil) {
        let initial = exercise ?? Self.blankExercise()
        _draft = State(initialValue: initial)
        _secondaryText = State(initialValue: initial.secondaryMuscles.joined(separator: ", "))
        _instructionsText = State(initialValue: initial.instructions.joined(separator: "\n"))
        _tipsText = State(initialValue: initial.tips.joined(separator: "\n"))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                basics
                coaching
                actions
            }
            .padding(16)
            .frame(maxWidth: 448)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(draft.name.isEmpty ? "New Exercise" : draft.name)
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .alert("Delete Exercise?", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.deleteCustomExercise(id: draft.id)
                dismiss()
            }
        } message: {
            Text("This removes the custom exercise from your synced data.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(store.isCustomExercise(draft) ? "Edit Exercise" : "Create Exercise")
                .font(.system(size: 34, weight: .bold, design: .default))
                .textCase(.uppercase)
                .foregroundStyle(Theme.text)

            Text("Create exercises you can add to custom programs.")
                .font(.subheadline)
                .foregroundStyle(Theme.textDim)
        }
    }

    private var basics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Basics")
                .font(.headline)
                .foregroundStyle(Theme.text)

            editorField("Name", text: $draft.name)

            Picker("Primary muscle", selection: $draft.primaryMuscle) {
                ForEach(muscles, id: \.self) { muscle in
                    Text(muscle).tag(muscle)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.accentLight)

            editorField("Secondary muscles, comma separated", text: $secondaryText)

            Picker("Equipment", selection: $draft.equipment) {
                ForEach(equipmentOptions, id: \.self) { equipment in
                    Text(equipment).tag(equipment)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.accentLight)

            Picker("Difficulty", selection: $draft.difficulty) {
                ForEach(difficulties, id: \.self) { difficulty in
                    Text(difficulty).tag(difficulty)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.accentLight)
        }
        .cardStyle()
        .foregroundStyle(Theme.text)
    }

    private var coaching: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coaching")
                .font(.headline)
                .foregroundStyle(Theme.text)

            editorField("Instructions, one per line", text: $instructionsText, minLines: 4)
            editorField("Tips, one per line", text: $tipsText, minLines: 4)
        }
        .cardStyle()
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                normalizeDraft()
                store.saveCustomExercise(draft)
                dismiss()
            } label: {
                Text("Save Exercise")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)

            if store.isCustomExercise(draft) {
                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    Text("Delete Exercise")
                }
                .buttonStyle(GhostButtonStyle())
            }
        }
    }

    private func normalizeDraft() {
        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.secondaryMuscles = commaList(secondaryText)
        draft.instructions = lineList(instructionsText)
        draft.tips = lineList(tipsText)
        draft.version = Int(Date().timeIntervalSince1970 * 1000)
    }

    private func commaList(_ value: String) -> [String] {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func lineList(_ value: String) -> [String] {
        value
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func editorField(_ placeholder: String, text: Binding<String>, minLines: Int = 1) -> some View {
        TextField("", text: text, axis: .vertical)
            .lineLimit(minLines, reservesSpace: minLines > 1)
            .foregroundStyle(Theme.text)
            .tint(Theme.accentLight)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.inputBg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(Theme.textDim.opacity(0.95))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
    }

    private static func blankExercise() -> Exercise {
        Exercise(
            id: "ios-ex-\(UUID().uuidString)",
            name: "",
            primaryMuscle: "Full Body",
            secondaryMuscles: [],
            equipment: "Bodyweight",
            difficulty: "Beginner",
            instructions: [],
            tips: [],
            photos: nil,
            shared: false,
            ownerName: nil,
            ownerId: nil,
            collaborative: false,
            version: nil
        )
    }
}
