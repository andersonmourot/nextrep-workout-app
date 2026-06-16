import SwiftUI

struct ActiveWorkoutView: View {
    let program: Program
    let day: ProgramDay

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Active Workout")
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.text)

                Text(program.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accent)

                Text(day.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.text)

                if !day.focus.isEmpty {
                    Text(day.focus)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textDim)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Label("Workout player coming next", systemImage: "figure.strengthtraining.traditional")
                    .font(.headline)
                    .foregroundStyle(Theme.text)

                Text("This placeholder confirms navigation from Program Detail. The next pass will add set, rep, weight, and rest-timer logging.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .cardStyle()

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: 448)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }

    private var accent: Color {
        Color(hex: program.accent)
    }
}
